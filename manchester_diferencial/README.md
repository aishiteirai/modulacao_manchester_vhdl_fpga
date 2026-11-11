# Codificação Manchester Diferencial

Implementação em VHDL do código Manchester Diferencial, em que sempre há transição no meio do bit e o valor do bit é dado pela transição no início do intervalo: **0 = inversão do nível** e **1 = mantém o nível anterior**. **Nível após o reset: baixo.** O circuito transmite ciclicamente os 16 bits dos switches da placa Basys 3, de SW15 a SW0, e apresenta o sinal codificado no LED acima do switch em transmissão.

## Estrutura desta pasta

```
manchester_diferencial/
├── src/                 Código-fonte VHDL do circuito
├── sim/                 Testbench para simulação
├── constraints/         Mapeamento dos pinos da FPGA (.xdc)
├── vivado_project/      Projeto Vivado e script para recriá-lo
├── docs/                Tutoriais e documentação técnica
│   └── midia/           Prints, fotos e vídeos
└── saidas/              Saídas PMOD (osciloscópio) e VGA
```

## Arquivos de código

- `src/manchester_dif.vhd`: código-fonte do codificador (contador de ciclos, índice do bit, registrador de nível com a regra de transição e saídas registradas)
- `src/display_7seg.vhd`: display de 7 segmentos com o número do bit em transmissão
- `sim/manchester_dif_tb.vhd`: testbench autoverificável, que acompanha o nível esperado a partir do reset
- `sim/display_7seg_tb.vhd`: testbench do display de 7 segmentos
- `constraints/manchester_dif.xdc`: mapeamento do clock, do BTNC, dos switches, dos LEDs, do display e dos pinos JA1/JA2 do PMOD
- `vivado_project/create_project.tcl`: script que recria o projeto Vivado

## Documentação

- [Tutorial de simulação](./docs/tutorial_simulacao.pdf): como simular no Vivado passo a passo
- [Tutorial de gravação na placa](./docs/tutorial_placa.pdf): como sintetizar, gerar o bitstream e gravar na FPGA
- [Documentação técnica](./docs/documentacao_projeto.pdf): diagrama de blocos, interface e funcionamento interno

## Por onde começar

Para uma **simulação rápida** (apenas ver funcionando):

1. Abrir o Vivado e carregar `vivado_project/manchester_dif.xpr`
2. Clicar em **Run Simulation › Run Behavioral Simulation**

Para **reproduzir o projeto do zero**, seguir esta ordem:

1. **Entender o circuito** lendo a [documentação técnica](./docs/documentacao_projeto.pdf)
2. **Comparar com o Manchester** (visto no [projeto anterior](../manchester/)) para identificar as diferenças na lógica de transição
3. **Simular no Vivado** seguindo o [tutorial de simulação](./docs/tutorial_simulacao.pdf)
4. **Gravar na placa** seguindo o [tutorial de gravação](./docs/tutorial_placa.pdf)
5. **Implementar as saídas** [PMOD e VGA](./saidas/)

## Uso na placa

| Elemento | Função |
|---|---|
| SW15..SW0 | Sequência de bits (para cima = 1), transmitida de SW15 a SW0 |
| LD15..LD0 | Sinal codificado no LED acima do switch em transmissão |
| BTNC | Reset: enquanto pressionado, a saída fica apagada; ao soltar, recomeça em SW15 a partir do nível baixo |
| Display de 7 segmentos | Número do bit em transmissão (15 a 0) |
| PMOD JA1 / JA2 | Sinal codificado / dado original |

Cada bit dura 1 s. O LED ativo **sempre muda de estado no meio do bit**. Na passagem para a posição seguinte, o novo LED começa no **mesmo estado** em que o anterior terminou se o bit for **1**, e no **estado oposto** se o bit for **0**.

## Saídas PMOD e VGA

- [Saída pelo PMOD para osciloscópio](./saidas/pmod_osciloscopio/)
- [Saída VGA com cores pulsantes](./saidas/vga/)

## Próximo passo

Os dois projetos do trabalho estão concluídos. Acesse o [Relatório técnico final](../relatorio_final/relatorio.pdf) para ver a análise comparativa entre os dois códigos, os resultados obtidos e as conclusões do grupo.
