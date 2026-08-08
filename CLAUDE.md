# CLAUDE.md — Snakito

> Contexto automático para sessões de Claude Code neste repositório.
> Fonte de verdade: `docs/snakito-instrucoes.md` (+ Instruções Globais da linha, com emenda de Trilhas). Feature sem seção na documentação → documentar primeiro.

## O que é este projeto

**Snakito** — jogo educacional Android (Google Play, política de Famílias, público 7+): snake-arena **single-player contra bots**, 100% jogável offline, com conta obrigatória e ranking global **assíncrono** (sem multiplayer, sem Realtime). Ensina estratégia em tempo real, gestão de risco/recompensa e reação rápida. Faz parte de uma linha de apps educacionais (irmão: Blokito, trilha Expo/TS).

**Repositório:** `https://github.com/rodrigowaters/snakito`

## Trilha de tecnologia (decisão fechada — não reabrir)

Este app é da **Trilha B** da linha: **Godot 4 (estável atual: 4.7.1; a doc citava "4.8", que não existe) + GDScript com tipagem estática obrigatória**. Nunca variáveis sem tipo sem justificativa explícita em comentário. React Native/Expo foi descartado para jogos de tempo real após problemas de performance no Blokito.

## Stack

| Camada | Ferramenta |
|---|---|
| Engine | Godot 4.8, GDScript tipado |
| Testes | gdUnit4 (`tests/`) |
| Backend | Supabase via REST (`HTTPRequest`) + Edge Function `submit_session` |
| Compras | Plugin oficial godot-google-play-billing (godot-sdk-integrations) |
| Anúncios | Plugin AdMob com COPPA/TFUA + UMP (Fase 2+; entitlement check desde o dia 1) |
| Crashes | Sentry (SDK oficial para Godot) |
| Analytics | Firebase Analytics via plugin comunitário (modo restrito p/ famílias) |
| i18n | Sistema nativo do Godot (CSV/PO), pt-BR padrão; nada hardcoded |

## Arquitetura (regras duras)

1. **Domínio puro em `src/domain/`:** classes `RefCounted` GDScript, **nunca** herdam `Node`, zero dependência de cena/render/input. Arquivos: `game_engine.gd`, `snake_model.gd`, `arena_model.gd`, `bot_engine.gd`, `strategy_analyzer.gd`, `challenge_rules.gd`, `rng_service.gd`. Cenas apenas renderizam o estado calculado pelo domínio.
2. **Determinismo:** todo RNG passa pelo `rng_service.gd` seedável. Mesma seed = mesma partida (desafios reproduzíveis, botão "Repetir esta arena").
3. **Bots honestos:** 3 personalidades (Fazendeiro, Caçador, Oportunista); dificuldade = composição da arena, nunca trapaça (sem visão através da névoa, sem reação sobre-humana).
4. **Design tokens centralizados:** um único `Theme` resource + script de constantes. Nenhuma cor/fonte/espaçamento hardcoded em cena. Contraste WCAG AA; modo daltonismo com símbolo geométrico por cor de cobra.
5. **Offline-first:** gameplay sem nenhuma chamada de rede. Sessões terminadas entram em fila local (`ConfigFile`/`FileAccess`) e sobem via Edge Function `submit_session` quando houver conexão. Insert direto em `game_sessions`/`leaderboard` é bloqueado por RLS.
6. **Entitlements por conta** (`ads_removed`, skins) no Supabase; todo componente de anúncio consulta o entitlement antes de renderizar, desde já.
7. **Skins nunca dão vantagem de gameplay.**
8. Testes gdUnit4 obrigatórios para todo o domínio (crescimento, morte, pontuação, desafios, determinismo, comportamento de cada bot).

## Fundação visual (implementada)

Design system importado do Claude Design (projeto `Design System Snakito`, v1.0, mood *Cosmic Soft*, Android portrait 412×915).

