# Combinados do grupo

Regras de trabalho para o desenvolvimento do projeto de codificação Manchester. O planejamento completo e a divisão de tarefas estão na issue #17.

## Integrantes e responsabilidades

| Integrante | Área | Issues |
|---|---|---|
| Ryan | Coordenação e projeto Manchester | #1, #2, #4, #16 |
| Bianca | Projeto Manchester Diferencial | #3, #5, #6 |
| Diogo | Saída PMOD (osciloscópio) | #7, #8, #9 |
| Leonardo | Saída VGA | #10, #11, #12 |
| Gustavo | Documentação técnica e relatório | #13, #14, #15 |

## Ferramentas

| Item | Definição |
|---|---|
| Vivado | **versão a definir** (todos devem usar a mesma) |
| Placa | Basys 3 (Artix-7, `xc7a35tcpg236-1`) |
| Constraints | partir do `Basys-3-Master.xdc` da Digilent |
| PDFs (tutoriais, documentação e relatório) | **ferramenta a definir** (ex.: Overleaf ou Google Docs), com modelo comum |
| Data do laboratório | **a definir** |

## Interface do núcleo

Os dois projetos usam a mesma interface. Ela permite que PMOD, VGA e documentação avancem em paralelo com os codificadores, por isso **não deve ser alterada sem avisar o grupo**.

```vhdl
entity manchester is  -- manchester_dif no projeto diferencial
  generic ( CYCLES_PER_BIT : positive := 100_000_000 );  -- deve ser par
  port (
    clk      : in  std_logic;                      -- 100 MHz (W5)
    btn_rst  : in  std_logic;                      -- BTNC (U18)
    data_in  : in  std_logic_vector(15 downto 0);  -- SW15..SW0
    data_out : out std_logic;                      -- sinal codificado (registrado)
    nrz_out  : out std_logic;                      -- bit atual / dado original
    led      : out std_logic_vector(15 downto 0);  -- LD15..LD0
    seg      : out std_logic_vector(6 downto 0);   -- display de 7 segmentos (g..a)
    an       : out std_logic_vector(3 downto 0)    -- anodos do display (AN3..AN0)
  );
end entity;
```

As portas `seg` e `an` foram acrescentadas pela issue #6 (display de 7 segmentos). Tops que instanciam o núcleo, como os do PMOD e do VGA, podem deixá-las sem conexão, mas precisam incluir `display_7seg.vhd` entre os arquivos do projeto.

Toda porta do top precisa ter pino no `.xdc`; caso contrário, o *Generate Bitstream* falha.

## Fluxo de Git

1. Atualizar a `main` antes de começar:
   ```bash
   git checkout main
   git pull origin main
   ```
2. Criar uma branch por issue, no formato `issue-<número>-<descrição>`:
   ```bash
   git checkout -b issue-3-dif-core
   ```
3. Fazer commits pequenos e frequentes, com mensagens descritivas em português e referência à issue:
   ```
   Diferencial: adiciona registrador de nível (Refs #3)
   ```
4. Enviar a branch e abrir um Pull Request **dentro do fork**, para a `main`, com `Closes #<número>` na descrição.
5. Ao final do trabalho, a `main` do fork é enviada ao repositório oficial pelo PR da issue #16 (base: `grupoX`).

### Autoria

Cada integrante faz commit do próprio trabalho, com o Git configurado com a própria conta do GitHub:

```bash
git config --global user.name "Seu Nome"
git config --global user.email "email-cadastrado@no-github.com"
```

Quando alguém fizer commit do trabalho de outra pessoa, adicionar ao final da mensagem:

```
Co-authored-by: Nome <email-cadastrado@no-github.com>
```

## Arquivos

- Cada pessoa trabalha nas pastas da sua área, para evitar conflitos. O `README.md` da raiz fica com o Ryan.
- Prints, fotos, vídeos e capturas vão para a pasta `docs/midia/` do projeto ou da saída correspondente **desde o início**.
- Não versionar arquivos gerados pelo Vivado (`.runs`, `.cache`, `.sim` etc.); o `.gitignore` já cuida disso. Versionar os `.vhd`, `.xdc`, `.xpr` e `.wcfg`.
- Os arquivos `.gitkeep` só existem para manter as pastas vazias no Git e podem ser apagados quando a pasta receber arquivos.
