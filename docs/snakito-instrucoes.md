# Snakito — Instruções Específicas

> Complementa **Instruções Globais — Linha de Apps Educacionais** (com a emenda de Trilhas de Tecnologia).
> O Snakito é o primeiro app da **Trilha B (Godot 4 + GDScript)**. Nada aqui contradiz as regras inegociáveis.
> Substitui integralmente o documento anterior "Snake Clash — Instruções Específicas".

---

## 1. Identidade educacional

**O que ensina:** estratégia em tempo real, gestão de risco/recompensa, leitura de padrões de comportamento, reação rápida.

**Público primário:** 7+; secundário: famílias.

**Diferencial vs. jogo casual comum:**
- Análise de mecânicas explicitamente dentro do app (modo "Aprender Estratégia")
- Desafios progressivos com metas claras (não só "crescer")
- Análise pós-partida que mostra *por quê* você perdeu
- Partidas **reproduzíveis por seed**: o mesmo desafio gera exatamente a mesma partida — o jogador pode tentar de novo e comparar decisões (mesmo padrão do desafio diário do Blokito)

**Nome verificado:** pesquisa na Play Store (ago/2026) não encontrou conflito direto com "Snakito". Categoria lotada de nomes "Snake*" (Snake.io, Snakzy, Snaky Cat), mas nenhuma colisão. Checagem final obrigatória no Play Console + INPI + domínio antes da publicação.

---

## 2. Mecânicas específicas (domínio do jogo)

### 2.1 Core Loop
1. Você entra na arena como cobra pequena (tamanho = 1)
2. **Objetivo:** comer comida ou bots menores → crescer → subir no ranking da partida
3. **Risco:** bots maiores podem devorá-lo → morte → tela de resultado
4. **Duração:** partida com tempo limite (ex.: 3 min) ou até morrer
5. **Pontuação:** tempo sobrevivido + comida + bots devorados

### 2.2 Crescimento
- Comida aleatória no mapa: +1 de tamanho, +10 pontos
- Bots devorados: crescimento proporcional ao tamanho da vítima, +100–500 pontos (escala não-linear)
- **Visibilidade:** quanto maior, maior o raio de visão (vantagem estratégica e maior exposição)
- **Velocidade cresce com o tamanho** (aprovado em ago/2026, playtest): comer →
  crescer → ficar mais rápido, dentro da partida. Curva suave com teto
  (`1 + ganho·(√tamanho − 1)`, clamp) para não virar bola de neve; vale para
  TODAS as cobras — bots sob as mesmas regras (honestidade). Compõe com o turbo
  (§2.6) e com o buff de conta (§2.6.2), que continuam existindo por cima.

### 2.3 Morte & Perda
- Qualquer cobra 10% maior pode matá-lo em um toque
- **Knockback:** você empurra cobras até 5% menores para escapar
- Ao morrer: mantém a pontuação da partida, vai para a tela de resultado

### 2.4 Bots & Arena Local (substitui o multiplayer)
**Decisão:** não há multiplayer. Toda partida é local, offline, contra 10–50 bots simulados.

- **Personalidades de bot** (cada arena mistura os três tipos):
  - **Fazendeiro** — evita conflito, prioriza comida, foge de cobras maiores
  - **Caçador** — persegue cobras menores dentro do raio de visão
  - **Oportunista** — farma, mas ataca alvos vulneráveis que cruzam seu caminho
- **Dificuldade** = composição da arena (quantidade, tamanho inicial, agressividade, **força de turbo** e **teto de crescimento** dos bots), nunca "trapaça" (bots não veem através da névoa nem reagem mais rápido que o permitido). Os dois eixos novos vieram do playtest de ago/2026: paridade total de turbo torna a caça impossível em campo aberto, e bots que se devoram sem teto viram gigantes que dominam a partida
- **Determinismo:** todo o `bot_engine` e o spawn de comida usam RNG seedável. Desafios têm seed fixa; modo Arcade usa seed aleatória exibida no resultado ("Repetir esta arena")
- **Simulação:** tick fixo de física (`_physics_process`, 60Hz); nenhuma dependência de rede em gameplay

