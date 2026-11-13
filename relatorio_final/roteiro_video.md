# Roteiro do Vídeo de Demonstração

Duração alvo: **5 a 7 minutos**. Gravar no dia do laboratório, com a placa, o osciloscópio e o monitor VGA disponíveis. O vídeo final vai para `relatorio_final/video_demo.mp4` ou, se o arquivo for grande, para um link no README raiz.

## Preparação (antes de gravar)

- [ ] Bitstreams gerados: Manchester, Manchester Diferencial, PMOD dos dois e VGA dos dois
- [ ] Celular em suporte ou tripé, com a placa, o display e os LEDs bem enquadrados
- [ ] Ambiente sem reflexo nos LEDs (evitar luz direta sobre a placa)
- [ ] Osciloscópio já configurado (ver `tutorial_pmod`) e monitor VGA ligado
- [ ] Switches na primeira sequência de teste antes de cada cena
- [ ] Definir quem narra cada cena (sugestão: o responsável por cada parte)

## Cenas

| # | Duração | Cena | Quem narra | O que mostrar e falar |
|:---:|:---:|---|---|---|
| 1 | 0:30 | Abertura | Ryan | Nome do trabalho, disciplina, integrantes. Mostrar a placa Basys 3 e explicar rapidamente: switches = sequência de bits, LEDs = sinal codificado, display = número do bit |
| 2 | 0:45 | Simulação | Ryan e Bianca | Tela do Vivado com a forma de onda dos dois projetos e o console com "Simulacao concluida sem erros" (pode ser gravação de tela) |
| 3 | 1:00 | Manchester na placa | Ryan | Sequência `1011001011110000`: acompanhar 4 ou 5 bits narrando "bit 1: apagado e depois aceso; bit 0: aceso e depois apagado". Mostrar o display acompanhando o índice |
| 4 | 0:30 | Reset e troca de switches | Ryan | Segurar o BTNC (tudo apaga) e soltar (recomeça em LD15). Trocar um switch durante a transmissão e mostrar a mudança na volta seguinte |
| 5 | 1:00 | Manchester Diferencial na placa | Bianca | Mesma sequência. Mostrar que o LED sempre muda no meio do bit e que, na passagem de posição, o novo LED começa igual (bit 1) ou oposto (bit 0) ao anterior. Mostrar o nível baixo após o reset |
| 6 | 1:00 | Osciloscópio (PMOD) | Diogo | Tela do osciloscópio com CH1 (codificado) e CH2 (NRZ) para os dois códigos. Apontar as transições do meio do bit e, no Diferencial, a inversão no início dos bits 0 |
| 7 | 0:45 | VGA | Leonardo | Monitor piscando verde e azul para os dois códigos, com a placa visível no mesmo quadro |
| 8 | 0:30 | Encerramento | Gustavo | Resumo da comparação: os dois códigos são autossincronizantes e sem componente DC, mas exigem o dobro da largura de banda do NRZ; o Diferencial não é afetado pela inversão de polaridade. Indicar onde está o repositório |

## Dicas de gravação

- Gravar cada cena separadamente e juntar na edição; é mais fácil refazer uma cena do que o vídeo inteiro
- Na placa, 1 s por bit é lento o bastante para narrar bit a bit; não é preciso acelerar o vídeo
- Para o osciloscópio, usar o botão **Run/Stop** para congelar uma captura enquanto se explica
- Gravar o áudio em ambiente silencioso ou narrar depois, sobre o vídeo editado
- Exportar em 1080p e conferir se o tamanho do arquivo é aceito no GitHub (limite de 100 MB por arquivo); se não for, publicar no YouTube (não listado) ou no Google Drive e colocar o link no README raiz
