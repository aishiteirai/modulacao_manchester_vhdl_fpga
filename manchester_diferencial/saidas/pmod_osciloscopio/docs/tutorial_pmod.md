# Tutorial da Saída PMOD: Manchester Diferencial no Osciloscópio

> Rascunho em Markdown do `tutorial_pmod.pdf`. Os trechos **[foto: ...]** e **[print: ...]** marcam onde entram as imagens, que devem ser salvas em `docs/midia/` durante a execução.

Este tutorial mostra como gravar a saída PMOD do codificador Manchester Diferencial na Basys 3 e observar no osciloscópio o sinal codificado junto com o dado original.

## 1. Pré-requisitos

- Vivado 2025.2 instalado (mesma versão usada no projeto principal)
- Placa Basys 3 e cabo micro-USB
- Osciloscópio de dois canais e duas pontas de prova, ou o Analog Discovery 3 com o programa WaveForms (seção 7)
- Projeto principal já simulado (ver o tutorial de simulação do Manchester Diferencial)

## 2. Criação do projeto Vivado

1. Abrir o Vivado e o **Tcl Console** (menu **Window**);
2. Executar:
   ```tcl
   cd C:/fpga/modulacao_manchester_vhdl_fpga/manchester_diferencial/saidas/pmod_osciloscopio/vivado_project
   source create_project.tcl
   ```
3. Conferir no painel **Sources** que `manchester_dif_pmod` é o top da síntese e que `manchester_dif.vhd` e `display_7seg.vhd` aparecem abaixo dele.

**[print: painel Sources do projeto manchester_dif_pmod]**

Opcionalmente, rodar **Run Behavioral Simulation**: o testbench simula 16 ms (pode levar alguns minutos) e deve terminar com `Simulacao concluida sem erros`.

## 3. Geração do bitstream e gravação

1. Clicar em **Generate Bitstream** (a síntese e a implementação são executadas automaticamente);
2. Conectar a placa pelo USB, com o jumper JP1 na posição **JTAG**, e ligar a chave **POWER**;
3. Em **Open Hardware Manager › Open Target › Auto Connect**, clicar em **Program Device**.

**[print: Hardware Manager com a placa conectada]**

## 4. Conexão do osciloscópio

O conector JA tem duas fileiras de 6 pinos. Na fileira identificada pelos pinos 1 a 6, os pinos 1 a 4 são os sinais **JA1 a JA4**, o pino 5 é **GND** e o pino 6 é **VCC (3,3 V)**; a outra fileira repete o padrão com JA7 a JA10, GND (pino 11) e VCC (pino 12). Conferir a numeração na serigrafia da placa antes de ligar as pontas e **nunca ligar a garra de terra no VCC**, o que colocaria a alimentação em curto.

| Ponta | Ligar em |
|---|---|
| CH1 (sinal) | JA1: sinal Manchester Diferencial |
| CH2 (sinal) | JA2: dado NRZ |
| Garras de terra | GND (pino 5 ou 11) |

**[foto: pontas de prova ligadas ao conector JA]**

## 5. Configuração do osciloscópio

| Ajuste | Valor sugerido | Motivo |
|---|---|---|
| Escala vertical (CH1 e CH2) | 1 V/div | sinais de 0 a 3,3 V |
| Acoplamento | DC | mostra os níveis reais do sinal |
| Base de tempo | 2 ms/div | 20 ms na tela: uma volta completa de 16 bits (16 ms) |
| Trigger | CH2, borda de subida, nível ≈ 1,6 V, modo **Normal** | sincroniza com o dado NRZ |

Para uma imagem estável, configurar os switches para que o dado tenha **uma única borda de subida por volta**, por exemplo SW15 = 1 e SW14..SW0 = 0. Assim o trigger dispara sempre no início da sequência. Outra opção é usar o ajuste de *holdoff* do trigger em cerca de 15 ms.

Para ver um único bit em detalhe, reduzir a base de tempo para **200 µs/div**: cada bit ocupa 5 divisões e a transição do meio do bit fica no centro.

## 6. Captura

Sequências sugeridas (switches de SW15 a SW0):

