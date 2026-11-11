--------------------------------------------------------------------------------
-- Testbench do controlador VGA 640x480 @ 60 Hz
--
-- Simula cerca de três quadros e verifica com assert:
--   * período e largura do pulso de hsync (32 us e 3,84 us);
--   * período e largura do pulso de vsync (16,8 ms e 64 us);
--   * cores em zero durante os sincronismos (fora da área visível);
--   * cor da tela de acordo com o nível de entrada (COR_ALTA / COR_BAIXA).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity vga_controller_tb is
end entity;

architecture sim of vga_controller_tb is
  constant CLK_PERIOD : time := 10 ns;                -- 100 MHz
  constant PIXEL      : time := 4 * CLK_PERIOD;       -- 25 MHz
  constant LINE       : time := 800 * PIXEL;          -- 32 us
  constant FRAME      : time := 525 * LINE;           -- 16,8 ms

  constant COR_BAIXA : std_logic_vector(11 downto 0) := x"00F";
  constant COR_ALTA  : std_logic_vector(11 downto 0) := x"0F0";

  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal nivel  : std_logic := '0';
  signal vga_r  : std_logic_vector(3 downto 0);
  signal vga_g  : std_logic_vector(3 downto 0);
  signal vga_b  : std_logic_vector(3 downto 0);
  signal vga_hs : std_logic;
  signal vga_vs : std_logic;
  signal rgb    : std_logic_vector(11 downto 0);

  signal sim_done : boolean := false;
begin
  clk <= not clk after CLK_PERIOD / 2 when not sim_done;
  rgb <= vga_r & vga_g & vga_b;

  dut: entity work.vga_controller
    generic map (COR_BAIXA => COR_BAIXA, COR_ALTA => COR_ALTA)
    port map (
      clk    => clk,
      rst    => rst,
      nivel  => nivel,
      vga_r  => vga_r,
      vga_g  => vga_g,
      vga_b  => vga_b,
      vga_hs => vga_hs,
      vga_vs => vga_vs
    );

  -- Estímulo: o nível muda a cada 5 ms, como um sinal codificado lento
  stimulus: process
  begin
    wait for 5 * CLK_PERIOD;
    rst <= '0';
    for k in 1 to 10 loop  -- 50 ms: cerca de 3 quadros
      wait for 5 ms;
      nivel <= not nivel;
    end loop;
    sim_done <= true;
    wait;
  end process;

  -- Mede período e largura do hsync a cada borda
  hsync_check: process
    variable t_fall, t_prev_fall : time := 0 ns;
    variable n : natural := 0;
  begin
    wait until falling_edge(vga_hs) or sim_done;
    if sim_done then wait; end if;
    t_fall := now;
    if n > 0 then
      assert t_fall - t_prev_fall = LINE
        report "Periodo de hsync errado: " & time'image(t_fall - t_prev_fall) severity error;
    end if;
    wait until rising_edge(vga_hs);
    assert now - t_fall = 96 * PIXEL
      report "Largura de hsync errada: " & time'image(now - t_fall) severity error;
    t_prev_fall := t_fall;
    n := n + 1;
  end process;

  -- Mede período e largura do vsync
  vsync_check: process
    variable t_fall, t_prev_fall : time := 0 ns;
    variable n : natural := 0;
  begin
    wait until falling_edge(vga_vs) or sim_done;
    if sim_done then
      assert n >= 2 report "Menos de dois pulsos de vsync simulados" severity error;
      report "Pulsos de vsync verificados: " & integer'image(n) severity note;
      wait;
    end if;
    t_fall := now;
    if n > 0 then
      assert t_fall - t_prev_fall = FRAME
        report "Periodo de vsync errado: " & time'image(t_fall - t_prev_fall) severity error;
    end if;
    wait until rising_edge(vga_vs);
    assert now - t_fall = 2 * LINE
      report "Largura de vsync errada: " & time'image(now - t_fall) severity error;
    t_prev_fall := t_fall;
    n := n + 1;
  end process;

  -- Cores: zero durante os sincronismos; na área visível, conforme o nível
  color_check: process(clk)
  begin
    if rising_edge(clk) and rst = '0' then
      if vga_hs = '0' or vga_vs = '0' then
        assert rgb = x"000" report "Cor diferente de zero durante o sincronismo" severity error;
      elsif rgb /= x"000" then
        if nivel = '1' then
          assert rgb = COR_ALTA or rgb = COR_BAIXA report "Cor invalida na tela" severity error;
        end if;
      end if;
    end if;
  end process;

  -- No meio de cada período do nível, o centro da tela deve ter a cor certa
  center_check: process
    variable checks : natural := 0;
  begin
    wait until rst = '0';
    loop
      -- vsync sobe no início de uma linha; depois do back porch (33 linhas)
      -- vem a linha 0. Espera a linha 240 e o pixel 320 (centro da tela).
      wait until rising_edge(vga_vs) or sim_done;
      exit when sim_done;
      wait for 33 * LINE + 240 * LINE + 320 * PIXEL;
      exit when sim_done;  -- o clock já parou
      if nivel = '1' then
        assert rgb = COR_ALTA report "Centro da tela deveria estar em COR_ALTA" severity error;
      else
        assert rgb = COR_BAIXA report "Centro da tela deveria estar em COR_BAIXA" severity error;
      end if;
      checks := checks + 1;
    end loop;
    report "Verificacoes de cor no centro da tela: " & integer'image(checks) severity note;
    wait;
  end process;
end architecture;
