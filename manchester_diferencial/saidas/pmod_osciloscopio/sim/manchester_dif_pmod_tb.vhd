--------------------------------------------------------------------------------
-- Testbench do top da saída PMOD do Manchester Diferencial, na taxa real do
-- osciloscópio
--
-- Usa o CYCLES_PER_BIT padrão do top (100_000, ou seja, 1 ms por bit) e
-- transmite uma volta completa da sequência 1011001011110000 a partir do nível
-- baixo, verificando com assert, em cada metade de cada bit, o sinal
-- codificado em JA1 e o dado original em JA2. A forma de onda resultante é a
-- esperada no osciloscópio.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_dif_pmod_tb is
end entity;

architecture sim of manchester_dif_pmod_tb is
  constant CLK_PERIOD     : time     := 10 ns;                          -- 100 MHz
  constant CYCLES_PER_BIT : positive := 100_000;
  constant BIT_PERIOD     : time     := CYCLES_PER_BIT * CLK_PERIOD;  -- 1 ms
  constant LATENCY        : positive := 3;
  constant SEQ            : std_logic_vector(15 downto 0) := "1011001011110000";

  signal clk     : std_logic := '0';
  signal btn_rst : std_logic := '1';
  signal sw      : std_logic_vector(15 downto 0) := SEQ;
  signal led     : std_logic_vector(15 downto 0);
  signal ja      : std_logic_vector(1 downto 0);

  signal sim_done : boolean := false;
begin
  clk <= not clk after CLK_PERIOD / 2 when not sim_done;

  dut: entity work.manchester_dif_pmod
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (clk => clk, btn_rst => btn_rst, sw => sw, led => led, ja => ja);

  process
    variable errors : natural := 0;
    variable nivel  : std_logic := '0';  -- nível baixo após o reset

    procedure check(cond : boolean; msg : string) is
    begin
      assert cond report msg severity error;
      if not cond then
        errors := errors + 1;
      end if;
    end procedure;
  begin
    wait for 5 * CLK_PERIOD;
    check(ja = "00", "JA1 e JA2 deveriam estar em 0 durante o reset");

    -- Solta o reset e para meio ciclo antes do início do primeiro bit
    wait until falling_edge(clk);
    btn_rst <= '0';
    for k in 1 to LATENCY - 1 loop
      wait until rising_edge(clk);
    end loop;
    wait until falling_edge(clk);

    for i in 15 downto 0 loop
      if SEQ(i) = '0' then
        nivel := not nivel;  -- bit 0: inverte no início do bit
      end if;
      wait for BIT_PERIOD / 4;
      check(ja(0) = nivel,  "Bit " & integer'image(i) & ": JA1 errado na 1a metade");
      check(ja(1) = SEQ(i), "Bit " & integer'image(i) & ": JA2 (NRZ) errado");
      nivel := not nivel;    -- meio do bit: sempre inverte
      wait for BIT_PERIOD / 2;
      check(ja(0) = nivel,  "Bit " & integer'image(i) & ": JA1 errado na 2a metade");
      wait for BIT_PERIOD / 4;
    end loop;

    if errors = 0 then
      report "Simulacao concluida sem erros" severity note;
    else
      report "Simulacao concluida com " & integer'image(errors) & " erro(s)" severity error;
    end if;
    sim_done <= true;
    wait;
  end process;
end architecture;