### 2.5 Desafios Progressivos (Modo Educacional)
- **Desafio 1:** "Chegue a 50 pontos em 1 min sem matar ninguém" (farming puro)
- **Desafio 2:** "Devore 3 bots antes de 2 min" (agressão controlada)
- **Desafio 3:** "Sobreviva 3 min numa arena com 2 caçadores de tamanho 100+" (defesa)
- **Desafio 4:** "Termine no Top 3 de uma arena com 20 bots" (integração completa)

### 2.6 Turbo & Buffs (aprovado em ago/2026)

**Turbo — mecânica de partida, todas as cobras.** Aceleração ×1.5 com custo de
energia: barra de 100, consome 40/s ativo, regenera 16/s solto, exige ≥10 para
ATIVAR (desliga só em 0 — histerese contra liga-desliga). Sem turbo, perseguição
nunca alcança (velocidades base são iguais); com turbo, caçar e fugir viram
decisões de gasto de energia — exatamente o risco/recompensa que o jogo ensina.

- **Controle:** botão de turbo no canto oposto ao joystick (segurar = acelerar).
- **Bots usam turbo sob as MESMAS regras de energia** (Caçador ao perseguir;
  todas as personalidades ao fugir), decidindo na cadência honesta de 100ms.
  Bots nunca recebem os buffs do jogador; a FORÇA do turbo deles é eixo de
  composição da arena (`turbo_bots`, sempre ≤ 1.5 — capacidade transparente,
  não trapaça). Padrão do Arcade: 1.4.
- **Determinismo preservado:** turbo do jogador é input; o dos bots deriva do
  estado + RNG seedável.

**Buffs permanentes — loja com moedas (M2).** Preço por nível `200 × growth^N`
(conforme o design; a tela da loja confirma: Velocidade Nv 2 = 298 moedas).

| Buff | growth | Efeito por nível | Teto (Nv 10) |
|---|---|---|---|
| Velocidade | 1.22 | +0.05 no multiplicador do turbo | turbo ×2.0 |
| Ímã | 1.42 | +15 de raio de atração (Nv 1 = 40) | raio 175 |
| Pontos Iniciais | 1.13 | +5 pontos no início da partida | +50 |

- Buffs afetam **apenas o jogador** (jogo é PvE; dificuldade dos bots é
  composição de arena, nunca reação ao poder do jogador).
- Ímã atrai comida a 120 u/s dentro do raio; não atravessa a névoa de visão.
- Super buffs de Evolução (+1%/+3% por patente): seção própria quando o
  sistema de XP/patentes for especificado.

**Integridade educacional & ranking.**

- **Desafios SEMPRE ignoram buffs** — partida por seed precisa ser comparável
  ("aprender por comparação de decisões"). O turbo base vale: é mecânica igual
  para todos.
- Arcade aplica buffs; `submit_session` envia os níveis de buff no payload e a
  validação de plausibilidade da Edge Function os considera nos limites do motor.
- Ranking global do Arcade aceita score com buff; o M1 cria ranking separado de
  desafios (puros).
- O princípio do §11 permanece intacto para skins. Para buffs, o enunciado é:
  *vantagem comprável só contra bots, nunca sobre a comparabilidade educacional,
  e sempre alcançável grátis com moedas de partida*.

### 2.7 Corte de corpo (aprovado em ago/2026, pós-playtest do M1)

O corpo deixa de ser só visual: vira estado do domínio com colisão. Nova camada
tática — proteger o próprio rabo e atacar o rabo alheio.

**Regras (decididas pelo Rodrigo):**
1. **Quem corta (EM TESTE, ago/2026):** QUALQUER cobra corta qualquer corpo —
   sem regra de tamanho. É o contra-golpe do pequeno: o líder gigante tem o
   rabo comprido exposto. (Versão original: só quem pode devorar cortava;
   trocada a pedido do Rodrigo no playtest do corte para deixar o fim de
   jogo perigoso. Se o teste reprovar, voltar à regra 11/10.)
2. **Cabeça no corpo:** corta (fora da zona do pescoço) — knockback continua
   exclusivo do contato cabeça-cabeça.
3. **O que a vítima perde: SÓ MASSA.** Duas réguas separadas (decisão do
   Rodrigo, ago/2026): **nível** (sobe com comida/abate, NUNCA desce — dele
   derivam visão, velocidade e o direito de devorar) e **massa/corpo** (o
   físico). O corte encolhe a massa para a fração do ponto do corte e apara o
   corpo ali; nível, pontos, visão e velocidade ficam intactos — ser cortado
   não rebaixa o que você conquistou, e comer devolve a massa. A cabeça
   (raio) mostra o NÍVEL: gigante raspada continua com cara de gigante.
   Abate: pontos pelo nível da vítima; crescimento pela massa que sobrou
   (só se come o que existe).
