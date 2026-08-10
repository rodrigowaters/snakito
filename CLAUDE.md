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

## Domínio (implementado)

Core loop completo em `src/domain/` (5 de 7 arquivos; `strategy_analyzer.gd` e `challenge_rules.gd` são M1/M2): `rng_service`, `snake_model`, `arena_model`, `bot_engine`, `game_engine`. Testes em `tests/domain/` (45 casos). Interpretações onde a spec (docs §2) é omissa — decididas e documentadas nas constantes do código:

- **Limiar de devorar em inteiros** (`11·tamanho_menor ≤ 10·tamanho_maior`): comparar com `1.1 * tamanho` em float erra o limiar exato (1.1 não tem representação binária finita)
- **Knockback:** qualquer contato não-devorável separa as duas cobras, a menor deslocando mais (contém o "empurra até 5% menores" da spec)
- **Borda desliza, não mata** (público 7+; mudar = flag de config)
- **Curvas escolhidas:** abate = `100·√tamanho_vítima` clamp 100–500; crescimento por abate = metade do tamanho da vítima; sobrevivência = +1 ponto/s; velocidade constante (boost é opcional na spec, fora do MVP)
- **Determinismo é contrato:** ordem do array `cobras`, ordem de spawn (fazendeiros→caçadores→oportunistas) e decisões de bot escalonadas por `(tick + id) % 6` fazem parte da seed
- **Bots honestos:** visão limitada via `raio_visao()` em toda consulta; reação a cada 6 ticks (100ms)
- **Turbo & buffs (§2.6, aprovado):** turbo ×1.5 com energia (100 · consumo 40/s · regen 16/s · histerese em 10, com epsilon anti-resíduo-float); bots usam turbo nas mesmas regras (fuga/caça), nunca os buffs do jogador; buffs por nível com teto (`_aplicar_buffs`); **desafios criam config com `aplicar_buffs = false`**
- **Desafios 1–2 (`challenge_rules.gd`):** avaliador puro com trava (resolvido não des-resolve); seed fixa por desafio (101/202); prioridades documentadas (D1: matar derrota antes da meta; D2: meta no mesmo tick da morte vale); composição pedagógica é nossa (D1 sem caçadores)
- **Calibragem do D2 em 3 rodadas de playtest com o Rodrigo (08/08):** 4 eixos novos de composição, todos capacidade transparente (nunca trapaça) — `turbo_bots` (paridade de turbo torna caça 1v1 impossível; Arcade 1.4, D2 1.3), `tamanho_teto_bot` (contém a bola de neve de bots que se devoram — chegavam a 286; jogador NUNCA tem teto), `tamanho_teto_cacador` e `tamanho_inicial_cacador` (caçadores-ALFA nascem 11 e crescem até 30 — a ameaça escala com o jogador em vez de evaporar; é também o eixo que o Desafio 3 exige: "caçadores de tamanho 100+"). **Metodologia (`tools/simular_desafios.gd`):** lote de 12 trajetórias sintéticas com ruído angular ("imprecisão humana" — sem ruído o lote degenera na mesma partida, comida sempre visível zera o consumo de RNG do vagueio); calibragem final após 5 rodadas de playtest (impossível → estéril → caça ok → 'campo de batalha' → aberto): arena 2000², 15 bots, alfas nascem 10, turbo_bots 1.25; banda em 24 trajetórias: conclui 17/24, morre 7/24 (fuga sintética ingênua — teto pessimista), fuga 21%, ~2.3 bots na tela, conclusão média 46s

## Cenas (implementado)

Fluxo Home → Jogo → Resultado completo e verificado por screenshot (`tools/capturar_tela.gd`). Padrões estabelecidos:

- **Árvores construídas em código** consumindo só `SnakitoTokens` + variações do Theme; `.tscn` mínimos (root + script + anchors). Anchors do root Control **precisam** estar no `.tscn` — definir só em `_ready` não dimensiona o root
- `src/scenes/jogo/`: `jogo.gd` (dono do `GameEngine`, tick em `_physics_process`), `arena_render.gd` (um `_draw()` com culling; corpo da cobra é trilha **visual** — a colisão do domínio é por cabeça), `hud.gd` (barra + pausa), `joystick_virtual.gd` (flutuante, com fallback de teclado)
- `src/scenes/sessao.gd`: navegação via `static var` (sem autoload) — seed pedida + motor da última partida
- "Maior visão" do jogador = zoom da câmera (leitura de render do docs §2.2)
- Performance do domínio: **0.66ms/tick** com 30 bots neste Mac (`tools/bench_dominio.gd`); orçamento de frame é 16.6ms — o teste de 60fps no aparelho é sobre o render

