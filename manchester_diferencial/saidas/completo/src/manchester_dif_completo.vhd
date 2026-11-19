--------------------------------------------------------------------------------
-- Top com todas as saídas do codificador Manchester Diferencial ao mesmo tempo
--
-- Instancia o núcleo manchester_dif (../../../src/manchester_dif.vhd) com 1 s
-- por bit e leva o mesmo sinal, no mesmo instante, para:
--   * LEDs e display de 7 segmentos da placa (como no projeto principal);
--   * saída VGA: tela verde em nível alto e azul em nível baixo
--     (controlador de ../../vga/src/vga_controller.vhd);
--   * conector PMOD JA, para o osciloscópio:
--       JA1 (pino J1) -> sinal codificado em Manchester Diferencial (canal 1)
--       JA2 (pino L2) -> dado original em NRZ                        (canal 2)
--
-- Como o bit dura 1 s, o osciloscópio deve ficar em modo de rolagem (Shift,
-- no Analog Discovery 3), com base de tempo da ordem de 1 a 2 s/div.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_dif_completo is
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
    Vsync    : out std_logic;
    ja       : out std_logic_vector(1 downto 0)    -- JA(0) = codificado, JA(1) = NRZ
  );
end entity;

architecture rtl of manchester_dif_completo is
  signal codificado : std_logic;
  signal nrz        : std_logic;
begin
  encoder: entity work.manchester_dif
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk      => clk,
      btn_rst  => btn_rst,
      data_in  => sw,
      data_out => codificado,
      nrz_out  => nrz,
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

  -- PMOD: as duas saídas já vêm registradas do núcleo
  ja(0) <= codificado;
  ja(1) <= nrz;
end architecture;
