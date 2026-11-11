--------------------------------------------------------------------------------
-- Testbench do top da saída VGA do Manchester
--
-- Usa um CYCLES_PER_BIT menor (10 ms por bit) para que a cor mude várias vezes
-- em cerca de três quadros. Uma segunda instância do núcleo, com as mesmas
-- entradas, fornece o sinal codificado de referência. Verifica com assert:
--   * que, na área visível, a tela fica verde com o sinal em nível alto e
--     azul com o sinal em nível baixo;
--   * que as cores ficam em zero durante os sincronismos;
--   * que as duas cores aparecem e que os sincronismos estão ativos.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_vga_tb is
end entity;

architecture sim of manchester_vga_tb is
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
  signal rgb      : std_logic_vector(11 downto 0);
  signal ref      : std_logic;  -- sinal codificado da instância de referência

  signal sim_done : boolean := false;
begin
  clk <= not clk after CLK_PERIOD / 2 when not sim_done;
  rgb <= vgaRed & vgaGreen & vgaBlue;

  dut: entity work.manchester_vga
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk => clk, btn_rst => btn_rst, sw => sw, led => led, seg => seg, an => an,
      vgaRed => vgaRed, vgaGreen => vgaGreen, vgaBlue => vgaBlue,
      Hsync => Hsync, Vsync => Vsync
    );

  referencia: entity work.manchester
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (clk => clk, btn_rst => btn_rst, data_in => sw, data_out => ref);

  process
  begin
    wait for 5 * CLK_PERIOD;
    btn_rst <= '0';
    wait for SIM_TIME;
    sim_done <= true;
    wait;
  end process;

  -- A cor registrada no VGA reflete o nível do ciclo anterior
  process(clk, sim_done)
    variable ref_ant      : std_logic := '0';
    variable errors       : natural := 0;
    variable viu_verde    : boolean := false;
    variable viu_azul     : boolean := false;
    variable pulsos_vsync : natural := 0;
    variable vs_ant       : std_logic := '1';
  begin
    if rising_edge(clk) then
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
      vs_ant  := Vsync;
      ref_ant := ref;
    end if;
    if sim_done'event and sim_done then
      assert viu_verde and viu_azul report "As duas cores deveriam aparecer" severity error;
      assert pulsos_vsync >= 2 report "Vsync nao esta pulsando" severity error;
      if errors = 0 and viu_verde and viu_azul and pulsos_vsync >= 2 then
        report "Simulacao concluida sem erros (" & integer'image(pulsos_vsync) & " quadros)" severity note;
      else
        report "Simulacao concluida com erros" severity error;
      end if;
    end if;
  end process;
end architecture;