4. **A parte cortada vira comida** espalhada ao longo do trecho perdido, com
   valor equivalente ao tamanho perdido (1 comida por unidade — invariante de
   plausibilidade preservada: `tamanho ≤ 1 + comidas + crescimento por abate`).
5. **Sem pontos pelo corte.** Kill (pontos + crescimento por abate) continua
   sendo SÓ devorar a cabeça. Morte também: a cobra só morre pela cabeça.
6. **Bots usam o corte** — caçador/oportunista miram o ponto mais próximo da
   presa (corpo ou cabeça), dentro da visão, sob as mesmas regras. Com o
   corte livre, caçador E oportunista colhem o rabo de qualquer cobra
   (inclusive superiores) — é o caminho deles para "ficar do mesmo nível"
   (playtest 11/08). **Coragem por personalidade**: o raio de fuga é uma
   fração da visão — fazendeiro foge ao avistar um devorador (1.0), caçador
   tolera até 0.6·visão e oportunista até 0.75·visão; no meio-termo, colhem
   rabo. Honesto: coragem não enxerga mais longe, só foge mais tarde — e às
   vezes paga com a vida.

**Decisões de implementação (onde a regra acima é omissa):**
- **Proteção pós-corte:** a vítima fica incortável por 1s (60 ticks) após
  sofrer um corte — sem isso, a cabeça deslizando pelo corpo retalha a vítima
  até 1 em poucos ticks. Devorar a cabeça NÃO tem proteção.
- **Pescoço é zona de cabeça:** pontos do corpo muito próximos da cabeça da
  vítima não contam como corpo (ali vale a colisão cabeça-cabeça).
- **Comprimento do corpo:** linear no tamanho (`12·(3 + tamanho)` unidades),
  única fonte de verdade — o render desenha o corpo do domínio.
- **Corpo de cobra morta desaparece** (não vira comida): o prêmio do abate já
  é pontos + crescimento; comida dupla inflaria o farm de kill.
- **Corte no rabo extremo que não muda o tamanho inteiro** (fração ≈ 1) não
  faz nada — evita cortes cosméticos infinitos.

---

## 3. Arquitetura de domínio (GDScript puro, sem cena)

```
src/domain/
├── game_engine.gd        # Física, colisão, crescimento, regras de morte
├── snake_model.gd        # Entidade cobra, estado
├── arena_model.gd        # Mapa, spawn de comida, lista de cobras
├── bot_engine.gd         # Personalidades, decisão por tick, dificuldade
├── strategy_analyzer.gd  # Análise pós-partida ("você poderia ter...")
├── challenge_rules.gd    # Regras e metas dos desafios
└── rng_service.gd        # RNG seedável centralizado (determinismo)
```

**Princípios:**
- Classes GDScript **puras** (`RefCounted`), sem herdar `Node` — nenhuma dependência de cena, renderização ou input
- Tipagem estática em 100% do domínio; avisos de tipo = erro
- Testadas isoladamente com **gdUnit4** (meta: paridade com o padrão do Blokito — cobertura de crescimento, morte, pontuação, desafios, determinismo de seed e comportamento de cada personalidade de bot)
- As cenas do Godot apenas renderizam o estado que o domínio calcula

---

## 4. Camadas da UI (Godot)

### 4.1 Telas funcionais (nós `Control` + `Theme` central)
- **Login / Cadastro** — **APENAS Google Sign-In** (decisão de ago/2026: zero fluxo de senha/e-mail próprio; menos superfície de dado e de suporte). Exige internet só neste passo
- **Home** (Arcade, Desafios, Ranking Global, Configurações)
- **Loja** (skins, Remover Anúncios — Fases 2+)
- **Ranking** (semana/mês/geral; requer conexão, com estado offline elegante)
- **Configurações** (som e música separados, háptica, idioma, privacidade, excluir conta)

Todos os tokens (cores, fontes, espaçamentos) vivem num único `Theme` resource + script de constantes. Nada hardcoded em cena.

