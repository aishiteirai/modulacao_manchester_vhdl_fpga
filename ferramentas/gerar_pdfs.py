"""Gera os PDFs da documentação a partir dos arquivos Markdown do repositório.

Cada documento (tutoriais, documentação técnica e relatório) é escrito em
Markdown e convertido para PDF com o mesmo modelo visual. Os PDFs são gerados
ao lado do arquivo .md, com o mesmo nome.

Instalação (uma vez):
    pip install markdown playwright
    playwright install chromium

Uso, a partir da raiz do repositório:
    python ferramentas/gerar_pdfs.py                  # todos os documentos
    python ferramentas/gerar_pdfs.py relatorio_final/relatorio.md   # só um

Os marcadores de imagens pendentes (por exemplo **[foto: ...]**) aparecem no
PDF como caixas destacadas, para facilitar a conferência do que falta.
"""
import argparse
import pathlib
import re
import sys

import markdown
from playwright.sync_api import sync_playwright

RAIZ = pathlib.Path(__file__).resolve().parent.parent

DOCUMENTOS = [
    "manchester/docs/tutorial_simulacao.md",
    "manchester/docs/tutorial_placa.md",
    "manchester/docs/documentacao_projeto.md",
    "manchester/saidas/pmod_osciloscopio/docs/tutorial_pmod.md",
    "manchester/saidas/vga/docs/tutorial_vga.md",
    "manchester_diferencial/docs/tutorial_simulacao.md",
    "manchester_diferencial/docs/tutorial_placa.md",
    "manchester_diferencial/docs/documentacao_projeto.md",
    "manchester_diferencial/saidas/pmod_osciloscopio/docs/tutorial_pmod.md",
    "manchester_diferencial/saidas/vga/docs/tutorial_vga.md",
    "relatorio_final/relatorio.md",
]

CSS = """
@page { size: A4; margin: 18mm 17mm 18mm; }
body { font-family: Inter, "Segoe UI", Arial, sans-serif; font-size: 10.2pt;
       line-height: 1.5; color: #1f2430; }
h1 { font-size: 21pt; margin: 0 0 4mm; padding-bottom: 2.5mm;
     border-bottom: 3px solid #2563eb; }
h2 { font-size: 14pt; margin: 7mm 0 2mm; color: #1e3a8a; page-break-after: avoid; }
h3 { font-size: 11.5pt; margin: 5mm 0 1.5mm; page-break-after: avoid; }
p, li { text-align: justify; }
table { border-collapse: collapse; width: 100%; margin: 2.5mm 0 4mm;
        font-size: 9.2pt; page-break-inside: avoid; }
th { background: #eef2ff; text-align: left; }
th, td { border: 1px solid #d1d5db; padding: 1.6mm 2.2mm; vertical-align: top; }
code { font-family: "JetBrains Mono", Consolas, monospace; font-size: 8.8pt;
       background: #f1f3f6; padding: 0 1mm; border-radius: 1mm; }
pre { background: #1f2430; color: #e5e7eb; padding: 3mm; border-radius: 2mm;
      font-size: 8.4pt; white-space: pre-wrap; page-break-inside: avoid; }
pre code { background: none; color: inherit; padding: 0; }
img { max-width: 100%; display: block; margin: 3mm auto; page-break-inside: avoid; }
p > em:only-child { display: block; text-align: center; color: #6b7280;
                    font-size: 9pt; margin-top: -1.5mm; }
blockquote { margin: 3mm 0; padding: 2mm 4mm; border-left: 3px solid #2563eb;
             background: #f6f7f9; color: #374151; }
hr { border: none; border-top: 1px solid #e5e7eb; margin: 6mm 0; }
.pendente { border: 1.5px dashed #d97706; background: #fffbeb; color: #92400e;
            padding: 2.5mm 3.5mm; border-radius: 2mm; margin: 3mm 0; font-size: 9.2pt; }
"""

RODAPE = (
    '<div style="font-family:Arial,sans-serif;font-size:7.5pt;color:#6b7280;'
    'width:100%;padding:0 17mm;display:flex;justify-content:space-between">'
    '<span>{titulo}</span><span><span class="pageNumber"></span> / '
    '<span class="totalPages"></span></span></div>'
)

MARCADOR = re.compile(r"^\*\*\[((?:print|foto|vídeo|foto/print|print/foto|foto/vídeo)[^\]]*)\]\*\*$",
                      re.IGNORECASE | re.MULTILINE)


def preparar(texto):
    """Remove o aviso de rascunho e destaca os marcadores de imagem pendente."""
    linhas = texto.splitlines()
    linhas = [l for l in linhas if not l.startswith("> Rascunho")]
    texto = "\n".join(linhas)
    return MARCADOR.sub(lambda m: f'<div class="pendente">Pendente: {m.group(1)}</div>', texto)


def converter(pagina, md_path):
    texto = preparar(md_path.read_text(encoding="utf-8"))
    titulo = re.search(r"^# (.+)$", texto, re.MULTILINE)
    titulo = titulo.group(1).strip() if titulo else md_path.stem
    corpo = markdown.markdown(texto, extensions=["tables", "fenced_code", "sane_lists", "attr_list"])
    html = (f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
            f'<base href="{md_path.parent.as_uri()}/"><title>{titulo}</title>'
            f"<style>{CSS}</style></head><body>{corpo}</body></html>")
    pagina.set_content(html, wait_until="load")
    pdf = md_path.with_suffix(".pdf")
    pagina.pdf(path=str(pdf), format="A4", print_background=True, prefer_css_page_size=True,
               display_header_footer=True, header_template="<span></span>",
               footer_template=RODAPE.format(titulo=titulo))
    return pdf


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("arquivos", nargs="*", help="arquivos .md (padrão: todos os documentos)")
    parser.add_argument("--chromium", help="caminho de um executável do Chromium já instalado")
    args = parser.parse_args()

    alvos = [pathlib.Path(a).resolve() for a in args.arquivos] or [RAIZ / d for d in DOCUMENTOS]
    faltando = [a for a in alvos if not a.exists()]
    if faltando:
        sys.exit("Arquivos não encontrados: " + ", ".join(map(str, faltando)))

    with sync_playwright() as p:
        navegador = p.chromium.launch(executable_path=args.chromium) if args.chromium else p.chromium.launch()
        pagina = navegador.new_page()
        for md_path in alvos:
            pdf = converter(pagina, md_path)
            print(f"gerado {pdf.relative_to(RAIZ)}")
        navegador.close()


if __name__ == "__main__":
    main()
