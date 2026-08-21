#!/usr/bin/env python3
"""Gera as páginas do GitHub Pages a partir do Markdown da política.

    python3 tools/gerar_politica.py

Saídas em `docs/`: `politica-privacidade.html`, `index.html` e `.nojekyll`.

Por que um gerador e não HTML escrito à mão: documento LEGAL em duas
cópias divergentes é problema jurídico. O Markdown é a fonte; o HTML é
derivado e nunca editado à mão.

`.nojekyll` desliga o Jekyll de propósito: sem ele o GitHub renderizaria
TODO o `docs/` como site (instruções internas, telas do design). Com ele,
o Pages serve só o que existe como HTML — as duas páginas abaixo.

Converte o subconjunto de Markdown usado no documento: h1/h2, parágrafos,
listas, tabelas, blockquote, hr, negrito e `código`.
"""
import html
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
FONTE = RAIZ / "docs/politica-privacidade.md"
SAIDA = RAIZ / "docs/politica-privacidade.html"
INDICE = RAIZ / "docs/index.html"

# Paleta dos tokens do design (Cosmic Soft) — a página parece do jogo.
CSS = """
:root {
  --fundo: #12141F; --fundo-fim: #191430; --superficie: #1B1F30;
  --borda: rgba(255,255,255,.12); --texto: #F4F6FF; --secundario: #A6AECB;
  --muted: #7E88A8; --verde: #4ADE80;
}
* { box-sizing: border-box; }
body {
  margin: 0; padding: 32px 20px 64px;
  background: linear-gradient(160deg, var(--fundo), var(--fundo-fim));
  background-attachment: fixed; color: var(--texto);
  font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
        "Helvetica Neue", Arial, sans-serif;
}
main { max-width: 720px; margin: 0 auto; }
h1 { font-size: 28px; line-height: 1.25; margin: 0 0 4px; }
h2 { font-size: 20px; margin: 40px 0 12px; color: var(--verde); }
p, li { color: var(--secundario); }
strong { color: var(--texto); }
a { color: var(--verde); }
code {
  background: rgba(255,255,255,.06); border: 1px solid var(--borda);
  border-radius: 6px; padding: 1px 5px; font-size: 13px; color: var(--texto);
}
hr { border: 0; border-top: 1px solid var(--borda); margin: 32px 0; }
ul { padding-left: 22px; }
li { margin: 6px 0; }
.cabecalho { color: var(--muted); font-size: 14px; margin: 0 0 24px; }
.cabecalho strong { color: var(--secundario); }
blockquote { display: none; }  /* nota interna de manutenção */
.tabela { overflow-x: auto; margin: 16px 0; }
table { border-collapse: collapse; width: 100%; min-width: 420px; }
th, td {
  border: 1px solid var(--borda); padding: 10px 12px;
  text-align: left; vertical-align: top; font-size: 15px;
}
th { background: rgba(255,255,255,.05); color: var(--texto); }
td { color: var(--secundario); }
.cobra { font-size: 40px; line-height: 1; margin-bottom: 8px; }
.rodape {
  margin-top: 56px; padding-top: 20px; border-top: 1px solid var(--borda);
  color: var(--muted); font-size: 13px;
}
"""


def inline(texto: str) -> str:
    """Negrito, código e links de e-mail dentro de uma linha."""
    saida = html.escape(texto)
    saida = re.sub(r"`([^`]+)`", r"<code>\1</code>", saida)
    saida = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", saida)
    saida = re.sub(r"([\w.+-]+@[\w.-]+\.\w+)", r'<a href="mailto:\1">\1</a>', saida)
    return saida


