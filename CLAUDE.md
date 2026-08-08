# CLAUDE.md — Snakito

> Contexto automático para sessões de Claude Code neste repositório.
> Fonte de verdade: `docs/snakito-instrucoes.md` (+ Instruções Globais da linha, com emenda de Trilhas). Feature sem seção na documentação → documentar primeiro.

## O que é este projeto

**Snakito** — jogo educacional Android (Google Play, política de Famílias, público 7+): snake-arena **single-player contra bots**, 100% jogável offline, com conta obrigatória e ranking global **assíncrono** (sem multiplayer, sem Realtime). Ensina estratégia em tempo real, gestão de risco/recompensa e reação rápida. Faz parte de uma linha de apps educacionais (irmão: Blokito, trilha Expo/TS).

**Repositório:** `https://github.com/rodrigowaters/snakito`

## Trilha de tecnologia (decisão fechada — não reabrir)

Este app é da **Trilha B** da linha: **Godot 4 (atual: 4.8) + GDScript com tipagem estática obrigatória**. Nunca variáveis sem tipo sem justificativa explícita em comentário. React Native/Expo foi descartado para jogos de tempo real após problemas de performance no Blokito.

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
| `src/ui/theme/snakito_theme.tres` | `Theme` do Godot: 6 tipos base + 25 variações, 30 StyleBoxes |

**Regra operacional:** valores visuais literais só existem nesses **dois** arquivos de `src/ui/theme/`. Cenas consomem `SnakitoTokens.*` ou variações do `Theme` (`BotaoPrimario`, `TituloLg`, `CardPainel`, …). O `.tres` é derivado do `tokens.gd` — ao mudar um token, o `.tres` precisa ser regerado junto.

**Contraste:** 0 reprovações. Única restrição de uso: `COR_TEXTO_MUTED` (#7E88A8) só em texto grande — ≥19px negrito ou ≥24px normal.

**Pendências da fundação** (bloqueiam fidelidade visual, não bloqueiam código):
- Fontes Fredoka e Nunito (`.ttf`) ausentes; o `Theme` não referencia fontes ainda
- Símbolos do modo daltonismo definidos no design (8 formas, 1 por cor) mas **sem assets exportados** — só existem como SVG inline no doc
- Gradientes de CTA aproximados por cor sólida (`StyleBoxFlat` não faz gradiente)
- Falta `tools/gerar_tema.gd` (EditorScript) para regerar o `.tres` a partir do `tokens.gd`
- Falta teste gdUnit4 de regressão de contraste usando `SnakitoTokens.razao_contraste()`

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
