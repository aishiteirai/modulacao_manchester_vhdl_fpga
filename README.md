# Codificação Manchester em VHDL

Trabalho da disciplina de **Comunicação de Dados – Sistemas Reconfiguráveis**, ministrada pelo professor Vinícius Borges, na Faculdade Engenheiro Salvador Arena (FESA).
7º semestre, 2026 · Grupo **[número a confirmar]**.

## Integrantes

- Bianca Ricci
- Diogo Santos Rodrigues
- Gustavo Marmo
- Leonardo Rosário Teixeira
- Ryan Corazza Alvarenga

## Descrição

Este trabalho implementa, em VHDL, dois codificadores de linha: **Manchester**, na convenção IEEE 802.3 (0 = descida, 1 = subida no meio do bit), e **Manchester Diferencial**, em que sempre há transição no meio do bit e o valor do bit é dado pela transição no início do intervalo (0 = inverte, 1 = mantém), com nível baixo após o reset.

Os dois circuitos são simulados no Vivado Simulator e implementados na placa Basys 3. A sequência de 16 bits é definida pelos switches e transmitida de SW15 a SW0; o sinal codificado aparece no LED acima do switch em transmissão, em um pino do conector PMOD (para o osciloscópio) e na saída VGA, que muda a cor da tela conforme o nível do sinal.

## Estrutura do repositório

```
.
├── README.md                 Este arquivo
├── CONTRIBUTING.md           Combinados de trabalho do grupo
├── ferramentas/              Script que gera os PDFs a partir dos documentos em Markdown
├── enunciado.pdf             Enunciado do trabalho
├── guia_entrega.pdf          Guia de entrega via GitHub
├── guia_documentacao.pdf     Guia de documentação
├── manchester/               Projeto Manchester (auto-contido)
│   ├── src/ sim/ constraints/ vivado_project/
│   ├── docs/                 Tutoriais e documentação técnica
│   └── saidas/               Saídas PMOD (osciloscópio) e VGA
├── manchester_diferencial/   Projeto Manchester Diferencial (mesma estrutura)
└── relatorio_final/          Relatório técnico consolidado e vídeo de demonstração
```

Cada projeto possui sua própria pasta `docs/`, com tutoriais e documentação técnica, e uma pasta `saidas/`, com as saídas PMOD e VGA.

## Projetos

- [Manchester](./manchester/): bit dado pelo sentido da transição no meio do bit
- [Manchester Diferencial](./manchester_diferencial/): bit dado pela presença de transição no início do bit

## Relatório

- [Relatório técnico final](./relatorio_final/relatorio.pdf)
- [Vídeo de demonstração](./relatorio_final/video_demo.mp4)

## Ferramentas utilizadas

- AMD Vivado 2025.2 e Vivado Simulator
- GHDL 4.1 (pré-validação das simulações e da síntese)
- Placa Digilent Basys 3 (FPGA Artix-7 `xc7a35tcpg236-1`)
- Osciloscópio de dois canais (saída PMOD)
- Monitor VGA (saída VGA)

## Como começar

Recomenda-se iniciar pelo projeto Manchester. Acesse a pasta [manchester/](./manchester/) e siga o README local.

## Documentos do enunciado

- [Enunciado](./enunciado.pdf): descrição do trabalho, requisitos e critério de avaliação
- [Guia de entrega](./guia_entrega.pdf): fluxo de entrega via GitHub e estrutura de pastas
- [Guia de documentação](./guia_documentacao.pdf): conteúdo de READMEs, tutoriais, documentação e relatório