def converter(md: str) -> str:
    linhas = md.split("\n")
    corpo: list[str] = []
    i = 0
    while i < len(linhas):
        linha = linhas[i]
        crua = linha.strip()

        if not crua or crua.startswith(">"):
            i += 1
            continue
        if crua == "---":
            corpo.append("<hr>")
            i += 1
            continue
        if crua.startswith("## "):
            corpo.append("<h2>%s</h2>" % inline(crua[3:]))
            i += 1
            continue
        if crua.startswith("# "):
            corpo.append('<div class="cobra">🐍</div>')
            corpo.append("<h1>%s</h1>" % inline(crua[2:]))
            i += 1
            continue

        # Tabela: linha de cabeçalho seguida de separador |---|
        if crua.startswith("|") and i + 1 < len(linhas) and set(
            linhas[i + 1].strip().replace("|", "").replace(":", "").replace(" ", "")
        ) == {"-"}:
            celulas = [c.strip() for c in crua.strip("|").split("|")]
            corpo.append('<div class="tabela"><table><thead><tr>')
            corpo += ["<th>%s</th>" % inline(c) for c in celulas]
            corpo.append("</tr></thead><tbody>")
            i += 2
            while i < len(linhas) and linhas[i].strip().startswith("|"):
                colunas = [c.strip() for c in linhas[i].strip().strip("|").split("|")]
                corpo.append("<tr>" + "".join("<td>%s</td>" % inline(c) for c in colunas) + "</tr>")
                i += 1
            corpo.append("</tbody></table></div>")
            continue

        # Lista: itens podem continuar em linhas indentadas
        if crua.startswith("- "):
            corpo.append("<ul>")
            while i < len(linhas) and linhas[i].strip().startswith("- "):
                item = linhas[i].strip()[2:]
                i += 1
                while i < len(linhas) and linhas[i].startswith("  ") \
                        and not linhas[i].strip().startswith("- "):
                    item += " " + linhas[i].strip()
                    i += 1
                corpo.append("<li>%s</li>" % inline(item))
            corpo.append("</ul>")
            continue

        # Parágrafo (junta linhas até a próxima em branco)
        paragrafo = [crua]
        i += 1
        while i < len(linhas) and linhas[i].strip() and not linhas[i].strip().startswith(
            ("#", "-", "|", ">", "---")
        ):
            paragrafo.append(linhas[i].strip())
            i += 1
        # O bloco de metadados do topo tem uma informação POR LINHA — juntar
        # com espaço (regra normal do Markdown) grudaria data, pacote e
        # responsável num parágrafo ilegível.
        if paragrafo[0].startswith("**Última atualização:**"):
            corpo.append('<p class="cabecalho">%s</p>'
                % "<br>".join(inline(l) for l in paragrafo))
        else:
            corpo.append("<p>%s</p>" % inline(" ".join(paragrafo)))

    return "\n".join(corpo)


PAGINA = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%(titulo)s</title>
<meta name="description" content="Política de privacidade do Snakito — jogo educacional para crianças de 7+ anos.">
<style>%(css)s</style>
</head>
<body>
<main>
%(corpo)s
<p class="rodape">Snakito · com.rodrigowaters.snakito · contato
<a href="mailto:rdrgwtrs@gmail.com">rdrgwtrs@gmail.com</a></p>
</main>
</body>
</html>
"""

INDEX = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Snakito</title>
<style>%(css)s
main { text-align: center; padding-top: 40px; }
.botao {
  display: inline-block; margin-top: 24px; padding: 14px 26px;
  border-radius: 999px; background: linear-gradient(135deg, #4ADE80, #2FBF8F);
  color: #0B2416; font-weight: 700; text-decoration: none;
}
</style>
</head>
<body>
<main>
<div class="cobra">🐍</div>
<h1>Snakito</h1>
<p>Jogo educacional de arena para crianças a partir de 7 anos —
estratégia em tempo real, risco e recompensa. Jogável offline.</p>
<a class="botao" href="politica-privacidade.html">Política de Privacidade</a>
<p class="rodape">Contato: <a href="mailto:rdrgwtrs@gmail.com">rdrgwtrs@gmail.com</a></p>
</main>
</body>
</html>
"""


def main() -> int:
    if not FONTE.exists():
        print("fonte não encontrada: %s" % FONTE, file=sys.stderr)
        return 1
    md = FONTE.read_text(encoding="utf-8")
    SAIDA.write_text(
        PAGINA % {
            "titulo": "Política de Privacidade — Snakito",
            "css": CSS,
            "corpo": converter(md),
        },
        encoding="utf-8",
    )
    INDICE.write_text(INDEX % {"css": CSS}, encoding="utf-8")
    (RAIZ / "docs/.nojekyll").write_text("", encoding="utf-8")
    print("gerado: %s (%d bytes)" % (SAIDA.name, SAIDA.stat().st_size))
    print("gerado: %s" % INDICE.name)
    print("gerado: .nojekyll (Pages não renderiza o resto de docs/)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
