--------------------------------------------------------------------------------
-- Top da saída VGA do codificador Manchester (cores pulsantes)
--
-- Instancia o núcleo manchester (../../../src/manchester.vhd) com 1 s por bit
-- e o controlador VGA 640x480 @ 60 Hz. A tela inteira fica verde quando o
-- sinal codificado está em nível alto e azul quando está em nível baixo,
-- piscando conforme as duas metades de cada bit. LEDs e display de 7
-- segmentos continuam funcionando como no projeto principal.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_vga is
  generic (
    CYCLES_PER_BIT : positive := 100_000_000  -- 1 s por bit a 100 MHz (deve ser par)
  );
  port (
    clk      : in  std_logic;                      -- clock de 100 MHz (W5)
    btn_rst  : in  std_logic;                      -- reset, botão BTNC (U18)
    sw       : in  std_logic_vector(15 downto 0);  -- sequência de bits (SW15..SW0)
    led      : out std_logic_vector(15 downto 0);  -- LD15..LD0
    seg      : out std_logic_vector(6 downto 0);   -- display de 7 segmentos
    an       : out std_logic_vector(3 downto 0);
    vgaRed   : out std_logic_vector(3 downto 0);
    vgaGreen : out std_logic_vector(3 downto 0);
    vgaBlue  : out std_logic_vector(3 downto 0);
    Hsync    : out std_logic;
    Vsync    : out std_logic
  );
end entity;

architecture rtl of manchester_vga is
  signal codificado : std_logic;
begin
  encoder: entity work.manchester
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk      => clk,
      btn_rst  => btn_rst,
      data_in  => sw,
      data_out => codificado,
      nrz_out  => open,
      led      => led,
      seg      => seg,
      an       => an
    );

  -- O VGA não é reiniciado pelo botão, para o monitor não perder o sincronismo
  vga: entity work.vga_controller
    generic map (
      COR_BAIXA => x"00F",  -- azul
      COR_ALTA  => x"0F0"   -- verde
    )
    port map (
      clk    => clk,
      rst    => '0',
      nivel  => codificado,
      vga_r  => vgaRed,
      vga_g  => vgaGreen,
      vga_b  => vgaBlue,
      vga_hs => Hsync,
      vga_vs => Vsync
    );
end architecture;