| Sequência | O que observar |
|---|---|
| `1011001011110000` | mesma sequência da simulação; comparar com a figura abaixo |
| todos em 1 | transições só no meio de cada bit (nunca no início): onda quadrada de 500 Hz |
| todos em 0 | transições no início e no meio de cada bit: onda quadrada de 1 kHz |
| `1100110011001100` | alterna trechos de 500 Hz (bits 1) e 1 kHz (bits 0), mostrando os dois casos da regra |

Forma de onda esperada para `1011001011110000`:

![Forma de onda esperada](midia/forma_onda_esperada.svg)

Em cada captura, identificar os canais e a escala de tempo e marcar: as transições do meio do bit (presentes em todos os bits), as inversões no início dos bits 0 e a ausência de transição no início dos bits 1. Uma captura logo após soltar o BTNC mostra o nível baixo após o reset. Salvar a imagem pelo próprio osciloscópio (pendrive) ou fotografar a tela.

## 7. Configuração usada no laboratório (Analog Discovery 3)

Nos testes de 16/11/2026, o sinal foi observado com o **Analog Discovery 3**, um osciloscópio USB da Digilent controlado pelo programa **WaveForms**, usando apenas o canal 1, ligado ao sinal codificado:

| Fio do Analog Discovery 3 | Ligação na placa |
|---|---|
| **1+** (laranja) | pino 1 do JA (sinal codificado) |
| **1−** (laranja e branco) e **⏚** (preto) | GND do JA |

| Ajuste no WaveForms (Scope) | Valor |
|---|---|
| Channel 1 | Range 1 V/div, Offset −1,5 V |
| Time | Base 2 ms/div (volta completa) ou 200 µs/div (detalhe), Position 0 |
| Trigger | Mode Normal, Source Channel 1, Condition Rising, Level 1,6 V |
| Medida | Measurements › Add › Channel 1 › Frequency |

Com um único canal, não há a referência do dado original para marcar o início de cada bit; as capturas foram conferidas pela frequência medida e pela largura dos pulsos (0,5 ms ou 1 ms). Para registrar o reset, usar Mode **Shift** com Base 200 ms/div e Trigger **Auto**: a tela continua rolando e mostra a linha em 0 V enquanto o BTNC é pressionado.

## 8. Resultados obtidos

![Sequência do enunciado](midia/osc_sequencia.png)

*Figura: sequência `1011001011110000` (2 ms/div). Lida como Manchester Diferencial, a forma de onda resulta exatamente na sequência configurada nos switches.*

![Detalhe de dois bits](midia/osc_zoom_bit.png)

*Figura: detalhe (200 µs/div).*

![Todos os switches em 1](midia/osc_todos1.png)

*Figura: todos os switches em 1 (2 ms/div): só há transição no meio dos bits, e a onda tem pulsos de 1 ms.*

![Frequência com todos em 1](midia/osc_todos1_freq.png)

*Figura: frequência medida com todos os switches em 1: 500 Hz.*

![Todos os switches em 0](midia/osc_todos0.png)

*Figura: todos os switches em 0 (2 ms/div): transições no início e no meio de cada bit, pulsos de 0,5 ms.*

![Frequência com todos em 0](midia/osc_todos0_freq.png)

*Figura: frequência medida com todos os switches em 0: 1,0000 kHz.*

![Pares de bits iguais](midia/osc_pares.png)

*Figura: sequência `1100110011001100`: trechos de pulsos de 1 ms (bits 1) alternados com trechos de pulsos de 0,5 ms (bits 0).*

| Switches | Esperado | Medido |
|---|---|---|
| todos em 1 | onda regular de 500 Hz | 500,01 Hz ✅ |
| todos em 0 | onda regular de 1 kHz | 1,0000 kHz ✅ |
| `1100110011001100` | trechos de 500 Hz e de 1 kHz alternados | conforme o esperado ✅ |
| `1011001011110000` | decodificação igual à sequência dos switches | conforme o esperado ✅ |

Com os mesmos switches em 1, o Manchester produz 1 kHz e o Manchester Diferencial, 500 Hz: no Diferencial, o bit 1 mantém o nível no início do intervalo, e só resta a transição do meio do bit.
