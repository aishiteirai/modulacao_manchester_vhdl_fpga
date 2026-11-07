--------------------------------------------------------------------------------
-- Top da saída PMOD do codificador Manchester (osciloscópio)
--
-- Instancia o núcleo manchester (../../../src/manchester.vhd) com uma duração
-- de bit curta, para que o sinal possa ser observado no osciloscópio, e leva
-- ao conector PMOD JA:
--   JA1 (pino J1) -> sinal codificado em Manchester (canal 1 do osciloscópio)
--   JA2 (pino L2) -> dado original em NRZ           (canal 2 do osciloscópio)
--
-- Com CYCLES_PER_BIT = 100_000 e clock de 100 MHz, cada bit dura 1 ms
-- (taxa de 1 kbit/s, metade do bit de 0,5 ms). Nessa taxa os LEDs continuam
-- ligados ao núcleo, mas piscam rápido demais para acompanhar a olho nu.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_pmod is
  generic (
    CYCLES_PER_BIT : positive := 100_000  -- 1 ms por bit a 100 MHz (deve ser par)
  );
  port (
    clk     : in  std_logic;                      -- clock de 100 MHz (W5)
    btn_rst : in  std_logic;                      -- reset, botão BTNC (U18)
    sw      : in  std_logic_vector(15 downto 0);  -- sequência de bits (SW15..SW0)
    led     : out std_logic_vector(15 downto 0);  -- LD15..LD0
    ja      : out std_logic_vector(1 downto 0)    -- JA(0) = codificado, JA(1) = NRZ
  );
end entity;

architecture rtl of manchester_pmod is
begin
  encoder: entity work.manchester
    generic map (CYCLES_PER_BIT => CYCLES_PER_BIT)
    port map (
      clk      => clk,
      btn_rst  => btn_rst,
      data_in  => sw,
      data_out => ja(0),
      nrz_out  => ja(1),
      led      => led
    );
end architecture;
