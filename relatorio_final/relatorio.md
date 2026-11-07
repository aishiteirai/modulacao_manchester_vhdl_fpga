# Relatório Técnico: Codificação de Linha Manchester em VHDL

> Rascunho em Markdown do `relatorio.pdf`. As seções marcadas como **[pendente]** são preenchidas nas fases seguintes, com os resultados de cada integrante. Ao final, o conteúdo deve ser passado para o modelo comum de PDF do grupo. O relatório é escrito no passado e de forma impessoal.

---

## Capa

**Codificação de Linha Manchester e Manchester Diferencial em VHDL (Vivado)**

Comunicação de Dados – Sistemas Reconfiguráveis

Professor(a): **[pendente]**
Instituição: **[pendente]**
Semestre: **[pendente]**
Grupo: **[pendente]**

Integrantes:

- Bianca Ricci
- Diogo Santos Rodrigues
- Gustavo Marmo
- Leonardo Rosário Teixeira
- Ryan Corazza Alvarenga

---

## Resumo

**[pendente]** Escrever ao final (5 a 10 linhas): o que foi implementado (codificadores Manchester IEEE 802.3 e Manchester Diferencial em VHDL, simulados no Vivado Simulator e implementados na Basys 3, com saídas em LEDs, PMOD e VGA) e os principais resultados obtidos.

---

## 1. Introdução

Em sistemas de comunicação digital, os bits precisam ser convertidos em sinais elétricos adequados ao meio de transmissão. Essa conversão é feita pela **codificação de linha**, que define como cada bit, ou sequência de bits, é representado por níveis e transições de tensão. A escolha do código de linha afeta diretamente características como a largura de banda necessária, a presença de componente contínua (DC) e a capacidade do receptor de recuperar o sincronismo a partir do próprio sinal.

Os códigos da família NRZ (*Non-Return-to-Zero*) são simples, mas não garantem transições quando há longas sequências de bits iguais, o que dificulta a sincronização entre transmissor e receptor. Os códigos Manchester resolvem esse problema ao impor uma transição no meio de todo intervalo de bit, tornando o sinal **autossincronizante**, ao custo de aproximadamente o dobro da largura de banda. O código Manchester é utilizado, por exemplo, no Ethernet a 10 Mbit/s (IEEE 802.3).

### 1.1 Objetivo geral

Desenvolver, simular e implementar em FPGA codificadores de linha Manchester e Manchester Diferencial, utilizando a linguagem VHDL e a ferramenta Vivado, e analisar o comportamento dos sinais gerados.

### 1.2 Objetivos específicos

- Implementar em VHDL um codificador Manchester na convenção IEEE 802.3 e um codificador Manchester Diferencial com nível baixo após o reset;
- Verificar o funcionamento dos dois codificadores por simulação comportamental no Vivado Simulator, com testbenches autoverificáveis;
- Implementar os circuitos na placa Basys 3, com a sequência de bits definida pelos switches e o sinal codificado apresentado nos LEDs;
- Observar os sinais codificados em um osciloscópio, por meio do conector PMOD, e em um monitor, por meio da saída VGA;
- Comparar os dois códigos entre si e com os códigos NRZ.

---

## 2. Fundamentação teórica

### 2.1 Codificação de linha e o código NRZ

A codificação de linha associa a cada bit um ou mais elementos de sinal. Uma distinção importante é entre a **taxa de bits** (*N*, em bit/s) e a **taxa de sinalização** ou taxa de modulação (*S*, em baud), que corresponde ao número de elementos de sinal por segundo. A largura de banda necessária para transmitir um sinal digital é proporcional à taxa de sinalização (FOROUZAN, 2010).