| Caminho | Papel |
|---|---|
| `docs/design/` | Fonte de verdade visual, versionada — export bruto do Claude Design |
| `docs/design/snakito-tokens.json` | Tokens originais (inclui economia/IAP, ainda não portados) |
| `docs/design/wcag-report.md` | Relatório de contraste WCAG 2.1 AA |
| `src/ui/theme/tokens.gd` | `SnakitoTokens` — constantes tipadas (cores, tipografia, espaçamento, raios, toque, daltonismo) |
| `src/ui/theme/snakito_theme.tres` | `Theme`: 6 tipos base + 25 variações, fontes ligadas via `FontVariation` |
| `tools/tema_builder.gd` | Construção do `Theme` (RefCounted estático — roda headless; `EditorScript` não instancia fora do editor) |
| `tools/gerar_tema.gd` | Casca EditorScript sobre o builder (Arquivo > Executar no editor) |
| `tools/validar_fundacao.gd` | Smoke test headless: tokens + tema + round-trip de regeneração. `godot --headless --quit-after 30 -s tools/validar_fundacao.gd` |
| `assets/fonts/` | Fredoka + Nunito variáveis (OFL, licenças incluídas) |
| `assets/daltonismo/` | 8 símbolos SVG do modo daltonismo (1 por cor de cobra) |
| `tests/ui/theme/test_tokens_contraste.gd` | Regressão WCAG dos tokens (gdUnit4 — addon vendorado em `addons/gdUnit4`) |
| `project.godot` | Projeto mínimo (nome, portrait 412×915, renderer mobile, tema global, plugin gdUnit4); presets Android entram no spike |

**Regra operacional:** valores visuais literais só existem em `tokens.gd` + `snakito_theme.tres`. Cenas consomem `SnakitoTokens.*` ou variações do `Theme` (`BotaoPrimario`, `TituloLg`, `CardPainel`, …). Ao mudar um token: regenerar o `.tres` (editor: `gerar_tema.gd`; terminal: `validar_fundacao.gd` já regenera e valida) e rodar os testes.

**Validado na engine (Godot 4.7.1, brew cask):** importação de assets, carga do tema, regeneração round-trip e suite gdUnit4 — 9/9 testes, 0 falhas. Rodar testes no terminal: `GODOT_BIN=/opt/homebrew/bin/godot sh addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests`.

**Contraste:** 0 reprovações. Única restrição de uso: `COR_TEXTO_MUTED` (#7E88A8) só em texto grande — ≥19px negrito ou ≥24px normal.

**Armadilhas de GDScript já encontradas** (a engine reprova, o olho não): construtores `Packed*Array(...)` e referências diretas a classe (`const T := SnakitoTokens`) não são expressão constante — use `Array[int]` e `preload(...)`; `EditorScript` só instancia no editor — lógica reutilizável vai para RefCounted.

**Pendência estética (não bloqueia):** gradientes de CTA aproximados pelo tom médio (`StyleBoxFlat` não desenha gradiente; `StyleBoxTexture`/shader quando o polimento importar). Estados `hover` = `normal` de propósito: alvo é Android.

## Conformidade (sempre)

Política de Famílias do Google Play; coleta mínima (username, e-mail, stats de partida); consentimento parental <13; exclusão de conta no app; build `.aab` com Play App Signing; `tagForChildDirectedTreatment` quando anúncios entrarem.

## Estado atual & roadmap

- [x] Documentação aprovada (`docs/snakito-instrucoes.md` v2.0) + emenda de Trilhas nas Instruções Globais
- [ ] **Spike (go/no-go, 2–3 dias):** export `.aab` assinado com plugins Billing+AdMob compilando; mini-arena com 30 bots + joystick a 60fps em aparelho mediano; Sentry reportando crash de teste
- [ ] MVP (sem 1–2): domínio puro + testes, 3 bots, Home/Jogo/Resultado, 1 skin — 100% offline, sem conta
- [ ] M1 (sem 3–4): auth (e-mail + Google), fila offline + `submit_session` + ranking, desafios 1–2, onboarding sem texto, +3 skins
- [ ] M2 (sem 5–6): AdMob, Billing "Remover Anúncios", analyzer completo, desafios 3–4, EN/ES, publicação
- [x] Design system e telas em alta fidelidade geradas via Claude Design; tokens portados para `src/ui/theme/` (ver *Fundação visual*)

## Convenções de resposta

Responder em pt-BR; explicar decisões técnicas brevemente antes do código; entregar arquivos completos com caminho; comentários em pt-BR quando necessários; ao final de cada entrega, listar próximos passos e atualizar este arquivo com o status.
