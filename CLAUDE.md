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

**Armadilhas de GDScript já encontradas** (a engine reprova, o olho não): construtores `Packed*Array(...)` e referências diretas a classe (`const T := SnakitoTokens`) não são expressão constante — use `Array[int]` e `preload(...)`; `EditorScript` só instancia no editor — lógica reutilizável vai para RefCounted. `FontVariation.variation_opentype` com chave String (`{"wght": 600}`) NÃO aplica o eixo da fonte variável — falha silenciosa (o app inteiro pesou 400 até o M2); use o tag numérico `TextServerManager.get_primary_interface().name_to_tag("weight")` (o validador da fundação agora pega regressão). Emoji com seletor U+FE0F (⬆️) pode renderizar como glifo monocromático — ícone crítico de design se desenha em `_draw`. Botão `disabled` troca o stylebox para o "desabilitado" do tema (raio/fundo diferentes) — placeholder "presente mas desligado" fiel ao design precisa de `add_theme_stylebox_override("disabled", tema.get_stylebox("normal", variação))` + `font_disabled_color` (mordeu 3× no M2). Glifos de símbolo (←) têm métrica torta — setas/ícones críticos se desenham em `_draw`. **Armadilhas de aparelho** (só aparecem com stretch de tela real): culling/visível em `_draw` usa `get_canvas_transform()` (mundo→design), NUNCA `get_viewport_transform()` (inclui o stretch — encolheu o mundo a 1/4 no moto g35); o boot splash cinza padrão do Godot parece tela morta em screenshot — está na cor da marca agora. Bug que só existe no celular exige screenshot do celular. **Input touch**: `InputEventScreenTouch/Drag` pode nunca chegar ao `_gui_input` de um Control no aparelho (a rota depende da emulação toque→mouse) — controles full-screen de gameplay precisam de `_unhandled_input` como rede de segurança (joystick ficou surdo 1 dia inteiro; Buttons funcionavam e mascaravam).

**Pendência estética (não bloqueia):** gradientes de CTA aproximados pelo tom médio (`StyleBoxFlat` não desenha gradiente; `StyleBoxTexture`/shader quando o polimento importar). Estados `hover` = `normal` de propósito: alvo é Android.

## Domínio (implementado)

Domínio COMPLETO em `src/domain/` — os 7 arquivos da arquitetura: `rng_service`, `snake_model`, `arena_model`, `bot_engine`, `game_engine`, `challenge_rules`, `strategy_analyzer` (análise v1: heurísticas tipadas sobre energia na morte, morte precoce, tamanho ao caçar, ritmo de coleta — máx. 2 achados por prioridade de enum; a UI traduz). Testes em `tests/domain/`. Interpretações onde a spec (docs §2) é omissa — decididas e documentadas nas constantes do código:

- **Limiar de devorar em inteiros** (`11·tamanho_menor ≤ 10·tamanho_maior`): comparar com `1.1 * tamanho` em float erra o limiar exato (1.1 não tem representação binária finita)
- **Knockback:** qualquer contato não-devorável separa as duas cobras, a menor deslocando mais (contém o "empurra até 5% menores" da spec)
- **Borda desliza, não mata** (público 7+; mudar = flag de config)
- **Curvas escolhidas:** abate = `100·√tamanho_vítima` clamp 100–500; crescimento por abate = metade do tamanho da vítima; sobrevivência = +1 ponto/s; velocidade constante (boost é opcional na spec, fora do MVP)
- **Determinismo é contrato:** ordem do array `cobras`, ordem de spawn (fazendeiros→caçadores→oportunistas) e decisões de bot escalonadas por `(tick + id) % 6` fazem parte da seed
- **Bots honestos:** visão limitada via `raio_visao()` em toda consulta; reação a cada 6 ticks (100ms)
- **Turbo & buffs (§2.6, aprovado):** turbo ×1.5 com energia (100 · consumo 40/s · regen 16/s · histerese em 10, com epsilon anti-resíduo-float); bots usam turbo nas mesmas regras (fuga/caça), nunca os buffs do jogador; buffs por nível com teto (`_aplicar_buffs`); **desafios criam config com `aplicar_buffs = false`**
- **Desafios 1–2 (`challenge_rules.gd`):** avaliador puro com trava (resolvido não des-resolve); seed fixa por desafio (101/202); prioridades documentadas (D1: matar derrota antes da meta; D2: meta no mesmo tick da morte vale); composição pedagógica é nossa (D1 sem caçadores)
- **Calibragem do D2 em 3 rodadas de playtest com o Rodrigo (08/08):** 4 eixos novos de composição, todos capacidade transparente (nunca trapaça) — `turbo_bots` (paridade de turbo torna caça 1v1 impossível; Arcade 1.4, D2 1.3), `tamanho_teto_bot` (contém a bola de neve de bots que se devoram — chegavam a 286; jogador NUNCA tem teto), `tamanho_teto_cacador` e `tamanho_inicial_cacador` (caçadores-ALFA nascem 11 e crescem até 30 — a ameaça escala com o jogador em vez de evaporar; é também o eixo que o Desafio 3 exige: "caçadores de tamanho 100+"). **Metodologia (`tools/simular_desafios.gd`):** lote de 12 trajetórias sintéticas com ruído angular ("imprecisão humana" — sem ruído o lote degenera na mesma partida, comida sempre visível zera o consumo de RNG do vagueio); calibragem final após 5 rodadas de playtest (impossível → estéril → caça ok → 'campo de batalha' → aberto): arena 2000², 15 bots, alfas nascem 10, turbo_bots 1.25; banda em 24 trajetórias: conclui 17/24, morre 7/24 (fuga sintética ingênua — teto pessimista), fuga 21%, ~2.3 bots na tela, conclusão média 46s

