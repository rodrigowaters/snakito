#!/usr/bin/env python3
"""Hook PostToolUse: compila o .gd editado e devolve os erros de parse.

Custa ~0.9s por arquivo. Existe porque a família de armadilhas de GDScript
registrada no CLAUDE.md (expressão não-constante, assinatura de plugin
errada, tipo incompatível) só aparecia no `--import` seguinte, um ciclo
depois — e às vezes só no aparelho.
"""
import json
import os
import subprocess
import sys

RAIZ = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
GODOT = os.environ.get("GODOT_BIN", "godot")


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
    erros = [
        linha.strip() for linha in saida.splitlines()
        if "Parse Error" in linha or "SCRIPT ERROR" in linha
    ]
    if not erros:
        return 0
    print("%s não compila:" % os.path.relpath(caminho, RAIZ), file=sys.stderr)
    for erro in erros[:6]:
        print("  " + erro, file=sys.stderr)
    return 2  # devolve os erros ao Claude no mesmo turno


if __name__ == "__main__":
    sys.exit(main())
