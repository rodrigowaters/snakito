# PROPOSTA — Seção 2.6 do `snakito-instrucoes.md`: Turbo & Buffs

> **Status: aguardando aprovação do Rodrigo.** Após aprovar/editar, o texto
> abaixo entra no `snakito-instrucoes.md` como §2.6 (e §4.2 ganha um ajuste),
> e só então a implementação começa — regra da linha: documentar primeiro.
>
> Origem: o design aprovado no Claude Design (`docs/design/snakito-tokens.json`,
> seção `economy`, + telas da loja) especifica buffs compráveis de Velocidade,
> Ímã e Pontos Iniciais com preço `200 × growth^N`, mas **não** especifica a
> mecânica de turbo que o buff de velocidade fortalece, nem o ganho por nível.
> Esta proposta preenche essas lacunas. Valores marcados ⚙️ são tuning inicial
> (constantes no domínio, fáceis de ajustar); decisões marcadas ❓ pedem
> escolha explícita.

---

## 2.6 Turbo & Buffs

### 2.6.1 Turbo (mecânica de partida)

Toda cobra tem um **turbo**: aceleração temporária com custo de energia.
É a resposta do jogo ao fato de todas as velocidades base serem iguais —
sem turbo, perseguição nunca alcança e fuga nunca escapa; com turbo, caçar
e fugir viram **decisões de gasto de energia** (risco/recompensa, o que o
jogo ensina).

| Parâmetro | Valor inicial ⚙️ | Nota |
|---|---|---|
| Multiplicador de velocidade | ×1.5 | 180 → 270 unidades/s |
| Energia máxima | 100 | barra no HUD (ProgressBar do tema) |
| Consumo com turbo ativo | 40/s | ~2.5s de turbo contínuo cheio |
| Regeneração com turbo solto | 16/s | ~6.2s para encher do zero |
| Energia mínima para ativar | 10 | evita "tremedeira" liga-desliga no zero |

- **Controle** ❓: botão de turbo no canto oposto ao joystick (alvo ≥56dp,
  segurar = acelerar). O §4.2 original dizia "deslizar para cima"; com
  joystick flutuante, o gesto conflita com direção — proposta é **botão**.
  (Alternativa B: segundo toque em qualquer lugar da tela.)
- **Bots usam turbo** sob as MESMAS regras de energia (bots honestos):
  Caçador acelera ao perseguir presa na visão; todas as personalidades
  aceleram ao fugir de ameaça. A decisão continua na cadência de 100ms.
  Bots **nunca** recebem os níveis de buff do jogador — o turbo deles é
  sempre o base (×1.5).
- **Determinismo:** o turbo do jogador é input (como a direção); o dos bots
  deriva do estado + RNG seedável. Nada muda no contrato de seed.
- **Fase:** mecânica de jogo → entra já (MVP+), independente de loja/moedas.

### 2.6.2 Buffs permanentes (comprados na loja com moedas — M2)

Preço por nível conforme o design: `preco(N→N+1) = 200 × growth^N`, arredondado.
O que o design não fixou — **ganho por nível e teto** — proposto aqui:

| Buff | growth (design) | Efeito por nível ⚙️ | Teto ⚙️ | No teto |
|---|---|---|---|---|
| **Velocidade** | 1.22 | +0.05 no multiplicador do turbo | Nv 10 | turbo ×2.0 |
| **Ímã** | 1.42 | +15 de raio de atração de comida (Nv 1 = 40) | Nv 10 | raio 175 |
| **Pontos Iniciais** | 1.13 | +5 pontos no início da partida | Nv 10 | +50 pontos |

- Buffs afetam **apenas o jogador** (o jogo é PvE; a dificuldade dos bots é
  composição de arena, nunca reação ao poder do jogador).
- O ímã atrai comida dentro do raio na direção do jogador (velocidade de
  atração ⚙️ 120 u/s); não atravessa a névoa de visão.
- "Compra sem saldo via anúncio recompensado" (design) segue as regras de
  anúncios da Fase 2+ (entitlement check, COPPA/TFUA).
- Os **super buffs de Evolução** (+1%/+3% por patente, até patente 100) ficam
  FORA desta seção: dependem do sistema de XP/patentes, que não tem doc nem
  design de mecânica ainda — seção própria quando chegar.

### 2.6.3 Integridade educacional & ranking

Aqui mora a tensão com o princípio "ninguém compra vantagem" (§11). Resolução
proposta:

1. **Desafios (modo educacional) SEMPRE ignoram buffs.** Desafio é partida
   reproduzível e comparável por seed; buff quebraria a comparabilidade e o
   propósito ("aprender por comparação de decisões"). O turbo base (×1.5)
   vale — é mecânica, igual para todos.
2. **Arcade aplica buffs**, e o envio de sessão (`submit_session`) passa a
   incluir os níveis de buff no payload; a validação de plausibilidade da
   Edge Function usa esses níveis nos limites do motor.
3. ❓ **Ranking global:** aceitar score com buff (posição = progresso total,
   padrão dos jogos casuais) **ou** ranquear só desafios (puros)? Proposta:
   aceitar no ranking semanal/geral do Arcade e criar ranking separado de
   desafios no M1. A decisão é de produto e fica registrada aqui.
4. Reformulação do princípio §11: **"Skins nunca dão vantagem"** permanece
   intacto. O novo enunciado para buffs: *"vantagem comprável só contra bots,
   nunca sobre a comparabilidade educacional (desafios) — e sempre alcançável
   grátis via moedas de partida"*.

### 2.6.4 Impacto no domínio (quando aprovado)

| Arquivo | Mudança |
|---|---|
| `snake_model.gd` | `energia: float`, `turbo_ativo: bool`, `multiplicador_turbo: float = 1.5`, `raio_ima: float = 0.0`, `velocidade_atual()` |
| `game_engine.gd` | consumo/regeneração de energia por tick; movimento usa `velocidade_atual()`; atração do ímã em `_resolver_comida()`; `ConfigPartida` ganha `buffs_jogador` e `aplicar_buffs: bool` (falso em desafios); pontos iniciais no spawn |
| `bot_engine.gd` | decisão de turbo por personalidade (caça/fuga), mesma cadência de 100ms |
| `tests/domain/` | energia (consumo/regen/limiar), perseguição COM turbo alcança / SEM turbo não alcança, ímã respeita raio, buffs desligados em desafio, determinismo com turbo |
| Cenas | botão de turbo no HUD + barra de energia (ProgressBar do tema) |

---

**Aprovação:** editar valores/decisões ❓ à vontade; com o OK, esta seção é
movida para o `snakito-instrucoes.md` (vira §2.6, bump para v2.1) e a
implementação segue a ordem: domínio+testes → HUD → loja (M2).
