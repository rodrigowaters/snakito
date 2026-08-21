#!/usr/bin/env python3
"""Extrai UMA tela do export do Claude Design, balanceando as <div>.

    extrair_blueprint.py            → lista os rótulos disponíveis
    extrair_blueprint.py "09b"      → grava o HTML da tela em /tmp e resume

O HTML de `docs/design/Snakito Telas.dc.html` é a fonte de verdade da
composição (26 telas). Sem isso, "fiel ao desenho" viraria chute.
"""
import os
import re
import sys

RAIZ = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
FONTE = os.path.join(RAIZ, "docs/design/Snakito Telas.dc.html")


def rotulos(html: str) -> list[str]:
    return sorted(set(re.findall(r'data-screen-label="([^"]+)"', html)))


def extrair(html: str, rotulo: str) -> "str | None":
    ini = html.find('data-screen-label="%s"' % rotulo)
    if ini < 0:
        return None
    ini = html.rfind("<div", 0, ini)
    profundidade = 0
    for m in re.finditer(r"<div\b|</div>", html[ini:]):
        profundidade += 1 if m.group(0) == "<div" else -1
        if profundidade == 0:
            return html[ini:ini + m.end()]
    return None


def main() -> int:
    if not os.path.exists(FONTE):
        print("fonte não encontrada: %s" % FONTE, file=sys.stderr)
        return 1
    html = open(FONTE, encoding="utf-8").read()
    disponiveis = rotulos(html)
    if len(sys.argv) < 2:
        print("telas disponíveis:")
        for r in disponiveis:
            print("  " + r)
        return 0

    busca = sys.argv[1].lower()
    achados = [r for r in disponiveis if busca in r.lower()]
    if not achados:
        print("nenhuma tela casa com %r. Disponíveis: %s"
              % (sys.argv[1], ", ".join(disponiveis)), file=sys.stderr)
        return 1
    if len(achados) > 1:
        print("ambíguo — %r casa com: %s" % (sys.argv[1], ", ".join(achados)),
              file=sys.stderr)
        return 1

    rotulo = achados[0]
    trecho = extrair(html, rotulo)
    if trecho is None:
        print("não deu para delimitar a tela %r" % rotulo, file=sys.stderr)
        return 1
    destino = "/tmp/blueprint_%s.html" % re.sub(r"\W+", "_", rotulo.lower())
    open(destino, "w", encoding="utf-8").write(trecho)
    print("tela:      %s" % rotulo)
    print("blueprint: %s (%d caracteres)" % (destino, len(trecho)))
    print("textos:    %s" % " · ".join(
        t.strip() for t in re.findall(r">([^<>{}]{3,40})<", trecho)[:14] if t.strip()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
