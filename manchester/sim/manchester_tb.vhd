--------------------------------------------------------------------------------
-- Testbench do codificador Manchester (IEEE 802.3)
--
-- Verifica com assert, no meio de cada metade de cada bit:
--   * o nível de data_out (1ª metade = not bit, 2ª metade = bit);
--   * o dado original em nrz_out;
--   * o vetor de LEDs (somente o LED do bit em transmissão recebe o sinal).
-- Também verifica a saída em nível baixo durante o reset, a troca de switches
-- entre duas voltas e o reset no meio da transmissão.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_tb is
end entity;

architecture sim of manchester_tb is
  constant CLK_PERIOD     : time     := 10 ns;                          -- 100 MHz
  constant CYCLES_PER_BIT : positive := 10;
  constant BIT_PERIOD     : time     := CYCLES_PER_BIT * CLK_PERIOD;  -- 100 ns

  -- Latência entre soltar o botão e o primeiro bit na saída:
  -- 2 flip-flops do sincronizador + 1 flip-flop de saída
  constant LATENCY : positive := 3;

  constant SEQ_1 : std_logic_vector(15 downto 0) := "1011001011110000";
  constant SEQ_2 : std_logic_vector(15 downto 0) := "0101010100110011";

  signal clk      : std_logic := '0';
  signal btn_rst  : std_logic := '1';
  signal data_in  : std_logic_vector(15 downto 0) := SEQ_1;
  signal data_out : std_logic;
  signal nrz_out  : std_logic;
  signal led      : std_logic_vector(15 downto 0);

  signal sim_done : boolean := false;
begin
  clk <= not clk after CLK_PERIOD / 2 when not sim_done;

  dut: entity work.manchester
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk      => clk,
      btn_rst  => btn_rst,
      data_in  => data_in,
      data_out => data_out,
      nrz_out  => nrz_out,
      led      => led
    );

  process
    variable errors : natural := 0;

    procedure check(cond : boolean; msg : string) is
    begin
      assert cond report msg severity error;
      if not cond then
        errors := errors + 1;
      end if;
    end procedure;

    -- Solta o reset numa borda de descida e para meio ciclo antes da borda em
    -- que o primeiro bit é lido. A partir daí, cada chamada de check_bit também
    -- termina meio ciclo antes do próximo bit, de modo que qualquer mudança em
    -- data_in feita entre os bits já está estável quando o circuito a lê.
    procedure release_reset is
    begin
      wait until falling_edge(clk);
      btn_rst <= '0';
      for k in 1 to LATENCY - 1 loop
        wait until rising_edge(clk);
      end loop;
      wait until falling_edge(clk);
    end procedure;

    -- Confere um bit inteiro; deve ser chamada meio ciclo antes do início do bit
    procedure check_bit(i : natural; b : std_logic) is
      variable exp : std_logic_vector(15 downto 0);
    begin
      exp := (others => '0');

      wait for BIT_PERIOD / 4;  -- meio da 1ª metade
      exp(i) := not b;
      check(data_out = not b, "Bit " & integer'image(i) & ": 1a metade errada");
      check(nrz_out = b,      "Bit " & integer'image(i) & ": nrz_out errado");
      check(led = exp,        "Bit " & integer'image(i) & ": LEDs errados na 1a metade");

      wait for BIT_PERIOD / 2;  -- meio da 2ª metade
      exp(i) := b;
      check(data_out = b,     "Bit " & integer'image(i) & ": 2a metade errada");
      check(led = exp,        "Bit " & integer'image(i) & ": LEDs errados na 2a metade");

      wait for BIT_PERIOD / 4;  -- início do próximo bit
    end procedure;

    procedure check_sequence(seq : std_logic_vector(15 downto 0)) is
    begin
      for i in 15 downto 0 loop
        check_bit(i, seq(i));
      end loop;
    end procedure;
  begin
    -- 1) Reset: saída e LEDs em nível baixo
    wait for 5 * CLK_PERIOD;
    check(data_out = '0' and led = x"0000", "Saida deveria estar em 0 durante o reset");

    -- 2) Primeira volta completa com SEQ_1 (SW15 -> SW0)
    release_reset;
    check_sequence(SEQ_1);

    -- 3) Troca dos switches: a segunda volta deve usar SEQ_2
    data_in <= SEQ_2;
    check_sequence(SEQ_2);

    -- 4) Switch alterado depois do início do bit não muda o bit em transmissão;
    --    alterado antes do início, vale para o próprio bit
    wait for BIT_PERIOD / 8;
    data_in(15) <= not SEQ_2(15);  -- SW15 muda durante a transmissão do bit 15
    wait for BIT_PERIOD / 8;
    check(data_out = not SEQ_2(15), "Bit 15: mudou com o switch alterado no meio do bit");
    wait for BIT_PERIOD / 2;
    check(data_out = SEQ_2(15),     "Bit 15: mudou com o switch alterado no meio do bit");
    data_in(14) <= not SEQ_2(14);  -- SW14 muda antes do início do bit 14
    wait for BIT_PERIOD / 4;
    check_bit(14, not SEQ_2(14));

    -- 5) Reset no meio da transmissão, com a saída em nível alto (1ª metade do
    --    bit 13, que vale 0): tudo vai a nível baixo e recomeça em SW15
    wait for BIT_PERIOD / 4;
    check(data_out = '1', "Bit 13: saida deveria estar em 1 antes do reset");
    btn_rst <= '1';
    wait for 4 * CLK_PERIOD;
    check(data_out = '0' and led = x"0000", "Saida deveria ir a 0 com o reset");
    wait for BIT_PERIOD;
    check(data_out = '0' and led = x"0000", "Saida deveria continuar em 0 com o reset");
    data_in <= SEQ_1;
    release_reset;
    check_bit(15, SEQ_1(15));
    check_bit(14, SEQ_1(14));

    wait for 0 ns;
    if errors = 0 then
      report "Simulacao concluida sem erros" severity note;
    else
      report "Simulacao concluida com " & integer'image(errors) & " erro(s)" severity error;
    end if;
    sim_done <= true;
    wait;
  end process;
end architecture;