No código **NRZ-L** (*Non-Return-to-Zero Level*), o nível do sinal representa diretamente o valor do bit e permanece constante durante todo o intervalo. No **NRZ-I** (*Non-Return-to-Zero Invert*), o bit 1 é representado por uma inversão do nível no início do intervalo e o bit 0 pela ausência de inversão. Nos dois casos, longas sequências de bits iguais (no NRZ-L) ou de zeros (no NRZ-I) produzem um sinal sem transições, o que provoca dois problemas (FOROUZAN, 2010; STALLINGS, 2014):

- **perda de sincronismo:** sem transições, o receptor não consegue corrigir a diferença entre o seu relógio e o do transmissor;
- **componente DC:** um sinal que permanece muito tempo em um mesmo nível tem valor médio diferente de zero, o que é inadequado para meios que não transmitem baixas frequências, como enlaces acoplados por transformador.

### 2.2 Código Manchester

No código **Manchester**, o intervalo de bit é dividido em duas metades e sempre há uma transição no meio do bit. O valor do bit é indicado pelo **sentido** da transição. Existem duas convenções:

| Convenção | Bit 0 | Bit 1 |
|---|---|---|
| **IEEE 802.3** (adotada neste trabalho) | alto → baixo (descida) | baixo → alto (subida) |
| G. E. Thomas | baixo → alto (subida) | alto → baixo (descida) |

Na convenção IEEE 802.3, o sinal Manchester equivale à operação XNOR entre o dado em NRZ-L e um relógio que vale 0 na primeira metade e 1 na segunda metade de cada bit.

### 2.3 Código Manchester Diferencial

No código **Manchester Diferencial**, também há sempre uma transição no meio do bit, mas ela serve apenas ao sincronismo. O valor do bit é indicado pela **presença ou ausência de transição no início** do intervalo: o bit 0 provoca uma inversão do nível no início do bit, e o bit 1 mantém o nível anterior (FOROUZAN, 2010). Como a codificação depende do nível anterior, o codificador precisa de memória, e o sinal gerado depende do nível inicial; neste trabalho, o nível após o reset é baixo.

O Manchester Diferencial combina a ideia do NRZ-I (informação na transição, e não no nível) com a transição no meio do bit do Manchester. Ele é utilizado, por exemplo, nas redes Token Ring (IEEE 802.5).

### 2.4 Autossincronização

Nos dois códigos Manchester há pelo menos uma transição por bit, independentemente da sequência transmitida. O receptor pode usar essas transições para recuperar o relógio do transmissor, sem necessidade de um sinal de relógio separado. Por isso, esses códigos são chamados de **autossincronizantes** (STALLINGS, 2014).

### 2.5 Componente DC

Em ambos os códigos Manchester, cada bit passa metade do intervalo em nível alto e metade em nível baixo. Com níveis simétricos (+V e −V), o valor médio do sinal é nulo em todo intervalo de bit, e o sinal **não possui componente DC**, ao contrário do NRZ (FOROUZAN, 2010).

### 2.6 Largura de banda

A transição obrigatória no meio do bit faz com que o sinal Manchester tenha até duas transições por bit. A taxa de sinalização média é igual à taxa de bits (*S = N*), contra *S = N/2* nos códigos NRZ. Consequentemente, os códigos Manchester exigem **aproximadamente o dobro da largura de banda** de um código NRZ com a mesma taxa de bits (FOROUZAN, 2010).

| Característica | NRZ-L | NRZ-I | Manchester | Manchester Diferencial |
|---|---|---|---|---|
| Informação no(a) | nível | transição no início do bit | sentido da transição no meio | transição no início do bit |
| Transições por bit | 0 a 1 | 0 a 1 | 1 a 2 | 1 a 2 |
| Autossincronizante | não | não | sim | sim |
| Componente DC | sim | sim | não | não |
| Largura de banda relativa | 1× | 1× | ≈ 2× | ≈ 2× |
| Sensível à inversão de polaridade | sim | não | sim | não |

### 2.7 Inversão de polaridade