## Corte de corpo & velocidade por tamanho (docs §2.7 e §2.2 — pós-M1, 11/08)

Aprovado pelo Rodrigo após playtest do M1 ("comer o rabo", "comi cresci fiquei mais rápido"):

- **Corpo virou estado do DOMÍNIO** (`SnakeModel.corpo`, trilha aparada em `12·(3+tamanho)` unidades) — o render desenha o corpo do domínio, não uma trilha própria. Colisão de corte: cabeça × pontos do corpo (com zona de pescoço e "espessura" 0.7·raio da vítima).
- **Regras do corte**: **corte livre APROVADO em playtest (11/08)** — QUALQUER cobra corta qualquer corpo, sem regra de tamanho (contra-golpe do pequeno; versão original era 11/10); vítima encolhe à fração do ponto do corte; trecho perdido vira comida equivalente (1/unidade — preserva a invariante de plausibilidade `nível ≤ 1+comidas+abates·teto`); **sem pontos**; kill/morte continuam SÓ pela cabeça; proteção de 1s pós-corte (senão a cabeça retalha em série); corpo de morta desaparece. Oportunista colhe rabo de qualquer cobra à vista (honesto por construção: fuga tem prioridade, só colhe rabo de cabeça fora da visão).
- **Duas réguas (11/08, decisão do Rodrigo)**: `nivel` (sobe com comida/abate, NUNCA desce — dele derivam **visão, velocidade, raio da cabeça e o direito de devorar**; HUD e `size_reached` mostram nível) × `tamanho` (massa: comprimento do corpo; é o que o corte leva e a comida repõe). Abate: pontos pelo NÍVEL da vítima, crescimento pela MASSA restante. Teto de bot aplica às duas réguas. Simulador: D2 18/24, morre 6/24; Arcade morre 5/24, vida 148s; score médio subiu p/ ~7k (abate paga pelo nível — inflação cosmética, ranking é relativo); bench 1.64ms/tick.
- **Velocidade por tamanho**: `1 + 0.06·(√nível−1)` clamp 1.35 (recalibrada 11/08: 0.03/1.25 era imperceptível), TODAS as cobras (tamanho 1 = exatamente 1.0 — testes de movimento não mudam). Compõe com turbo e buff.
- **Bots cortam**: caçador/oportunista miram o ponto mais próximo da presa (corpo ou cabeça, amostrado a cada 4 pontos).
- **Consequência de meta**: "maior = mais rápido" quebrou a premissa de paridade da calibragem — D2 trivializou (24/24, 0 mortes) e foi recalibrado: alfas nascem 14, teto 40, turbo 1.4 → banda 20/24, morre 4/24, fuga 17%, 44s. Arcade seguiu na banda (morre 8/24, vida 129s) mas o churn de cortes derruba comida em linha e o piloto sintético chega a tamanho ~290 — **fim de jogo fácil continua em aberto** (alavanca sugerida: alfas escalando com o líder; aguarda veredito de playtest).
- `submit_session` v2: `CRESCIMENTO_POR_ABATE_MAX` 15→60 (bug latente: devorar alfa 35 do Arcade dava falso 422; D3 com caçadores 100+ estouraria).
- Bench: 1.34ms/tick (era 0.66) — corpo+corte dobraram o domínio, folga grande no frame de 16.6ms.