### 4.2 Tela de jogo
- **Arena:** `Node2D` com câmera (`Camera2D`) seguindo o jogador; culling nativo do Godot; fundo em grade com parallax leve
- **Minimap:** `SubViewport` mostrando densidade de cobras (não identidades)
- **HUD** (`CanvasLayer`): tamanho/level, tempo restante, pontuação, posição ("4º de 28")
- **Controles:** joystick virtual flutuante (touch) com fallback de teclado; **botão de turbo** no canto oposto ao joystick (segurar = acelerar — mecânica em §2.6); botão de pausa com feedback sonoro

### 4.3 Tela pós-partida
- Posição final, breakdown de pontos (comida + kills + sobrevivência)
- **Análise estratégica** (se desafio ativo): sugestão concreta baseada na partida
- Seed da arena visível + botão "Repetir esta arena"
- Botões: Jogar Novamente, Menu, Compartilhar Resultado

---

## 5. Monetização (sequência Snakito)

- **Fase 1 (lançamento):** sem anúncios, sem compras; arquitetura de entitlements pronta desde o dia 1
- **Fase 2 (2–4 semanas):** AdMob certificado para famílias — banner apenas **entre** partidas; `tagForChildDirectedTreatment` ativo; consentimento UMP; oferta "assista 1 anúncio = +100 pontos na próxima partida" (rewarded)
- **Fase 3 (4–8 semanas):** "Remover Anúncios" (não consumível, ex.: R$ 14,90); skins premium em lotes (ex.: "Pacote Neon", R$ 9,90)
- **Fase 4 (futuro):** passe seasonal cosmético; booster consumível

**Plugins:** `godot-google-play-billing` (oficial, godot-sdk-integrations) e plugin AdMob com suporte COPPA/TFUA + UMP. Recibos validados em Edge Function. "Restaurar compras" sempre disponível. Skins nunca dão vantagem de gameplay.

---

## 6. Backend Supabase (sem Realtime)

**Modelo:** conta **obrigatória** (cadastro exige internet uma única vez) + jogo **100% offline** + ranking global **assíncrono**.

- Acesso via REST (`HTTPRequest`); nenhuma dependência de Supabase durante partidas
- **Fila offline:** sessões terminadas ficam em armazenamento local (`ConfigFile`/`FileAccess` criptografado com chave de dispositivo) e sobem quando houver conexão
- **Envio de sessão exclusivamente via Edge Function `submit_session`:**
  - Valida plausibilidade: score × duração × kills × seed coerentes com os limites do motor
  - RLS bloqueia INSERT direto em `game_sessions` e `leaderboard` por clientes
  - Não é anti-cheat blindado — é mitigação proporcional a um ranking cosmético

### Tabelas (inalteradas do plano original, exceto uso)
- `profiles` (id, username único, email, timestamps)
- `game_sessions` (user_id, seed, start/end, final_rank, score, size_reached, kills)
- `leaderboard` (denormalizado por semana, atualizado por trigger/cron)
- `entitlements` (entitlement_key: "ads_removed", "skin_neon_1"; expires_at NULL = perpétuo)

**RLS:** usuário lê só o próprio perfil/sessões; leaderboard é leitura pública; escrita de score só pela Edge Function.

---

## 7. Animação & Feedback (Tween + GPUParticles2D + háptica)

- **Crescimento:** escala suave via `Tween` (0.3s, ease out) ao comer
- **Morte:** flash vermelho + `Input.vibrate_handheld(500)` + som suave (não assustador)
- **Kill:** `GPUParticles2D` de confete no local + "ding" + pontos flutuando
- **Desafio completo:** celebração em tela cheia proporcional ao feito (regra da linha)
- **Som:** "pop" suave ao comer; BGM opcional e **desligada por padrão**; controles de som e música separados

---

## 8. Onboarding animado (sem texto)

1. Sua cobra pequena, uma comida brilha — você come, cresce (demonstração pura)
2. Aparece um bot menor — você o devora; ele vira confete
3. Aparece um bot maior — ele te toca; "game over" suave e acolhedor
4. Escolha visual de dificuldade: arena tranquila (poucos bots lentos) vs. arena cheia — ícones, zero texto

Duração total: ~30 segundos.

---

## 9. Conformidade & Segurança

