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

# --- Estatísticas para resultado e análise pós-partida ---
var comidas: int = 0
var abates: int = 0
var ticks_vividos: int = 0


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


func crescer(quantidade: int) -> void:
	tamanho += quantidade
