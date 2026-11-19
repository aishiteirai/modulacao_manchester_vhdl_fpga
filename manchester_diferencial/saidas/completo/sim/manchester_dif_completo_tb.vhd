--------------------------------------------------------------------------------
-- Testbench do top com todas as saídas do Manchester Diferencial
-- (placa, VGA e PMOD)
--
-- Simula as três saídas ao mesmo tempo, com um CYCLES_PER_BIT menor (10 ms por
-- bit) para que a cor da tela mude várias vezes em cerca de três quadros. Uma
-- segunda instância do núcleo, com as mesmas entradas, fornece a referência
-- (a codificação em si é verificada bit a bit em ../../../sim/manchester_dif_tb.vhd).
-- Verifica com assert, a cada ciclo de clock:
--   * PMOD: JA1 igual ao sinal codificado e JA2 igual ao dado original;
--   * placa: LEDs e display de 7 segmentos iguais aos da referência;
--   * VGA: na área visível, verde com o sinal em nível alto e azul em nível
--     baixo; cores em zero durante os sincronismos;
--   * que as duas cores aparecem, que o Vsync pulsa e que o Hsync continua
--     pulsando enquanto o BTNC está pressionado (o VGA não é reiniciado).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_dif_completo_tb is
end entity;

architecture sim of manchester_dif_completo_tb is
  constant CLK_PERIOD     : time     := 10 ns;
  constant CYCLES_PER_BIT : positive := 1_000_000;  -- 10 ms por bit
  constant SIM_TIME       : time     := 50 ms;

  constant VERDE : std_logic_vector(11 downto 0) := x"0F0";
  constant AZUL  : std_logic_vector(11 downto 0) := x"00F";

  signal clk      : std_logic := '0';
  signal btn_rst  : std_logic := '1';
  signal sw       : std_logic_vector(15 downto 0) := "1011001011110000";
  signal led      : std_logic_vector(15 downto 0);
  signal seg      : std_logic_vector(6 downto 0);
  signal an       : std_logic_vector(3 downto 0);
  signal vgaRed   : std_logic_vector(3 downto 0);
  signal vgaGreen : std_logic_vector(3 downto 0);
  signal vgaBlue  : std_logic_vector(3 downto 0);
  signal Hsync    : std_logic;
  signal Vsync    : std_logic;
  signal ja       : std_logic_vector(1 downto 0);
  signal rgb      : std_logic_vector(11 downto 0);

  -- Saídas da instância de referência
  signal ref_enc : std_logic;
  signal ref_nrz : std_logic;
  signal ref_led : std_logic_vector(15 downto 0);
  signal ref_seg : std_logic_vector(6 downto 0);
  signal ref_an  : std_logic_vector(3 downto 0);

  signal sim_done : boolean := false;
begin
  clk <= not clk after CLK_PERIOD / 2 when not sim_done;
  rgb <= vgaRed & vgaGreen & vgaBlue;

  dut: entity work.manchester_dif_completo
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk => clk, btn_rst => btn_rst, sw => sw, led => led, seg => seg, an => an,
      vgaRed => vgaRed, vgaGreen => vgaGreen, vgaBlue => vgaBlue,
      Hsync => Hsync, Vsync => Vsync, ja => ja
    );

  referencia: entity work.manchester_dif
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk => clk, btn_rst => btn_rst, data_in => sw,
      data_out => ref_enc, nrz_out => ref_nrz, led => ref_led,
      seg => ref_seg, an => ref_an
    );

  -- Estímulos: reset inicial, transmissão, um toque no BTNC e nova transmissão
  process
  begin
    wait for 5 * CLK_PERIOD;
    btn_rst <= '0';
    wait for 32 ms;
    btn_rst <= '1';
    wait for 1 ms;
    btn_rst <= '0';
    wait for SIM_TIME - 33 ms;
    sim_done <= true;
    wait;
  end process;

  process(clk, sim_done)
    variable ref_ant        : std_logic := '0';
    variable errors         : natural := 0;
    variable viu_verde      : boolean := false;
    variable viu_azul       : boolean := false;
    variable pulsos_vsync   : natural := 0;
    variable pulsos_hs_rst  : natural := 0;
    variable vs_ant         : std_logic := '1';
    variable hs_ant         : std_logic := '1';
  begin
    if rising_edge(clk) then
      -- PMOD (osciloscópio)
      if ja(0) /= ref_enc then
        errors := errors + 1;
        assert false report "JA1 diferente do sinal codificado" severity error;
      end if;
      if ja(1) /= ref_nrz then
        errors := errors + 1;
        assert false report "JA2 diferente do dado original" severity error;
      end if;

      -- Placa (LEDs e display)
      if led /= ref_led then
        errors := errors + 1;
        assert false report "LEDs diferentes da referencia" severity error;
      end if;
      if seg /= ref_seg or an /= ref_an then
        errors := errors + 1;
        assert false report "Display diferente da referencia" severity error;
      end if;

      -- VGA: a cor registrada reflete o nível do ciclo anterior
      if Hsync = '0' or Vsync = '0' then
        if rgb /= x"000" then
          errors := errors + 1;
          assert false report "Cor diferente de zero durante o sincronismo" severity error;
        end if;
      elsif rgb /= x"000" then
        if (ref_ant = '1' and rgb /= VERDE) or (ref_ant = '0' and rgb /= AZUL) then
          errors := errors + 1;
          assert false report "Cor da tela nao corresponde ao nivel do sinal" severity error;
        end if;
        viu_verde := viu_verde or rgb = VERDE;
        viu_azul  := viu_azul or rgb = AZUL;
      end if;
      if vs_ant = '1' and Vsync = '0' then
        pulsos_vsync := pulsos_vsync + 1;
      end if;
      if btn_rst = '1' and hs_ant = '1' and Hsync = '0' then
        pulsos_hs_rst := pulsos_hs_rst + 1;
      end if;
      vs_ant  := Vsync;
      hs_ant  := Hsync;
      ref_ant := ref_enc;
    end if;
    if sim_done'event and sim_done then
      assert viu_verde and viu_azul report "As duas cores deveriam aparecer" severity error;
      assert pulsos_vsync >= 2 report "Vsync nao esta pulsando" severity error;
      assert pulsos_hs_rst > 0 report "Hsync parou durante o reset" severity error;
      if errors = 0 and viu_verde and viu_azul and pulsos_vsync >= 2 and pulsos_hs_rst > 0 then
        report "Simulacao concluida sem erros (" & integer'image(pulsos_vsync) &
               " quadros; PMOD, LEDs, display e VGA conferidos)" severity note;
      else
        report "Simulacao concluida com erros" severity error;
      end if;
    end if;
  end process;
end architecture;
