--------------------------------------------------------------------------------
-- Controlador VGA 640x480 @ 60 Hz com cor de tela cheia
--
-- Gera os sincronismos horizontal e vertical a partir do clock de 100 MHz
-- (clock de pixel de 25 MHz obtido com um enable a cada 4 ciclos) e pinta a
-- área visível inteira com COR_ALTA quando nivel = '1' e com COR_BAIXA quando
-- nivel = '0'. Fora da área visível, as cores ficam em zero, como exige o
-- padrão VGA.
--
-- Temporização (em pixels / linhas):
--   horizontal: 640 visível + 16 front porch + 96 sync + 48 back porch = 800
--   vertical:   480 visível + 10 front porch +  2 sync + 33 back porch = 525
--   sincronismos ativos em nível baixo
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity vga_controller is
  generic (
    COR_BAIXA : std_logic_vector(11 downto 0) := x"00F";  -- RGB 4:4:4, azul
    COR_ALTA  : std_logic_vector(11 downto 0) := x"0F0"   -- RGB 4:4:4, verde
  );
  port (
    clk      : in  std_logic;                     -- clock de 100 MHz
    rst      : in  std_logic;                     -- reset síncrono
    nivel    : in  std_logic;                     -- nível do sinal codificado
    vga_r    : out std_logic_vector(3 downto 0);
    vga_g    : out std_logic_vector(3 downto 0);
    vga_b    : out std_logic_vector(3 downto 0);
    vga_hs   : out std_logic;
    vga_vs   : out std_logic
  );
end entity;

architecture rtl of vga_controller is
  constant H_VISIBLE : natural := 640;
  constant H_FRONT   : natural := 16;
  constant H_SYNC    : natural := 96;
  constant H_BACK    : natural := 48;
  constant H_TOTAL   : natural := H_VISIBLE + H_FRONT + H_SYNC + H_BACK;  -- 800

  constant V_VISIBLE : natural := 480;
  constant V_FRONT   : natural := 10;
  constant V_SYNC    : natural := 2;
  constant V_BACK    : natural := 33;
  constant V_TOTAL   : natural := V_VISIBLE + V_FRONT + V_SYNC + V_BACK;  -- 525

  -- Divisor de 100 MHz para o clock de pixel de 25 MHz
  signal div       : natural range 0 to 3 := 0;
  signal pixel_en  : std_logic := '0';

  -- Posição do pixel atual
  signal h_cnt : natural range 0 to H_TOTAL - 1 := 0;
  signal v_cnt : natural range 0 to V_TOTAL - 1 := 0;

  -- Saídas registradas
  signal rgb_reg : std_logic_vector(11 downto 0) := (others => '0');
  signal hs_reg  : std_logic := '1';
  signal vs_reg  : std_logic := '1';
begin
  -- Enable de pixel: um ciclo ativo a cada 4 ciclos de 100 MHz
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        div      <= 0;
        pixel_en <= '0';
      else
        if div = 3 then
          div      <= 0;
          pixel_en <= '1';
        else
          div      <= div + 1;
          pixel_en <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Contadores horizontal e vertical
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        h_cnt <= 0;
        v_cnt <= 0;
      elsif pixel_en = '1' then
        if h_cnt = H_TOTAL - 1 then
          h_cnt <= 0;
          if v_cnt = V_TOTAL - 1 then
            v_cnt <= 0;
          else
            v_cnt <= v_cnt + 1;
          end if;
        else
          h_cnt <= h_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- Sincronismos e cor, registrados para evitar glitches no conector VGA
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        hs_reg  <= '1';
        vs_reg  <= '1';
        rgb_reg <= (others => '0');
      else
        if h_cnt >= H_VISIBLE + H_FRONT and h_cnt < H_VISIBLE + H_FRONT + H_SYNC then
          hs_reg <= '0';
        else
          hs_reg <= '1';
        end if;

        if v_cnt >= V_VISIBLE + V_FRONT and v_cnt < V_VISIBLE + V_FRONT + V_SYNC then
          vs_reg <= '0';
        else
          vs_reg <= '1';
        end if;

        if h_cnt < H_VISIBLE and v_cnt < V_VISIBLE then
          if nivel = '1' then
            rgb_reg <= COR_ALTA;
          else
            rgb_reg <= COR_BAIXA;
          end if;
        else
          rgb_reg <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  vga_r  <= rgb_reg(11 downto 8);
  vga_g  <= rgb_reg(7 downto 4);
  vga_b  <= rgb_reg(3 downto 0);
  vga_hs <= hs_reg;
  vga_vs <= vs_reg;
end architecture;
