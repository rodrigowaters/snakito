#!/usr/bin/env bash
# Exporta o APK, reconecta o adb wireless e instala/abre no moto g35.
#   ./instalar.sh              → build + install + launch
#   ./instalar.sh --sem-build  → usa o build/snakito.apk que já existe
#
# O bailado de reconexão é lição de playtest: a depuração por Wi-Fi cai
# toda hora e a porta MUDA quando o Rodrigo religa — o mdns às vezes
# anuncia a porta velha (recusada) por vários ciclos antes da nova.
set -uo pipefail

RAIZ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../../.." && pwd)}"
APK="$RAIZ/build/snakito.apk"
PACOTE="com.rodrigowaters.snakito"
LAUNCHER="$PACOTE/com.godot.game.GodotAppLauncher"
JAVA_17="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

if [ "${1:-}" != "--sem-build" ]; then
  echo "→ exportando APK (Godot segfauta AO SAIR: inofensivo)"
  JAVA_HOME="$JAVA_17" godot --headless --path "$RAIZ" \
    --export-debug "Android APK (aparelho)" "$APK" 2>&1 | grep -iE "^ERROR" | head -3
fi
[ -f "$APK" ] || { echo "✗ APK não existe: $APK"; exit 1; }
echo "→ APK: $(du -h "$APK" | cut -f1)"

conectado() { adb devices | grep -q "device$"; }
echo "→ reconectando adb (a porta muda ao religar a depuração)"
# Endereço explícito: `./instalar.sh --sem-build --endereco 192.168.68.100:45881`
# Serve quando o mdns anuncia porta velha (já aconteceu) — a porta de
# CONEXÃO aparece em Depuração por Wi-Fi; se pedir pareamento, é outra
# porta + código: `adb pair IP:PORTA_PAREAMENTO CODIGO`.
for arg in "$@"; do
  case "$arg" in
    --endereco=*) adb connect "${arg#*=}" 2>&1 | grep -v refused || true ;;
  esac
done
if [ "${1:-}" = "--endereco" ] && [ -n "${2:-}" ]; then
  adb connect "$2" 2>&1 | grep -v refused || true
fi
for tentativa in 1 2 3 4; do
  conectado && break
  adb kill-server >/dev/null 2>&1; sleep 2
  adb start-server >/dev/null 2>&1; sleep 8
  conectado && break
  for porta in $(adb mdns services 2>/dev/null | grep tls-connect | awk '{print $NF}' | sort -u); do
    adb connect "$porta" 2>&1 | grep -v "refused" || true
  done
  sleep 2
  echo "   tentativa $tentativa: $(adb devices | grep -c 'device$') aparelho(s)"
done
conectado || { echo "✗ aparelho fora. Pedir ao Rodrigo: religar Depuração por Wi-Fi + TELA ACESA"; exit 2; }

# O mesmo aparelho costuma aparecer em DOIS transportes (entrada IP:porta
# + entrada mdns) e o adb fica ambíguo ("more than one device"): fixar o
# serial resolve — é o mesmo celular nas duas linhas.
SERIAL="$(adb devices | awk '/device$/ {print $1; exit}')"
echo "→ serial: $SERIAL"

echo "→ instalando (115MB por Wi-Fi: 1–3 min; tela apagada DERRUBA a conexão)"
adb -s "$SERIAL" install -r "$APK" 2>&1 | tail -1
echo "→ abrindo (am start, NUNCA monkey: injeta evento aleatório)"
adb -s "$SERIAL" shell am start -n "$LAUNCHER" 2>&1 | tail -1
