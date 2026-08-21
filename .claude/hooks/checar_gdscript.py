#!/usr/bin/env python3
"""Hook PostToolUse: compila o .gd editado e devolve os erros de parse.

Custa ~0.9s por arquivo. Existe porque a família de armadilhas de GDScript
registrada no CLAUDE.md (expressão não-constante, assinatura de plugin
errada, tipo incompatível) só aparecia no `--import` seguinte, um ciclo
depois — e às vezes só no aparelho.

`--check-only` sobre UM arquivo não conhece os autoloads do projeto
(`Rede`, `Anuncios`, `FilaSessoes`), então "Identifier not found: X" para
um nome de autoload é RUÍDO da ferramenta, não erro do código — a lista
sai do próprio project.godot para não desatualizar.
"""
import json
import os
import subprocess
import sys

RAIZ = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
GODOT = os.environ.get("GODOT_BIN", "godot")


def _autoloads():
    """Nomes dos autoloads declarados no project.godot."""
    nomes = []
    try:
        dentro = False
        for linha in open(os.path.join(RAIZ, "project.godot"), encoding="utf-8"):
            linha = linha.strip()
            if linha.startswith("["):
                dentro = linha == "[autoload]"
                continue
            if dentro and "=" in linha:
                nomes.append(linha.split("=", 1)[0].strip())
    except OSError:
        pass
    return nomes


def main() -> int:
    try:
        dados = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    caminho = (dados.get("tool_input") or {}).get("file_path", "")
    if not caminho.endswith(".gd") or "/addons/" in caminho:
        return 0
    if not os.path.exists(caminho):
        return 0

    try:
        proc = subprocess.run(
            [GODOT, "--headless", "--path", RAIZ, "--check-only", "-s", caminho],
            capture_output=True, text=True, cwd=RAIZ, timeout=60,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return 0  # sem engine no PATH: o hook não atrapalha o trabalho

    saida = proc.stdout + proc.stderr
    # Ruído da ferramenta, não erro nosso:
    #  · autoload não resolvido (o check de 1 arquivo não os conhece)
    #  · erro DENTRO de addons/ (o sample do AdMob referencia um SVG que o
    #    próprio addon gitignora — quem depende dele herda a queixa)
    #  · "Failed to compile depended scripts" é consequência, não causa: o
    #    erro real aparece quando o arquivo culpado for editado
    ruido = ["Identifier not found: %s" % nome for nome in _autoloads()]
    ruido += ["res://addons/", "Failed to compile depended scripts"]
    # Rodada poluída por erro em `addons/` derruba coisas em cascata. A
    # causa é NOSSA e deliberada: a higiene de APK (commit 811a2b5) apagou
    # 63 assets de sample do addon AdMob, e os mocks de editor `preload`
    # 5 deles. Isso não afeta o build Android (verificado no aparelho) —
    # os mocks só existem para preview de anúncio no desktop, que não
    # usamos. Só as FAMÍLIAS de cascata são silenciadas; erro de tipo ou
    # identificador nosso continua passando (coberto por teste).
    if "res://addons/" in saida:
        ruido += [
            "Cannot infer the type of",
            "Nonexistent function 'new' in base 'GDScript'",
        ]
    erros = [
        linha.strip() for linha in saida.splitlines()
        if ("Parse Error" in linha or "SCRIPT ERROR" in linha)
        and not any(r in linha for r in ruido)
    ]
    if not erros:
        return 0
    print("%s não compila:" % os.path.relpath(caminho, RAIZ), file=sys.stderr)
    for erro in erros[:6]:
        print("  " + erro, file=sys.stderr)
    return 2  # devolve os erros ao Claude no mesmo turno


if __name__ == "__main__":
    sys.exit(main())
