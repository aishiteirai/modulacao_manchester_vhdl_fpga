# Tutorial de Gravação na Placa: Codificador Manchester

> Rascunho em Markdown do `tutorial_placa.pdf`. Os trechos **[print: ...]** e **[foto: ...]** marcam onde entram as imagens, que devem ser salvas em `docs/midia/` durante a execução do tutorial.

Este tutorial mostra como sintetizar o codificador Manchester, gerar o bitstream, gravar a placa Basys 3 e testar o funcionamento.

## 1. Pré-requisitos

| Item | Observação |
|---|---|
| AMD Vivado | versão **a definir pelo grupo**, com suporte à família Artix-7 e os drivers de cabo instalados (opção *Install Cable Drivers* no instalador) |
| Placa Digilent Basys 3 | jumper **JP1** na posição **JTAG** |
| Cabo micro-USB | ligado ao conector **PROG/UART** da placa |
| Projeto Vivado | aberto conforme o [tutorial de simulação](./tutorial_simulacao.md) (`vivado_project/manchester.xpr` ou `create_project.tcl`) |

**[foto: placa Basys 3 com o jumper JP1 em JTAG e o cabo USB ligado]**

## 2. Síntese

1. No painel **Sources › Design Sources**, conferir que `manchester` está em negrito (top). Se não estiver, clicar com o botão direito sobre ele e escolher **Set as Top**;
2. Em **Flow Navigator › Synthesis**, clicar em **Run Synthesis** e confirmar com **OK**;
3. Aguardar a mensagem *Synthesis successfully completed*.

O código foi feito para não gerar *latches*; ao final da síntese, a aba **Messages** não deve ter erros (*Errors*) nem avisos críticos (*Critical Warnings*).

**[print: mensagem de síntese concluída e aba Messages]**

## 3. Implementação

1. Na janela que aparece após a síntese, escolher **Run Implementation** (ou clicar em **Flow Navigator › Implementation › Run Implementation**);
2. Aguardar a mensagem *Implementation successfully completed*;
3. Abrir **Open Implemented Design › Report Timing Summary** e conferir que o **WNS** (*Worst Negative Slack*) é positivo: o circuito atende ao clock de 100 MHz.

**[print: Timing Summary com WNS positivo]**

## 4. Geração do bitstream

1. Clicar em **Flow Navigator › Program and Debug › Generate Bitstream**;
2. Aguardar *Bitstream Generation successfully completed*. O arquivo gerado é `vivado_project/manchester.runs/impl_1/manchester.bit`.

Se aparecer o erro de porta sem pino (*NSTD-1* ou *UCIO-1*), alguma porta do módulo não está no arquivo `constraints/manchester.xdc`. Todas as portas (`clk`, `btn_rst`, `data_in`, `data_out`, `nrz_out`, `led`, `seg` e `an`) já estão mapeadas nesse arquivo.

**[print: mensagem de bitstream gerado]**

## 5. Conexão da placa

1. Ligar o cabo micro-USB entre o computador e a placa;
2. Ligar a chave **POWER** da placa; o LED de alimentação acende;
3. No Vivado, clicar em **Flow Navigator › Program and Debug › Open Hardware Manager**;
4. Clicar em **Open Target › Auto Connect**. A FPGA `xc7a35t_0` deve aparecer no painel **Hardware**.

Se a placa não aparecer, conferir o cabo (alguns cabos só carregam, sem dados) e se os drivers de cabo do Vivado foram instalados.

**[print: Hardware Manager com a xc7a35t_0 conectada]**

## 6. Programação

1. Clicar em **Program Device** (ou com o botão direito em `xc7a35t_0` › **Program Device**);
2. Conferir se o campo **Bitstream file** aponta para `manchester.bit` e clicar em **Program**;
3. Ao final, o LED **DONE** da placa acende e o circuito começa a funcionar.

A gravação é perdida quando a placa é desligada; para usar de novo, basta repetir esta etapa.

**[print: janela Program Device]**

## 7. Mapeamento de uso na placa

| Elemento | Pino(s) | Função |
|---|---|---|
| SW15..SW0 | R2 ... V17 | Sequência de bits (para cima = 1), transmitida de SW15 a SW0 |
| LD15..LD0 | L1 ... U16 | Sinal codificado no LED acima do switch em transmissão; os demais ficam apagados |
| BTNC (botão central) | U18 | Reset: enquanto pressionado, tudo apaga; ao soltar, a transmissão recomeça em SW15 |
| Display de 7 segmentos | W7...U7 / U2...W4 | Número do bit em transmissão (15 a 0) |
| PMOD JA1 / JA2 | J1 / L2 | Sinal codificado / dado original (para o osciloscópio) |

Cada bit dura **1 s**: 0,5 s na primeira metade e 0,5 s na segunda. O LED ativo percorre a fileira da esquerda para a direita (LD15 → LD0) e recomeça.

**Como conferir (convenção IEEE 802.3):** com o switch abaixo do LED ativo em **1**, o LED fica **apagado e depois aceso**; com o switch em **0**, fica **aceso e depois apagado**.

**[foto: placa em funcionamento com o display e um LED aceso]**

## 8. Como testar

| Teste | Switches (SW15 → SW0) | O que deve acontecer |
|---|---|---|
| Todos em 0 | `0000000000000000` | Em cada posição, o LED acende na 1ª metade e apaga na 2ª |
| Todos em 1 | `1111111111111111` | Em cada posição, o LED fica apagado na 1ª metade e acende na 2ª |
| Alternados | `1010101010101010` | LD15 apagado→aceso, LD14 aceso→apagado, LD13 apagado→aceso... |
| Exemplo do enunciado | `1011001011110000` | Mesma sequência da simulação; comparar com a forma de onda de referência do tutorial de simulação |
| Reset | qualquer | Segurar o BTNC: LEDs e display apagam. Soltar: recomeça em LD15, com o display mostrando 15 |
| Troca de switch | qualquer | Mudar um switch enquanto o seu LED está ativo: o bit atual não muda; a mudança aparece na próxima volta |

**[vídeo: cerca de 20 s de cada teste, para o vídeo de demonstração]**

## 9. Problemas comuns

| Sintoma | Causa provável |
|---|---|
| Nenhum LED acende | O BTNC está preso ou a placa não foi programada (LED DONE apagado) |
| LEDs piscam rápido demais | Foi gravado o bitstream da saída PMOD (1 ms por bit) em vez do projeto principal |
| A ordem dos LEDs parece invertida | Conferir se a sequência está sendo lida de SW15 (esquerda) para SW0 (direita) |
| `Program Device` não aparece | O Hardware Manager não está conectado: repetir **Open Target › Auto Connect** |