## Conformidade (sempre)

Política de Famílias do Google Play; coleta mínima (username, e-mail, stats de partida); consentimento parental <13; exclusão de conta no app; build `.aab` com Play App Signing; `tagForChildDirectedTreatment` quando anúncios entrarem.

## Estado atual & roadmap

- [x] Documentação aprovada (`docs/snakito-instrucoes.md` v2.0) + emenda de Trilhas nas Instruções Globais
- [x] **Spike (go/no-go): APROVADO — GO.** `.aab` assinado com Billing+AdMob compilando (e vivos em runtime no aparelho); arena 30 bots a 115–119fps num moto g35; Sentry entregando evento com HTTP 200
- [x] MVP jogável (sem 1–2): domínio puro + 45 testes ✅; 3 bots ✅; Home/Jogo/Resultado ✅; skin padrão (verde) ✅; feedback visual §7 ✅ (pulso ao comer, confete no kill, pontos flutuando, flash+háptica na morte) — 100% offline, sem conta. Pendências: **sons** (sem assets de áudio ainda), minimap, modo daltonismo em jogo, balanceamento (jogador parado morre em ~3s — aprovado inicialmente pelo Rodrigo em 08/08), i18n das strings
- **Spike Android — 3 de 3 critérios APROVADOS: GO (08–10/08):**
  - ✅ **60fps em aparelho mediano**: moto g35 5G via adb — arena 30 bots a 115–119fps (pior frame de gameplay: 76); 1 hitch único de load (mascarável)
  - ✅ **`.aab` assinado com Billing+AdMob compilando juntos**: gradle build ok; dex contém `com/android/billingclient` e `com/poingstudios/godot/admob`; **11 singletons vivos em runtime** no aparelho (incl. `UserMessagingPlatform`/`ConsentInformation` — UMP p/ famílias); AAB assinado com debug keystore (upload key do Play fica p/ publicação)
  - ✅ **Sentry**: SDK oficial 2.1.1 em `addons/sentry` (com libs Android); DSN em `override.cfg` (gitignorado, entra no export via `include_filter`); evento de erro entregue com **HTTP 200** via SDK no desktop; botão "🐛 Crash de teste" na Home (só builds debug) envia evento + crash nativo proposital. Config: chaves `sentry/options/*` (dsn, environment, release, debug_printing, skip_auto_init_on_editor_play=false)
  - Infra local: templates 4.7.1 instalados, keystore debug gerado, editor_settings apontando SDK/Java; presets `Android AAB` + `Android APK (aparelho)`; plugins vendorados em `addons/` (Billing 3.3.0; AdMob poing v5 nightly + template nativo 4.7.1 — os AARs nativos em `addons/admob/android/bin` são gitignorados pelo próprio addon: re-baixar `android-template-v4.7.1.zip` em clone novo); `android/` (template gradle) é gerado, gitignorado
  - Export headless: `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home godot --headless --export-debug "Android AAB" export/snakito.aab` (Godot segfaulta AO SAIR depois de gravar o artefato — quirk macOS, inofensivo)
  - Pendências menores: ícone do projeto (warning no export; assets do ícone adaptativo existem só como SVG no design), `tagForChildDirectedTreatment` quando anúncios ativarem
- [ ] M1 (sem 3–4): auth (e-mail + Google), fila offline + `submit_session` + ranking, desafios 1–2 (**domínio ✅** — falta UI + análise pós-partida), onboarding sem texto, +3 skins
- [ ] M2 (sem 5–6): AdMob, Billing "Remover Anúncios", analyzer completo, desafios 3–4, EN/ES, publicação
- [x] Design system e telas em alta fidelidade geradas via Claude Design; tokens portados para `src/ui/theme/` (ver *Fundação visual*)

## Convenções de resposta

Responder em pt-BR; explicar decisões técnicas brevemente antes do código; entregar arquivos completos com caminho; comentários em pt-BR quando necessários; ao final de cada entrega, listar próximos passos e atualizar este arquivo com o status.
