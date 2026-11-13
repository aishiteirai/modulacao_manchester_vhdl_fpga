--------------------------------------------------------------------------------
-- Display de 7 segmentos: número do bit em transmissão (15 a 0)
--
-- Mostra o valor de "numero" em decimal nos dois displays da direita da
-- Basys 3 (AN1 = dezena, AN0 = unidade); os dois da esquerda ficam apagados,
-- assim como a dezena quando o número é menor que 10.
--
-- Os quatro displays compartilham os segmentos, então são acesos um de cada
-- vez (multiplexação). Com REFRESH_BITS = 17 e clock de 100 MHz, cada display
-- é atualizado a cerca de 380 Hz, rápido o bastante para não piscar.
-- Segmentos e anodos são ativos em nível baixo.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_7seg is
  generic (
    REFRESH_BITS : positive := 17  -- tamanho do contador de multiplexação
  );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    numero : in  natural range 0 to 15;
    seg    : out std_logic_vector(6 downto 0);  -- g f e d c b a (ativos em 0)
    an     : out std_logic_vector(3 downto 0)   -- AN3..AN0 (ativos em 0)
  );
end entity;

architecture rtl of display_7seg is
  signal refresh : unsigned(REFRESH_BITS - 1 downto 0) := (others => '0');
  signal seg_reg : std_logic_vector(6 downto 0) := (others => '1');
  signal an_reg  : std_logic_vector(3 downto 0) := (others => '1');

  -- Padrão dos segmentos (g f e d c b a, ativos em 0) para cada dígito
  function decod(d : natural range 0 to 9) return std_logic_vector is
  begin
    case d is
      when 0      => return "1000000";
      when 1      => return "1111001";
      when 2      => return "0100100";
      when 3      => return "0110000";
      when 4      => return "0011001";
      when 5      => return "0010010";
      when 6      => return "0000010";
      when 7      => return "1111000";
      when 8      => return "0000000";
      when others => return "0010000";  -- 9
    end case;
  end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        refresh <= (others => '0');
        seg_reg <= (others => '1');
        an_reg  <= (others => '1');
      else
        refresh <= refresh + 1;

        -- O bit mais significativo do contador alterna entre unidade e dezena
        if refresh(REFRESH_BITS - 1) = '0' then
          an_reg  <= "1110";                    -- AN0: unidade
          seg_reg <= decod(numero mod 10);
        elsif numero >= 10 then
          an_reg  <= "1101";                    -- AN1: dezena
          seg_reg <= decod(numero / 10);
        else
          an_reg  <= "1111";                    -- dezena apagada (número < 10)
          seg_reg <= (others => '1');
        end if;
      end if;
    end if;
  end process;

  seg <= seg_reg;
  an  <= an_reg;
end architecture;