Se os fios de um par forem trocados, todos os níveis do sinal são invertidos. No Manchester, isso inverte o sentido de todas as transições do meio do bit e, portanto, **inverte todos os bits** recebidos. No Manchester Diferencial, a informação está na presença ou ausência de transição, e não no sentido; uma inversão de polaridade preserva as transições e **não altera os dados** (STALLINGS, 2014).

---

## 3. Metodologia

O trabalho foi organizado nas seguintes etapas:

1. **Estudo** dos códigos de linha e da especificação do trabalho;
2. **Implementação em VHDL** dos dois codificadores, a partir de uma interface comum (`clk`, `btn_rst`, `data_in`, `data_out`, `nrz_out`, `led` e o generic `CYCLES_PER_BIT`), o que permitiu o desenvolvimento em paralelo das saídas PMOD e VGA;
3. **Simulação comportamental** no Vivado Simulator, com testbenches que verificam automaticamente, por meio de `assert`, o nível esperado em cada metade de cada bit;
4. **Síntese, implementação e geração do bitstream** no Vivado;
5. **Gravação na placa** Basys 3 e testes com diferentes sequências nos switches;
6. **Observação dos sinais** no osciloscópio (saída PMOD) e no monitor (saída VGA).

O desenvolvimento foi dividido entre os integrantes e acompanhado por *issues* no repositório Git do grupo.

**Ferramentas utilizadas:** AMD Vivado (versão **[pendente]**), Vivado Simulator, placa Digilent Basys 3 (FPGA Artix-7 `xc7a35tcpg236-1`), osciloscópio **[pendente: modelo]**, monitor VGA e Git/GitHub.

---

## 4. Desenvolvimento

**[pendente]** Para cada projeto: descrição do que foi implementado, decisões de projeto (por exemplo, o uso da porta XNOR no Manchester, o registrador de nível no Manchester Diferencial, as saídas registradas e o sincronizador do botão), a duração de bit adotada na placa (1 s) e no osciloscópio (1 ms), as dificuldades encontradas e como foram resolvidas. Pedir um parágrafo a cada responsável.

---

## 5. Resultados

**[pendente]**

- Prints das simulações, com identificação dos sinais (índice do bit, bit atual, sinal codificado e LEDs);
- Fotos da placa em funcionamento;
- Capturas do osciloscópio (saída PMOD), com os sinais e as transições do meio do bit identificados;
- Fotos ou vídeo da tela VGA.

---

## 6. Análise e discussão

**[pendente]**

- Comparação entre Manchester e Manchester Diferencial (vantagens, desvantagens, características do sinal, comportamento com inversão de polaridade);
- Comparação dos códigos Manchester com os códigos NRZ (número de transições por bit, sincronismo, largura de banda);
- Comparação entre o resultado da simulação e o obtido na placa;
- Interpretação dos resultados observados.

---

## 7. Conclusões

**[pendente]** Principais aprendizados, limitações observadas, possíveis melhorias ou trabalhos futuros.

---

## Referências

> Conferir edição, ano e editora de cada obra efetivamente consultada antes da versão final.

DIGILENT. **Basys 3 Reference Manual**. Pullman: Digilent, [s.d.]. Disponível em: https://digilent.com/reference/programmable-logic/basys-3/reference-manual. Acesso em: **[pendente]**.

DIGILENT. **Basys-3-Master.xdc**. Repositório digilent-xdc. Disponível em: https://github.com/Digilent/digilent-xdc. Acesso em: **[pendente]**.

FOROUZAN, B. A. **Comunicação de dados e redes de computadores**. 4. ed. Porto Alegre: AMGH, 2010.

IEEE. **IEEE Std 802.3: IEEE Standard for Ethernet**. New York: IEEE, 2022.

STALLINGS, W. **Data and computer communications**. 10. ed. Upper Saddle River: Pearson, 2014.

TANENBAUM, A. S.; WETHERALL, D. **Redes de computadores**. 5. ed. São Paulo: Pearson Prentice Hall, 2011.
