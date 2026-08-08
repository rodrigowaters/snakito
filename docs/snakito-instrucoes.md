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
- **Dificuldade** = composição da arena (quantidade, tamanho inicial e agressividade dos bots), nunca "trapaça" (bots não veem através da névoa nem reagem mais rápido que o permitido)
- **Determinismo:** todo o `bot_engine` e o spawn de comida usam RNG seedável. Desafios têm seed fixa; modo Arcade usa seed aleatória exibida no resultado ("Repetir esta arena")
- **Simulação:** tick fixo de física (`_physics_process`, 60Hz); nenhuma dependência de rede em gameplay

### 2.5 Desafios Progressivos (Modo Educacional)
- **Desafio 1:** "Chegue a 50 pontos em 1 min sem matar ninguém" (farming puro)
- **Desafio 2:** "Devore 3 bots antes de 2 min" (agressão controlada)
- **Desafio 3:** "Sobreviva 3 min numa arena com 2 caçadores de tamanho 100+" (defesa)
- **Desafio 4:** "Termine no Top 3 de uma arena com 20 bots" (integração completa)

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
- **Login / Cadastro** (e-mail + Google Sign-In; exige internet só neste passo)
- **Home** (Arcade, Desafios, Ranking Global, Configurações)
- **Loja** (skins, Remover Anúncios — Fases 2+)
- **Ranking** (semana/mês/geral; requer conexão, com estado offline elegante)
- **Configurações** (som e música separados, háptica, idioma, privacidade, excluir conta)

Todos os tokens (cores, fontes, espaçamentos) vivem num único `Theme` resource + script de constantes. Nada hardcoded em cena.

### 4.2 Tela de jogo
- **Arena:** `Node2D` com câmera (`Camera2D`) seguindo o jogador; culling nativo do Godot; fundo em grade com parallax leve
- **Minimap:** `SubViewport` mostrando densidade de cobras (não identidades)
- **HUD** (`CanvasLayer`): tamanho/level, tempo restante, pontuação, posição ("4º de 28")
- **Controles:** joystick virtual (touch) ou arrastar direcional; deslizar para cima = aceleração com custo de energia (opcional); botão de pausa com feedback sonoro

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
- [ ] Auth Supabase (e-mail + Google Sign-In) + consentimento parental
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

**Versão:** 2.0 (substitui Snake Clash v1.0)
**Data:** Ago 2026
**Stack:** Godot 4.8 + GDScript tipado · Supabase (REST + Edge Functions) · gdUnit4 · Sentry (SDK oficial) · Firebase Analytics (plugin comunitário) · AdMob + Play Billing (plugins Godot)
**Status:** Aguardando aprovação → spike
