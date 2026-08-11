class_name SnakeModel
extends RefCounted
## Entidade cobra: estado puro + propriedades derivadas do tamanho.
## Sem cena, sem render, sem input (regra dura #1). Quem aplica as regras de
## jogo (morte, pontuação, movimento) é o GameEngine; este modelo só sabe o
## que é intrínseco à cobra.

## Personalidade controla quem decide a direção: JOGADOR = input externo;
## demais = BotEngine (docs §2.4).
enum Personalidade { JOGADOR, FAZENDEIRO, CACADOR, OPORTUNISTA }

# --- Geometria derivada do tamanho -------------------------------------------
## Raio de colisão base (tamanho 1), em unidades de mundo.
const RAIO_BASE: float = 10.0
## Crescimento do raio por sqrt(tamanho) — raiz para o crescimento desacelerar.
const RAIO_POR_TAMANHO: float = 2.0
## Raio de visão no tamanho 1 (docs §2.2: maior cobra → maior visão).
const VISAO_BASE: float = 220.0
## Ganho de visão por unidade de tamanho.
const VISAO_POR_TAMANHO: float = 6.0
## Teto da visão — mantém a névoa relevante até para cobras gigantes.
const VISAO_MAX: float = 700.0

# --- Turbo (docs §2.6) --------------------------------------------------------
## Capacidade máxima de energia de turbo.
const ENERGIA_MAX: float = 100.0
## Multiplicador de velocidade do turbo sem buff (bots usam sempre este).
const TURBO_BASE: float = 1.5

# --- Velocidade por tamanho (docs §2.2, ago/2026) ------------------------------
## Curva: 1 + GANHO·(√tamanho − 1), clamp no teto. √ para o ganho desacelerar;
## tamanho 1 = exatamente 1.0 (o novato anda na base). No teto (+25%), o
## gigante alcança pequenos sem turbo — é a recompensa de crescer que o
## playtest pediu; o teto impede a bola de neve de ficar incaçável.
const VEL_GANHO_POR_TAMANHO: float = 0.03
const VEL_TETO_TAMANHO: float = 1.25

# --- Corpo (docs §2.7) ----------------------------------------------------------
## Comprimento do corpo em unidades de mundo: linear no tamanho. Única fonte
## de verdade — o render desenha ESTE corpo, não uma trilha própria.
const CORPO_BASE_SEGMENTOS: float = 3.0
const CORPO_COMPRIMENTO_POR_TAMANHO: float = 12.0
## Zona do pescoço (em raios da vítima): pontos do corpo a menos disso da
## cabeça não contam como corpo cortável — ali vale a colisão cabeça-cabeça.
const CORPO_ZONA_PESCOCO_RAIOS: float = 2.0

# --- Regra de devorar (docs §2.3: "qualquer cobra 10% maior mata em um toque")
# Razão 11/10 em inteiros: comparar com float (1.1 * tamanho) erra no limiar
# exato (1.1 não tem representação binária finita — 11 >= 1.1*10 dá falso!).
const DEVORAR_NUMERADOR: int = 11
const DEVORAR_DENOMINADOR: int = 10

var id: int
var personalidade: Personalidade
var posicao: Vector2
## Direção de movimento (unitária). O GameEngine move; bots/input só apontam.
var direcao: Vector2 = Vector2.RIGHT
## Tamanho em unidades de crescimento (começa em 1 — docs §2.1).
var tamanho: int = 1
var pontos: int = 0
var viva: bool = true
## 0..1 — escala o alcance de caça/oportunidade (dificuldade da arena, §2.4).
var agressividade: float = 0.5

# --- Turbo (docs §2.6) ---
## Energia corrente de turbo.
var energia: float = ENERGIA_MAX
## INTENÇÃO de turbo (input do jogador / decisão do bot). Quem resolve se
## vira turbo de fato — pelas regras de energia — é o GameEngine.
var quer_turbo: bool = false
## Turbo efetivamente ativo neste tick (resolvido pelo GameEngine).
var turbo_ativo: bool = false
## Multiplicador do turbo. Só o jogador com buff passa de TURBO_BASE (§2.6.2).
var multiplicador_turbo: float = TURBO_BASE
## Raio do ímã de comida; 0 = sem ímã (buff exclusivo do jogador).
var raio_ima: float = 0.0

# --- Corpo (docs §2.7) ---
## Trilha da cabeça, do ponto mais recente ([0] = pescoço) ao rabo. Estado de
## DOMÍNIO: é aqui que o corte colide; o render desenha esta trilha.
var corpo: PackedVector2Array = PackedVector2Array()
## Tick até o qual esta cobra está protegida de novos cortes (proteção de 1s
## após sofrer um — sem ela a cabeça deslizando retalha até 1 em poucos ticks).
var protegida_de_corte_ate: int = -1

# --- Estatísticas para resultado e análise pós-partida ---
var comidas: int = 0
var abates: int = 0
var ticks_vividos: int = 0
## Cortes que esta cobra APLICOU / SOFREU (docs §2.7 — insumo de análise).
var cortes_feitos: int = 0
var cortes_sofridos: int = 0


func _init(
	id_: int,
	personalidade_: Personalidade,
	posicao_: Vector2,
	tamanho_: int = 1,
) -> void:
	id = id_
	personalidade = personalidade_
	posicao = posicao_
	tamanho = tamanho_


func eh_jogador() -> bool:
	return personalidade == Personalidade.JOGADOR


## Raio de colisão atual.
func raio() -> float:
	return RAIO_BASE + RAIO_POR_TAMANHO * sqrt(float(tamanho))


## Raio de visão atual — bots HONESTOS só enxergam dentro dele (regra dura #3).
func raio_visao() -> float:
	return minf(VISAO_BASE + VISAO_POR_TAMANHO * float(tamanho), VISAO_MAX)


## Esta cobra é pelo menos 10% maior que a outra? (condição de devorar)
func pode_devorar(outra: SnakeModel) -> bool:
	return tamanho * DEVORAR_DENOMINADOR >= outra.tamanho * DEVORAR_NUMERADOR


## Multiplicador de velocidade neste tick: fator do tamanho (docs §2.2)
## composto com o turbo quando ativo.
func multiplicador_velocidade() -> float:
	var fator: float = multiplicador_tamanho()
	if turbo_ativo:
		fator *= multiplicador_turbo
	return fator


## Fator de velocidade pelo tamanho: comer → crescer → correr mais (§2.2).
func multiplicador_tamanho() -> float:
	return minf(
		1.0 + VEL_GANHO_POR_TAMANHO * (sqrt(float(tamanho)) - 1.0),
		VEL_TETO_TAMANHO,
	)


## Comprimento-alvo do corpo (unidades de mundo) para o tamanho atual.
func comprimento_corpo() -> float:
	return CORPO_COMPRIMENTO_POR_TAMANHO * (CORPO_BASE_SEGMENTOS + float(tamanho))


func crescer(quantidade: int) -> void:
	tamanho += quantidade
