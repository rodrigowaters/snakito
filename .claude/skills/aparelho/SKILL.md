---
name: aparelho
description: Exporta o APK de debug, reconecta o adb wireless com retry, instala no moto g35 e abre o app para playtest.
disable-model-invocation: true
---

# Instalar no aparelho

Fecha o ciclo "código → mão do Rodrigo". Use quando ele pedir para testar
no celular, ou depois de fechar uma entrega que precisa de veredito.

## Como rodar

```bash
.claude/skills/aparelho/instalar.sh              # build + install + launch
.claude/skills/aparelho/instalar.sh --sem-build  # reaproveita build/snakito.apk
```

**Rode em background** (`run_in_background: true`): a transferência de
~115 MB por Wi-Fi leva de 1 a 3 minutos e estoura o timeout padrão.

## Antes de rodar

1. **Suíte verde primeiro** — `GODOT_BIN=/opt/homebrew/bin/godot sh addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests`.
   Nunca mandar build quebrado para o aparelho: o ciclo dele é caro.
2. Se o script sair com código 2, o aparelho está fora: pedir ao Rodrigo
   para religar **Depuração por Wi-Fi** e **deixar a tela acesa** — tela
   apagada derruba a conexão no meio do install (já aconteceu).

## Depois de instalar

Entregar um **roteiro de teste curto**, específico da mudança: o que
tocar, em que ordem, e o que deve acontecer. Ele responde com veredito
("aprovado" / "não ficou fiel" / o que sentiu) — esse é o loop.

Para mexer no progresso local **sem perder o login** (liberar desafios,
injetar moedas/tickets):

```bash
adb shell am force-stop com.rodrigowaters.snakito
adb shell run-as com.rodrigowaters.snakito cat files/progresso.cfg   # ler
adb push progresso.cfg /data/local/tmp/ && \
  adb shell 'run-as com.rodrigowaters.snakito sh -c "cp /data/local/tmp/progresso.cfg files/progresso.cfg"'
```

Nunca `pm clear` (apaga a sessão do Google) nem `monkey` (injeta evento
aleatório — já completou um onboarding sozinho).
