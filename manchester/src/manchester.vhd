--------------------------------------------------------------------------------
-- Codificador Manchester (convenção IEEE 802.3)
--
-- Transmite ciclicamente os 16 bits de data_in, do MSB (SW15) ao LSB (SW0).
-- Cada bit dura CYCLES_PER_BIT ciclos de clock e é dividido em duas metades:
--   bit 0 -> 1ª metade alta,  2ª metade baixa (descida no meio do bit)
--   bit 1 -> 1ª metade baixa, 2ª metade alta  (subida no meio do bit)
--
-- O sinal codificado sai em data_out e no LED acima do switch em transmissão;
-- os demais LEDs ficam apagados. Enquanto btn_rst está pressionado, a
-- transmissão fica parada e a saída em nível baixo; ao soltar, recomeça em SW15.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester is
  generic (
    CYCLES_PER_BIT : positive := 100_000_000  -- 1 s por bit a 100 MHz (deve ser par)
  );
  port (
    clk      : in  std_logic;                      -- clock de 100 MHz (W5)
    btn_rst  : in  std_logic;                      -- reset, botão BTNC (U18)
    data_in  : in  std_logic_vector(15 downto 0);  -- sequência de bits (SW15..SW0)
    data_out : out std_logic;                      -- sinal codificado
    nrz_out  : out std_logic;                      -- bit em transmissão (dado original)
    led      : out std_logic_vector(15 downto 0)   -- LD15..LD0
  );
end entity;

architecture rtl of manchester is
  constant HALF_BIT : natural := CYCLES_PER_BIT / 2;  -- ciclo do meio do bit

  -- Sincronizador do botão (assíncrono em relação ao clock)
  signal rst_sync : std_logic_vector(1 downto 0) := (others => '1');
  signal rst      : std_logic;

  -- Contador de ciclos dentro do bit e índice do bit em transmissão
  signal cnt : natural range 0 to CYCLES_PER_BIT - 1 := 0;
  signal idx : natural range 0 to 15 := 15;

  -- Bit atual, lido do switch no início do intervalo
  signal bit_reg : std_logic := '0';

  -- Saídas registradas (evitam glitches no PMOD)
  signal enc_reg : std_logic := '0';
  signal nrz_reg : std_logic := '0';
  signal led_reg : std_logic_vector(15 downto 0) := (others => '0');
begin
  assert CYCLES_PER_BIT mod 2 = 0
    report "CYCLES_PER_BIT deve ser par" severity failure;

  -- Dois flip-flops em série sincronizam o botão com o clock
  process(clk)
  begin
    if rising_edge(clk) then
      rst_sync <= rst_sync(0) & btn_rst;
    end if;
  end process;
  rst <= rst_sync(1);

  process(clk)
    variable b    : std_logic;
    variable metade : std_logic;
    variable enc  : std_logic;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt     <= 0;
        idx     <= 15;
        bit_reg <= '0';
        enc_reg <= '0';
        nrz_reg <= '0';
        led_reg <= (others => '0');
      else
        -- Lê o switch no início do bit; no restante do intervalo usa o valor
        -- guardado, para que mexer no switch só afete a próxima transmissão
        if cnt = 0 then
          b := data_in(idx);
          bit_reg <= b;
        else
          b := bit_reg;
        end if;

        -- '0' na 1ª metade do bit, '1' na 2ª
        if cnt < HALF_BIT then
          metade := '0';
        else
          metade := '1';
        end if;

        -- IEEE 802.3: 1ª metade = not bit, 2ª metade = bit  =>  bit XNOR metade
        enc := b xnor metade;

        enc_reg <= enc;
        nrz_reg <= b;
        led_reg <= (others => '0');
        led_reg(idx) <= enc;

        -- Fim do bit: zera o contador e passa para o próximo switch (15 -> 0 -> 15)
        if cnt = CYCLES_PER_BIT - 1 then
          cnt <= 0;
          if idx = 0 then
            idx <= 15;
          else
            idx <= idx - 1;
          end if;
        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process;

  data_out <= enc_reg;
  nrz_out  <= nrz_reg;
  led      <= led_reg;
end architecture;
