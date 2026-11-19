# Todas as Saídas ao Mesmo Tempo: Manchester

Reúne em um único bitstream as três formas de visualizar o sinal codificado em Manchester: **LEDs e display de 7 segmentos** da placa, **tela VGA** (verde em nível alto, azul em nível baixo) e **conector PMOD JA** para o osciloscópio. As três saídas vêm do mesmo núcleo, então mostram o mesmo sinal no mesmo instante, o que facilita a gravação do vídeo de demonstração.

Para que os LEDs e a tela possam ser acompanhados a olho nu, o bit dura **1 s**, como no projeto principal. Por isso o osciloscópio deve ser usado em modo de rolagem (veja abaixo). Para capturas paradas, com trigger, continue usando a [saída PMOD](../pmod_osciloscopio/), que transmite a 1 ms por bit.

## Estrutura desta pasta

```
completo/
├── src/               Top manchester_completo (núcleo + VGA + PMOD)
├── sim/               Testbench que confere as três saídas juntas
├── constraints/       Mapeamento dos pinos: placa, conector VGA e PMOD JA
└── vivado_project/    Script que cria o projeto Vivado desta saída
```

## Arquivos de código

- `src/manchester_completo.vhd`: top que liga o núcleo `../../src/manchester.vhd` aos LEDs, ao display, ao controlador `../vga/src/vga_controller.vhd` e aos pinos JA1/JA2, sem copiar nenhum desses arquivos
- `sim/manchester_completo_tb.vhd`: testbench autoverificável que confere, a cada ciclo de clock, o PMOD, os LEDs, o display e a cor da tela VGA em relação a uma instância de referência do núcleo; inclui um toque no BTNC para conferir que o VGA mantém o sincronismo durante o reset
- `constraints/manchester_completo.xdc`: pinos da saída VGA mais JA1 (J1) e JA2 (L2)
- `vivado_project/create_project.tcl`: script que recria o projeto Vivado

## Simulação

No Tcl Console do Vivado:

```tcl
cd <caminho do repositório>/manchester/saidas/completo/vivado_project
source create_project.tcl
```

Depois, **Run Simulation › Run Behavioral Simulation**. O testbench usa 10 ms por bit e simula 50 ms (cerca de três quadros VGA), o que pode levar alguns minutos. Ao final, o console deve mostrar:

```
Simulacao concluida sem erros (3 quadros; PMOD, LEDs, display e VGA conferidos)
```

Na janela de formas de onda, os sinais `ja`, `led`, `seg`/`an`, `vgaGreen`/`vgaBlue` e `Hsync`/`Vsync` podem ser observados lado a lado.

## Ligações na placa

| Saída | Ligação |
|---|---|
| LEDs e display | na própria placa |
| VGA | monitor no conector VGA |
| PMOD | CH1 em JA1 (sinal codificado), CH2 em JA2 (dado original), terra no pino 5 ou 11 |

## Configuração do osciloscópio

Com 1 s por bit, cada metade de bit dura 0,5 s e uma volta completa dos 16 bits leva 16 s. No Analog Discovery 3 (WaveForms):

| Parâmetro | Valor |
|---|---|
| Mode | **Shift** (a forma de onda rola pela tela) |
| Base de tempo | 2 s/div (20 s na tela: uma volta completa) ou 1 s/div |
| Trigger | Auto |
| Range | 1 V/div nos dois canais |

## Como reproduzir

1. Criar o projeto Vivado executando `vivado_project/create_project.tcl` no Tcl Console;
2. Gerar o bitstream e gravar a placa;
3. Ligar o monitor no conector VGA e as pontas de prova em JA1, JA2 e GND;
4. Configurar os switches e observar a placa, a tela e o osciloscópio ao mesmo tempo.
