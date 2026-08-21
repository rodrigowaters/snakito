---
name: tela
description: Compara uma tela implementada com o blueprint do Claude Design lado a lado (screenshot × desenho) e lista as divergências.
disable-model-invocation: true
---

# Fidelidade ao Claude Design

O ciclo que fechou o M2 e o M3: extrair o blueprint → capturar a tela →
comparar → listar divergências → corrigir → recapturar. Use quando for
construir ou revisar qualquer tela do desenho.

## Passos

**1. Extrair o blueprint** (fonte de verdade: `docs/design/Snakito Telas.dc.html`)

```bash
.claude/skills/tela/extrair_blueprint.py            # lista as 26 telas
.claude/skills/tela/extrair_blueprint.py "09b"      # grava em /tmp e resume
```

Ler o HTML gravado: dele saem as medidas reais (raios, paddings, pesos,
tamanhos de fonte) e os textos exatos.

**2. Capturar a tela implementada** — precisa de janela; headless não renderiza.

```bash
godot --headless --path . --import      # só quando houver class_name novo
godot --path . -s tools/capturar_tela.gd -- res://src/ui/loja/loja.tscn /tmp/loja.png 40
```

Para telas com estado interno (aba, raridade, modal), escrever um script
de captura temporário no scratchpad que define o estado antes do frame —
padrão usado nas 3 abas da Loja.

**3. Comparar e reportar.** Ler o PNG e conferir contra o blueprint:
composição e ordem dos blocos · hierarquia de tamanhos · cores por papel ·
raios e respiros · **textos idênticos** · estados (ativo/desabilitado).

Entregar as divergências como lista curta, cada uma com o que o desenho
pede e o que a tela mostra. Recapturar depois de corrigir.

## Regras que não se negociam

- Valores visuais literais só existem em `tokens.gd` + `snakito_theme.tres`
  (regra dura #4). Se o blueprint pede algo que não há no token, o token
  é que ganha uma constante nova — nunca a cena.
- Divergência **deliberada** (feature ainda não existe, decisão do
  Rodrigo) entra como comentário no topo do script da cena, na seção
  "Adaptações registradas". Não silenciar diferença.
- Armadilhas que já mordeream, todas em `_draw`: emoji com seletor
  U+FE0F vira glifo monocromático; glifo `←` tem métrica torta; botão
  `disabled` troca o stylebox; anchors do root Control precisam estar no
  `.tscn`; largura MÍNIMA de rótulo+chips estoura o card e come o respiro
  lateral (usar `autowrap_mode`).