## Cenas (implementado)

Fluxo Home → Jogo → Resultado completo e verificado por screenshot (`tools/capturar_tela.gd`). Padrões estabelecidos:

- **Árvores construídas em código** consumindo só `SnakitoTokens` + variações do Theme; `.tscn` mínimos (root + script + anchors). Anchors do root Control **precisam** estar no `.tscn` — definir só em `_ready` não dimensiona o root
- `src/scenes/jogo/`: `jogo.gd` (dono do `GameEngine`, tick em `_physics_process`), `arena_render.gd` (um `_draw()` com culling; corpo da cobra é trilha **visual** — a colisão do domínio é por cabeça), `hud.gd` (barra + pausa), `joystick_virtual.gd` (flutuante, com fallback de teclado)
- `src/scenes/sessao.gd`: navegação via `static var` (sem autoload) — seed pedida + motor da última partida
- "Maior visão" do jogador = zoom da câmera (leitura de render do docs §2.2)
- Performance do domínio: **0.66ms/tick** com 30 bots neste Mac (`tools/bench_dominio.gd`); orçamento de frame é 16.6ms — o teste de 60fps no aparelho é sobre o render

## Pendência: fidelidade às telas do Claude Design (decisão de 10/08)

As telas atuais usam os tokens/componentes fielmente (regra dura #4), mas **não seguem as composições hi-fi** de `docs/design/Snakito Telas.dc.html` (26 telas com decisões registradas: "Home 1d+1e · HUD 1h · pós 8c ..."). O Rodrigo decidiu registrar como pendência e priorizar o backend-cliente. Ao pagar a dívida, usar o HTML das telas como blueprint e entregar lado-a-lado (screenshot × design) para validação:

- **Refazer composição** (feature já existe): Home (sem moedas/fase por ora — preview da skin equipada, "▶ Jogar Arcade", nav em grade), HUD ("1h"), Pausa ("04c"), Pós-partida ("8c"), Desafios ("07")
- **Construir quando a feature chegar**: Mapa/fases (02), Evolução (03), Loja (09*), Configurações (10), Chefe/Duelo/Prorrogação (12*), Recompensa diária (01b), Ranking da fase (06). **Já construídas**: Renascimento (04b), Ranking (08), Fase concluída (12c → celebração de desafio/arena dominada), Info do jogador (02b — avatar da Home abre; SEM porta p/ Conta até Configurações). Onboarding (11a-d) removido por decisão.

## Backend Supabase (provisionado)

Projeto **snakito** · ref `cfpsounmrhoodijmrths` · região **sa-east-1 (São Paulo)** · org "aplicativos" · $0/mês. Fonte versionada em `supabase/` (migrations + functions); mudanças de schema SEMPRE via migration nova (nunca editar as antigas) e rodar `get_advisors` depois de DDL — advisors zerados em 10/08.

- URL: `https://cfpsounmrhoodijmrths.supabase.co` · chave publishable (pública por design): `sb_publishable_6F6vxEdvykR96c6fqE2ZMQ_EpQM16Yz`
- Tabelas (docs §6): `profiles` (sem e-mail — coleta mínima: e-mail só em `auth.users`, desvio documentado na migration), `game_sessions` (com níveis de buff p/ plausibilidade §2.6.3), `leaderboard` (semana ISO, trigger de upsert com `best_score`/`total_kills`/`games`), `entitlements`
- RLS: dono lê o que é seu; leaderboard leitura autenticada; **zero policies de escrita** em sessions/leaderboard/entitlements — só service role escreve
- Edge Function `submit_session` (verify_jwt): valida plausibilidade contra os limites do motor — teto de score (comida×10 + abates×500 + duração + buff), abates/comidas por segundo, tamanho máximo por abate, **buff em desafio = rejeição**, relógio (futuro >5min / passado >30d). 422 devolve o motivo. Limites espelham `game_engine.gd` — manter em sincronia
- **Cliente implementado (10/08):** autoload `Rede` (`src/net/rede.gd` — auth Google via `grant_type=id_token`, renovação automática em 401, tokens criptografados com chave do aparelho, perfil, ranking, envio de sessão) + `FilaSessoes` (`src/net/fila_sessoes.gd` — fila criptografada em `user://`, teto de 200, 5 testes); `jogo.gd` enfileira TODA partida encerrada (logado ou não) e o despacho descarta 422 (implausível nunca vai passar) e para em falha de rede/login. Telas: Conta (3 estados: Google → apelido → logado c/ pendências da fila) e Ranking (estado deslogado elegante + lista com destaque "você"). Verificado: morte forçada em partida real → fila 1 com payload correto
- **Login Google verificado no aparelho (10/08):** OAuth clients criados pelo Rodrigo, plugin Kotlin próprio (`plugin/google_signin/`, Credential Manager), perfil criado e 18 sessões despachadas da fila
- **Consentimento parental <13 (10/08):** migration `0004` adiciona `profiles.parental_consent_at` (minimização: idade NÃO é coletada — só o carimbo quando o responsável autoriza; nulo = declarou 13+). Fluxo na Conta: porta de idade → card "para o responsável" → apelido; "Agora não" desloga
- **Apelido é ÚNICO por decisão (13/08):** a identidade técnica é a conta Google, mas o apelido é a única identidade VISÍVEL (ranking público, coleta mínima) — unicidade dá distinguibilidade e barra imitação (público 7+). Custo aceito: atrito do "já está em uso"; se o funil mostrar 409 repetidos, o meio-termo é sufixo automático ("Pedro#482"). Edição de apelido no app (02b) via migração 0006 (UPDATE só na coluna username, própria linha)
- **Exclusão de conta no app (10/08):** Edge Function `delete_account` (verify_jwt) — `auth.admin.deleteUser` + cascade das FKs varre perfil/sessões/leaderboard. Na Conta: "Excluir conta…" com confirmação dupla

## Conformidade (sempre)

Política de Famílias do Google Play; coleta mínima (username, e-mail, stats de partida); consentimento parental <13; exclusão de conta no app; build `.aab` com Play App Signing; `tagForChildDirectedTreatment` quando anúncios entrarem.

## Estado atual & roadmap

- [x] Documentação aprovada (`docs/snakito-instrucoes.md` v2.0) + emenda de Trilhas nas Instruções Globais
- [x] **Spike (go/no-go): APROVADO — GO.** `.aab` assinado com Billing+AdMob compilando (e vivos em runtime no aparelho); arena 30 bots a 115–119fps num moto g35; Sentry entregando evento com HTTP 200
- [x] MVP jogável (sem 1–2): domínio puro + 45 testes ✅; 3 bots ✅; Home/Jogo/Resultado ✅; skin padrão (verde) ✅; feedback visual §7 ✅ (pulso ao comer, confete no kill, pontos flutuando, flash+háptica na morte) — 100% offline, sem conta. Pendências: **sons** (sem assets de áudio ainda), minimap, modo daltonismo em jogo, balanceamento (jogador parado morre em ~3s — aprovado inicialmente pelo Rodrigo em 08/08), i18n das strings
- **Spike Android — 3 de 3 critérios APROVADOS: GO (08–10/08):**
  - ✅ **60fps em aparelho mediano**: moto g35 5G via adb — arena 30 bots a 115–119fps (pior frame de gameplay: 76); 1 hitch único de load (mascarável)
  - ✅ **`.aab` assinado com Billing+AdMob compilando juntos**: gradle build ok; dex contém `com/android/billingclient` e `com/poingstudios/godot/admob`; **11 singletons vivos em runtime** no aparelho (incl. `UserMessagingPlatform`/`ConsentInformation` — UMP p/ famílias); AAB assinado com debug keystore (upload key do Play fica p/ publicação)
  - ✅ **Sentry**: SDK oficial 2.1.1 em `addons/sentry` (com libs Android); DSN em `override.cfg` (gitignorado, entra no export via `include_filter`); evento de erro entregue com **HTTP 200** via SDK no desktop **e no aparelho** (moto g35: "Envelope sent successfully"); crash nativo proposital capturado em tempo real (backtrace de 32 frames via sentry-native) e sessão `crashed: true` enviada no boot seguinte. Botão "🐛 Crash de teste" na Home (só builds debug). Config: chaves `sentry/options/*` (dsn, environment, release, debug_printing, skip_auto_init_on_editor_play=false)
  - Infra local: templates 4.7.1 instalados, keystore debug gerado, editor_settings apontando SDK/Java; presets `Android AAB` + `Android APK (aparelho)`; plugins vendorados em `addons/` (Billing 3.3.0; AdMob poing v5 nightly + template nativo 4.7.1 — os AARs nativos em `addons/admob/android/bin` são gitignorados pelo próprio addon: re-baixar `android-template-v4.7.1.zip` em clone novo); `android/` (template gradle) é gerado, gitignorado
  - Export headless: `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home godot --headless --export-debug "Android AAB" export/snakito.aab` (Godot segfaulta AO SAIR depois de gravar o artefato — quirk macOS, inofensivo)
  - Pendências menores: ícone do projeto (warning no export; assets do ícone adaptativo existem só como SVG no design), `tagForChildDirectedTreatment` quando anúncios ativarem
- [x] M1 (sem 3–4) — **FECHADO em 10/08**: desafios 1–2 ✅; análise pós-partida v1 ✅; auth Google (única forma de login) ✅; fila offline + `submit_session` + ranking ✅; consentimento parental <13 ✅; exclusão de conta no app ✅; **onboarding sem texto ✅** (`src/scenes/onboarding/` — 3 vinhetas com o motor real em piloto automático: comer → devorar menor → ser devorado suave; 4º passo escolhe a dificuldade OLHANDO dois cards desenhados; sempre pulável; gate na Home via `ProgressoLocal.onboarding_visto()`); **+3 skins ✅** (`src/ui/skins/` — verde/azul/rosa/amarela, grátis, só cor; turquesa descartada por confundir com o verde; `ArenaRender` dá a cor da skin ao jogador e os bots pulam esse índice; escolha do onboarding vira composição do Arcade em `Sessao.config_para_jogar()` — "tranquila": 3 caçadores, ag 0.35, turbo_bots 1.3; nunca toca desafios). Minimapa ✅. Pendências que ficaram para M2: sons, modo daltonismo em jogo, i18n
- [x] **M2 — Fidelidade ao Claude Design** — **FECHADO em 13/08**: refazer Home (1d+1e), HUD (1h), Pausa (04c), Pós-partida (8c), Desafios (07), Ranking (08) pelos blueprints de `docs/design/Snakito Telas.dc.html`; entrega lado-a-lado (screenshot × design) por tela. **Onboarding REMOVIDO em 13/08 por decisão do Rodrigo** (era do M1/docs §8; cenas excluídas, gate retirado da Home; dificuldade do Arcade migra para Configurações no M3 — padrão CHEIA até lá)
- [~] M3 (antigo M2) — em andamento: **Configurações (10) ✅ (13/08)** — layout fixo sem scroll (2 rodadas: gesto briga com botões de linha na rota touch→mouse; scroll volta na Loja com validação em aparelho); funcionais: Vibração, **modo daltonismo ✅** (símbolos geométricos por cor, cabeça + a cada 3 segmentos — spec dos tokens), **Sons/Música = TOGGLES liga/desliga** (decisão 13/08 — o desenho tinha sliders, mas liga/desliga é mais simples p/ 7+; persistem em `ProgressoLocal.sons_ligados()/musica_ligada()`, o som consome no M3-sons), Sair/Excluir conta (confirmação inline); guardam lugar: Idioma, Privacidade, Remover anúncios/Restaurar compras; dificuldade do Arcade SEM linha (não está no desenho — interna, padrão CHEIA). Tela 02b Info do jogador ✅ (avatar da Home; stats locais acumuladas; SEM porta p/ Conta — Configurações é a porta). **Desafios 3–4 ✅ (13/08)**: D3 Defesa (seed 303 — gigantes nível 100+ nascem a 2000 em arena 3000², turbo_bots 1.1: o turbo do jogador SEMPRE escapa, lição = gestão de energia; vitória emergente por extermínio é legítima e a celebração mostra "Arena dominada!"; HUD sem linha META — o cronômetro é a meta; banda 18/24, morre 6) e D4 Integração total (seed 404 — Top 3 com 20 bots exatos; "TERMINE" = vivo no encerramento; banda 20/24). Migração 0005 (CHECK challenge 0–3 — o da tabela derrubava INSERT com 500) + submit_session v3. Celebração encadeia D1→D2→D3→D4→Arcade. Faltam: AdMob, Billing (+ Loja 09*), sons, analyzer completo, EN/ES, publicação
- [x] Design system e telas em alta fidelidade geradas via Claude Design; tokens portados para `src/ui/theme/` (ver *Fundação visual*)

## Convenções de resposta

Responder em pt-BR; explicar decisões técnicas brevemente antes do código; entregar arquivos completos com caminho; comentários em pt-BR quando necessários; ao final de cada entrega, listar próximos passos e atualizar este arquivo com o status.
