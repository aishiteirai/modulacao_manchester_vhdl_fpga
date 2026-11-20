--------------------------------------------------------------------------------
-- Codificador Manchester Diferencial
--
-- Transmite ciclicamente os 16 bits de data_in, do MSB (SW15) ao LSB (SW0).
-- Cada bit dura CYCLES_PER_BIT ciclos de clock. Sempre há inversão do nível
-- no meio do bit (sincronismo); o valor do bit é dado pelo início do intervalo:
--   bit 0 -> inverte o nível no início do bit
--   bit 1 -> mantém o nível anterior no início do bit
-- O nível da saída após o reset é baixo.
--
-- O sinal codificado sai em data_out e no LED acima do switch em transmissão;
-- os demais LEDs ficam apagados. O display de 7 segmentos mostra o número do
-- bit em transmissão (15 a 0), e o conector VGA mostra a tela inteira verde
-- (sinal em nível alto) ou azul (nível baixo). Enquanto btn_rst está
-- pressionado, a transmissão fica parada e a saída em nível baixo; ao soltar,
-- recomeça em SW15.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity manchester_dif is
  generic (
    CYCLES_PER_BIT : positive := 100_000_000  -- 1 s por bit a 100 MHz (deve ser par)
  );
  port (
    clk      : in  std_logic;                      -- clock de 100 MHz (W5)
    btn_rst  : in  std_logic;                      -- reset, botão BTNC (U18)
    data_in  : in  std_logic_vector(15 downto 0);  -- sequência de bits (SW15..SW0)
    data_out : out std_logic;                      -- sinal codificado
    nrz_out  : out std_logic;                      -- bit em transmissão (dado original)
    led      : out std_logic_vector(15 downto 0);  -- LD15..LD0
    seg      : out std_logic_vector(6 downto 0);   -- segmentos do display (g..a)
    an       : out std_logic_vector(3 downto 0);   -- anodos do display (AN3..AN0)
    vgaRed   : out std_logic_vector(3 downto 0);   -- conector VGA: tela inteira
    vgaGreen : out std_logic_vector(3 downto 0);   --   verde com o sinal em nível alto
    vgaBlue  : out std_logic_vector(3 downto 0);   --   e azul em nível baixo
    Hsync    : out std_logic;
    Vsync    : out std_logic
  );
end entity;

architecture rtl of manchester_dif is
  constant HALF_BIT : natural := CYCLES_PER_BIT / 2;  -- ciclo do meio do bit

  -- Sincronizador do botão (assíncrono em relação ao clock)
  signal rst_sync : std_logic_vector(1 downto 0) := (others => '1');
  signal rst      : std_logic;

  -- Contador de ciclos dentro do bit e índice do bit em transmissão
  signal cnt : natural range 0 to CYCLES_PER_BIT - 1 := 0;
  signal idx : natural range 0 to 15 := 15;

  -- Último nível transmitido; também é o flip-flop de saída do sinal codificado
  signal nivel_reg : std_logic := '0';

  -- Demais saídas registradas
  signal nrz_reg : std_logic := '0';
  signal led_reg : std_logic_vector(15 downto 0) := (others => '0');

  -- Saída VGA 640x480 @ 60 Hz (mesma temporização do controlador da pasta
  -- saidas/vga): 640 + 16 + 96 + 48 = 800 pixels por linha e
  -- 480 + 10 + 2 + 33 = 525 linhas por quadro, sincronismos ativos em 0
  constant H_VISIBLE : natural := 640;
  constant H_SYNC_I  : natural := 656;  -- início do pulso de Hsync
  constant H_SYNC_F  : natural := 752;  -- fim do pulso de Hsync
  constant H_TOTAL   : natural := 800;
  constant V_VISIBLE : natural := 480;
  constant V_SYNC_I  : natural := 490;
  constant V_SYNC_F  : natural := 492;
  constant V_TOTAL   : natural := 525;
  constant COR_ALTA  : std_logic_vector(11 downto 0) := x"0F0";  -- verde
  constant COR_BAIXA : std_logic_vector(11 downto 0) := x"00F";  -- azul

  signal pix_div : natural range 0 to 3 := 0;  -- clock de pixel: 100 MHz / 4
  signal h_cnt   : natural range 0 to H_TOTAL - 1 := 0;
  signal v_cnt   : natural range 0 to V_TOTAL - 1 := 0;
  signal rgb_reg : std_logic_vector(11 downto 0) := (others => '0');
  signal hs_reg  : std_logic := '1';
  signal vs_reg  : std_logic := '1';
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
    variable b     : std_logic;
    variable nivel : std_logic;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt       <= 0;
        idx       <= 15;
        nivel_reg <= '0';  -- nível baixo após o reset
        nrz_reg   <= '0';
        led_reg   <= (others => '0');
      else
        nivel := nivel_reg;

        if cnt = 0 then
          -- Início do bit: lê o switch e aplica a regra de transição
          -- (o valor fica guardado em nrz_reg até o próximo bit)
          b := data_in(idx);
          if b = '0' then
            nivel := not nivel;
          end if;
          nrz_reg <= b;
        elsif cnt = HALF_BIT then
          -- Meio do bit: sempre inverte
          nivel := not nivel;
        end if;

        nivel_reg <= nivel;
        led_reg <= (others => '0');
        led_reg(idx) <= nivel;

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

  -- Display de 7 segmentos com o número do bit em transmissão
  display: entity work.display_7seg
    port map (
      clk    => clk,
      rst    => rst,
      numero => idx,
      seg    => seg,
      an     => an
    );

  -- Saída VGA: a cor da tela acompanha o sinal codificado. O VGA não é
  -- reiniciado pelo botão, para o monitor não perder o sincronismo.
  process(clk)
  begin
    if rising_edge(clk) then
      if pix_div = 3 then
        pix_div <= 0;
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
      else
        pix_div <= pix_div + 1;
      end if;

      if h_cnt >= H_SYNC_I and h_cnt < H_SYNC_F then
        hs_reg <= '0';
      else
        hs_reg <= '1';
      end if;

      if v_cnt >= V_SYNC_I and v_cnt < V_SYNC_F then
        vs_reg <= '0';
      else
        vs_reg <= '1';
      end if;

      if h_cnt < H_VISIBLE and v_cnt < V_VISIBLE then
        if nivel_reg = '1' then
          rgb_reg <= COR_ALTA;
        else
          rgb_reg <= COR_BAIXA;
        end if;
      else
        rgb_reg <= (others => '0');
      end if;
    end if;
  end process;

  vgaRed   <= rgb_reg(11 downto 8);
  vgaGreen <= rgb_reg(7 downto 4);
  vgaBlue  <= rgb_reg(3 downto 0);
  Hsync    <= hs_reg;
  Vsync    <= vs_reg;

  data_out <= nivel_reg;
  nrz_out  <= nrz_reg;
  led      <= led_reg;
end architecture;
