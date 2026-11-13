# Codificação Manchester

Implementação em VHDL do código Manchester na **convenção IEEE 802.3**, em que o bit é representado pelo sentido da transição no meio do intervalo de bit: **0 = descida** (alto → baixo) e **1 = subida** (baixo → alto). O circuito transmite ciclicamente os 16 bits dos switches da placa Basys 3, de SW15 a SW0, e apresenta o sinal codificado no LED acima do switch em transmissão.

## Estrutura desta pasta

```
manchester/
├── src/                 Código-fonte VHDL do circuito
├── sim/                 Testbench para simulação
├── constraints/         Mapeamento dos pinos da FPGA (.xdc)
├── vivado_project/      Projeto Vivado e script para recriá-lo
├── docs/                Tutoriais e documentação técnica
│   └── midia/           Prints, fotos e vídeos
└── saidas/              Saídas PMOD (osciloscópio) e VGA
```

## Arquivos de código

- `src/manchester.vhd`: código-fonte do codificador (contador de ciclos, índice do bit, registrador do bit atual, codificador XNOR e saídas registradas)
- `sim/manchester_tb.vhd`: testbench autoverificável, com `assert` em cada metade de cada bit
- `constraints/manchester.xdc`: mapeamento do clock, do BTNC, dos switches, dos LEDs e dos pinos JA1/JA2 do PMOD
- `vivado_project/create_project.tcl`: script que recria o projeto Vivado

## Documentação

- [Tutorial de simulação](./docs/tutorial_simulacao.pdf): como simular no Vivado passo a passo
- [Tutorial de gravação na placa](./docs/tutorial_placa.pdf): como sintetizar, gerar o bitstream e gravar na FPGA
- [Documentação técnica](./docs/documentacao_projeto.pdf): diagrama de blocos, interface e funcionamento interno

## Por onde começar

Para uma **simulação rápida** (apenas ver funcionando):

1. Abrir o Vivado e carregar `vivado_project/manchester.xpr`
2. Clicar em **Run Simulation › Run Behavioral Simulation**

Para **reproduzir o projeto do zero**, seguir esta ordem:

1. **Entender o circuito** lendo a [documentação técnica](./docs/documentacao_projeto.pdf)
2. **Simular no Vivado** seguindo o [tutorial de simulação](./docs/tutorial_simulacao.pdf)
3. **Gravar na placa** seguindo o [tutorial de gravação](./docs/tutorial_placa.pdf)
4. **Implementar as saídas** [PMOD e VGA](./saidas/)

## Uso na placa

| Elemento | Função |
|---|---|
| SW15..SW0 | Sequência de bits (para cima = 1), transmitida de SW15 a SW0 |
| LD15..LD0 | Sinal codificado no LED acima do switch em transmissão |
| BTNC | Reset: enquanto pressionado, a saída fica apagada; ao soltar, recomeça em SW15 |
| PMOD JA1 / JA2 | Sinal codificado / dado original |

Cada bit dura 1 s. Com o switch em **1**, o LED ativo fica **apagado e depois aceso**; com o switch em **0**, fica **aceso e depois apagado**.

## Saídas PMOD e VGA

- [Saída pelo PMOD para osciloscópio](./saidas/pmod_osciloscopio/)
- [Saída VGA com cores pulsantes](./saidas/vga/)

## Próximo passo

Após concluir este projeto, seguir para a [Codificação Manchester Diferencial](../manchester_diferencial/), que implementa a outra versão estudada no trabalho.
