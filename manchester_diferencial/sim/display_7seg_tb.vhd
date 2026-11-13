--------------------------------------------------------------------------------
-- Testbench do display de 7 segmentos
--
-- Para cada número de 0 a 15, observa vários períodos de multiplexação e
-- verifica com assert:
--   * que só AN0 (unidade) e AN1 (dezena) são acesos, um de cada vez;
--   * que a unidade e a dezena mostradas correspondem ao número;
--   * que a dezena fica apagada para números menores que 10;
--   * que tudo fica apagado durante o reset.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity display_7seg_tb is
end entity;

architecture sim of display_7seg_tb is
  constant CLK_PERIOD   : time     := 10 ns;
  constant REFRESH_BITS : positive := 4;  -- troca de display a cada 8 ciclos

  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal numero : natural range 0 to 15 := 0;
  signal seg    : std_logic_vector(6 downto 0);
  signal an     : std_logic_vector(3 downto 0);

  signal sim_done : boolean := false;

  -- Converte o padrão dos segmentos de volta para o dígito (-1 = inválido)
  function digito(s : std_logic_vector(6 downto 0)) return integer is
  begin
    case s is
      when "1000000" => return 0;
      when "1111001" => return 1;
      when "0100100" => return 2;
      when "0110000" => return 3;
      when "0011001" => return 4;
      when "0010010" => return 5;
      when "0000010" => return 6;
      when "1111000" => return 7;
      when "0000000" => return 8;
      when "0010000" => return 9;
      when others    => return -1;
    end case;
  end function;
begin
  clk <= not clk after CLK_PERIOD / 2 when not sim_done;

  dut: entity work.display_7seg
    generic map (REFRESH_BITS => REFRESH_BITS)
    port map (clk => clk, rst => rst, numero => numero, seg => seg, an => an);

  process
    variable errors     : natural := 0;
    variable viu_unid   : boolean;
    variable viu_dezena : boolean;

    procedure check(cond : boolean; msg : string) is
    begin
      assert cond report msg severity error;
      if not cond then
        errors := errors + 1;
      end if;
    end procedure;
  begin
    wait for 5 * CLK_PERIOD;
    check(an = "1111" and seg = "1111111", "Display deveria estar apagado no reset");
    wait until falling_edge(clk);
    rst <= '0';

    for n in 0 to 15 loop
      numero <= n;
      wait until falling_edge(clk);  -- um ciclo para o novo número chegar à saída
      wait until falling_edge(clk);
      viu_unid   := false;
      viu_dezena := false;
      for k in 1 to 4 * 2 ** REFRESH_BITS loop
        wait until falling_edge(clk);
        case an is
          when "1110" =>
            viu_unid := true;
            check(digito(seg) = n mod 10,
                  "Numero " & integer'image(n) & ": unidade errada");
          when "1101" =>
            viu_dezena := true;
            check(n >= 10 and digito(seg) = n / 10,
                  "Numero " & integer'image(n) & ": dezena errada ou acesa indevidamente");
          when "1111" =>
            check(n < 10, "Numero " & integer'image(n) & ": dezena apagada indevidamente");
          when others =>
            check(false, "Numero " & integer'image(n) & ": combinacao de anodos invalida");
        end case;
      end loop;
      check(viu_unid, "Numero " & integer'image(n) & ": unidade nunca mostrada");
      check(viu_dezena = (n >= 10), "Numero " & integer'image(n) & ": dezena mostrada incorretamente");
    end loop;

    rst <= '1';
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    check(an = "1111" and seg = "1111111", "Display deveria apagar com o reset");

    if errors = 0 then
      report "Simulacao concluida sem erros" severity note;
    else
      report "Simulacao concluida com " & integer'image(errors) & " erro(s)" severity error;
    end if;
    sim_done <= true;
    wait;
  end process;
end architecture;