- **Coleta mínima:** username, e-mail, estatísticas de partida — nada de GPS, câmera, contatos
- **Anúncios (Fase 2+):** certificados para famílias; sem rastreamento comportamental de menores
- **Consentimento parental** no cadastro se usuário <13 (LGPD)
- **Exclusão de conta** dentro do app: apaga perfil e sessões; mantém agregados anônimos
- **Build:** `.aab` com Play App Signing; formulário de Segurança de Dados com coleta mínima; política de privacidade publicada

---

## 10. Roadmap

### Spike (antes de tudo — 2–3 dias)
- [ ] Exportar `.aab` assinado com plugins de Billing + AdMob compilando juntos
- [ ] Mini-arena com 30 bots + joystick + câmera a 60fps em aparelho Android mediano (confirmação, não aposta)
- [ ] Sentry (SDK oficial Godot) reportando crash de teste

### MVP (Semana 1–2)
- [ ] Documentação completa aprovada (esta + `snakito-documentacao.md`)
- [ ] Core loop no domínio puro + testes gdUnit4
- [ ] Bots: 3 personalidades funcionais, determinismo por seed
- [ ] UI básica: Home, jogo, resultado
- [ ] 1 skin padrão — tudo 100% offline, sem conta ainda

### M1 (Semana 3–4)
- [ ] Auth Supabase (APENAS Google Sign-In) + consentimento parental
- [ ] Fila offline de sessões + Edge Function `submit_session` + ranking
- [ ] Desafios 1 & 2 + análise pós-partida v1
- [ ] Onboarding animado + 3 skins adicionais

### M2 (Semana 5–6)
- [ ] AdMob (banners entre partidas + rewarded) com entitlement check
- [ ] Play Billing: "Remover Anúncios" + restaurar compras
- [ ] Desafios 3 & 4 + strategy analyzer completo
- [ ] Idiomas: EN, ES (CSV de tradução; pt-BR padrão)
- [ ] Publicação Play Store (checklist da linha completo)

### Pós-lançamento
- [ ] Skins premium, passe seasonal, novas arenas/personalidades de bot
- [ ] Rebalanceamento por dados (Firebase Analytics modo restrito)

---

## 11. Decisões de design & rationale

| Decisão | Por quê |
|---|---|
| **Godot 4 + GDScript (Trilha B)** | Arena em tempo real com 50 entidades a 60fps é o ponto fraco do React Native (lição do Blokito); engine dedicada elimina o risco na raiz |
| **Bots em vez de multiplayer** | Offline-first de verdade, custo zero de servidor, sem anti-cheat pesado, sem dependência de massa crítica de jogadores |
| **Conta obrigatória + fila offline** | Ranking global e entitlements por conta (regra da linha) conciliados com jogo 100% offline; internet só no cadastro e na sincronização |
| **Determinismo por seed** | Desafios reproduzíveis = aprendizado por comparação de decisões; mesmo padrão do Blokito |
| **Bots honestos (sem trapaça)** | Dificuldade legível ensina estratégia; dificuldade trapaceira ensina frustração |
| **Edge Function para scores** | RLS não impede cliente de mentir; validação de plausibilidade no servidor é mitigação proporcional ao risco |
| **Skins, nunca stats** | Ninguém compra vantagem |
| **Tempo real, não turn-based** | Ensina reação imediata + decisão sob pressão |

---

## 12. Estado do projeto & próximos passos

**Repositório oficial:** `https://github.com/rodrigowaters/snakito` — repositório dedicado, separado do monorepo do Blokito, conforme a emenda de Trilhas de Tecnologia. Estrutura: `docs/`, `src/domain/`, `src/scenes/`, `src/ui/`, `tests/`, `export/`, com `CLAUDE.md` na raiz.

1. Aprovar este documento + emenda das Instruções Globais
2. Executar o **spike** (export + plugins + mini-arena) — critério de go/no-go
3. Redigir `snakito-documentacao.md` (padrão 9 seções da linha)
4. Sprint 1: core loop + bots

---

**Versão:** 2.2 (auth só-Google; adiciona §2.6 Turbo & Buffs; substitui Snake Clash v1.0)
**Data:** Ago 2026
**Stack:** Godot 4 (estável atual: 4.7.1) + GDScript tipado · Supabase (REST + Edge Functions) · gdUnit4 · Sentry (SDK oficial) · Firebase Analytics (plugin comunitário) · AdMob + Play Billing (plugins Godot)
**Status:** Aguardando aprovação → spike
