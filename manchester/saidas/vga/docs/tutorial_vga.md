# Tutorial da Saída VGA: Manchester com Cores Pulsantes

> Rascunho em Markdown do `tutorial_vga.pdf`. Os trechos **[foto: ...]** e **[print: ...]** marcam onde entram as imagens, que devem ser salvas em `docs/midia/` durante a execução.

Este tutorial mostra como gravar a saída VGA do codificador Manchester na Basys 3 e interpretar as cores da tela.

## 1. Pré-requisitos

- Vivado 2025.2 instalado (mesma versão usada no projeto principal)
- Placa Basys 3 e cabo micro-USB
- Monitor com entrada VGA e cabo VGA
- Projeto principal já simulado e testado na placa

## 2. Criação do projeto Vivado

1. Abrir o Vivado e o **Tcl Console** (menu **Window**);
2. Executar:
   ```tcl
   cd C:/fpga/modulacao_manchester_vhdl_fpga/manchester/saidas/vga/vivado_project
   source create_project.tcl
   ```
3. Conferir no painel **Sources** que `manchester_vga` é o top da síntese e que `manchester.vhd`, `display_7seg.vhd` e `vga_controller.vhd` aparecem abaixo dele.

**[print: painel Sources do projeto manchester_vga]**

Opcionalmente, rodar **Run Behavioral Simulation**: o testbench do top simula cerca de três quadros de vídeo (50 ms), o que pode levar alguns minutos, e deve terminar com `Simulacao concluida sem erros`.

## 3. Geração do bitstream e gravação

1. Clicar em **Generate Bitstream**;
2. Conectar a placa pelo USB, com o jumper JP1 na posição **JTAG**, e ligar a chave **POWER**;
3. Em **Open Hardware Manager › Open Target › Auto Connect**, clicar em **Program Device**.

**[print: Hardware Manager com a placa programada]**

## 4. Conexão do monitor

1. Ligar o cabo VGA entre o conector VGA da placa e o monitor;
2. Selecionar a entrada VGA no monitor.

O monitor deve reconhecer o modo **640x480 a 60 Hz**. Se aparecer "sem sinal" ou "fora de faixa", conferir o cabo e a seleção de entrada; alguns monitores levam alguns segundos para sincronizar.

**[foto: placa ligada ao monitor]**

## 5. O que observar

| Cor da tela | Nível do sinal codificado |
|---|---|
| Verde | alto (1) |
| Azul | baixo (0) |

Cada bit dura 1 s e a tela muda de cor no meio de todo bit (0,5 s). Na convenção IEEE 802.3:

- **bit 1:** azul e depois verde;
- **bit 0:** verde e depois azul.

O LED acima do switch em transmissão acende junto com o verde, e o display de 7 segmentos mostra o número do bit, o que ajuda a acompanhar a sequência.

Sequência esperada para os primeiros bits de `1011001011110000`:

![Sequência de cores esperada](midia/tela_esperada.svg)

Sequências sugeridas para testar:

| Sequência | O que observar |
|---|---|
| todos em 1 | azul e verde alternando a cada 0,5 s, sempre começando o bit em azul |
| todos em 0 | o mesmo ritmo, mas começando o bit em verde |
| alternados (`1010...`) | cores trocam apenas no meio dos bits: blocos de 1 s de cada cor |
| BTNC pressionado | tela azul (saída em nível baixo) até soltar o botão |

**[foto/vídeo: tela verde e tela azul, com a placa e o display visíveis]**
