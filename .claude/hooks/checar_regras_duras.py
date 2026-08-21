#!/usr/bin/env python3
"""Hook PostToolUse: guarda das regras duras do CLAUDE.md.

Invariantes que o olho não pega e nenhum teste cobre:
  #1  domínio (`src/domain/`) é RefCounted puro — nunca herda Node
  #4  valores visuais literais só existem em `tokens.gd`
  Trilha B  tipagem estática obrigatória (var sem tipo precisa de
            justificativa explícita em comentário na mesma linha)

Exceções registradas: `configuracoes.gd` desenha o G do Google com as 4
cores da MARCA (recolorir descaracterizaria logo de terceiro) e a regra
#4 fala de CENA — validadores e testes em `tools/`/`tests/` precisam
citar o literal para conferir o token.
"""
import json
import os
import re
import sys

RAIZ = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
ISENTOS_DE_COR = ("src/ui/theme/tokens.gd", "src/ui/configuracoes/configuracoes.gd")

COR_LITERAL = re.compile(r'Color\("#')
VAR_SEM_TIPO = re.compile(r'^\s*var\s+([a-z_][a-z0-9_]*)\s*=\s*(?!.*#)')


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
    relativo = os.path.relpath(caminho, RAIZ)
    try:
        texto = open(caminho, encoding="utf-8").read()
    except OSError:
        return 0

    achados: list[str] = []
    if relativo.startswith("src/domain/") and re.search(r"^extends\s+Node", texto, re.M):
        achados.append(
            "REGRA DURA #1: domínio é RefCounted puro — `extends Node` em %s "
            "acopla o domínio à cena." % relativo)
    checa_cor = relativo.startswith("src/") and not relativo.endswith(ISENTOS_DE_COR)
    if checa_cor and COR_LITERAL.search(texto):
        linhas = [str(i + 1) for i, l in enumerate(texto.splitlines()) if COR_LITERAL.search(l)]
        achados.append(
            "REGRA DURA #4: cor literal fora de tokens.gd (linha(s) %s) — "
            "use `SnakitoTokens.*` ou uma variação do Theme."
            % ", ".join(linhas[:5]))
    sem_tipo = [
        str(i + 1) for i, l in enumerate(texto.splitlines())
        if VAR_SEM_TIPO.match(l) and ":=" not in l
    ]
    if sem_tipo:
        achados.append(
            "TRILHA B: var sem tipo na(s) linha(s) %s — tipar ou justificar "
            "em comentário na mesma linha." % ", ".join(sem_tipo[:5]))

    if not achados:
        return 0
    for achado in achados:
        print(achado, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
