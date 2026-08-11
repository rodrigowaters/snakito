class_name Minimapa
extends Control
## Minimapa (docs §4.2): mostra DENSIDADE de cobras, não identidades —
## você localiza a ação sem ganhar visão sobre-humana de quem é quem.
## Resolve o "demorado para localizar inimigo no fim do jogo" (playtest
## 10/08): com a arena de 2400² e poucos sobreviventes, a caçada final
## precisava de bússola.

const T := preload("res://src/ui/theme/tokens.gd")

## Lado do minimapa em px de design (arena é quadrada). O blueprint do HUD
## (tela 04) o encaixa como chip de 48 na barra do topo; 104 foi o tamanho
## do playtest de 10/08 — parametrizado para servir aos dois.
var lado: float = 104.0
## Pontos no tamanho de referência (104): jogador maior e na cor da skin;
## demais são pontos anônimos. Escalam junto com `lado`.
const LADO_REFERENCIA: float = 104.0
const RAIO_PONTO_JOGADOR: float = 3.5
const RAIO_PONTO_COBRA: float = 2.0

var _motor: GameEngine


func _init(lado_: float = 104.0) -> void:
	lado = lado_


func _ready() -> void:
	custom_minimum_size = Vector2(lado, lado)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func atualizar(motor: GameEngine) -> void:
	_motor = motor
	queue_redraw()


func _draw() -> void:
	if _motor == null:
		return
	var quadro: Rect2 = Rect2(Vector2.ZERO, Vector2(lado, lado))
	# Vidro do design: fundo translúcido + borda sutil.
	draw_rect(quadro, T.COR_SUPERFICIE_HUD)
	draw_rect(quadro, T.COR_SUPERFICIE_VIDRO_BORDA, false, float(T.BORDA_FINA))

	var fator: float = lado / LADO_REFERENCIA
	var escala: float = lado / _motor.arena.tamanho.x
	for cobra: SnakeModel in _motor.arena.cobras:
		if not cobra.viva or cobra.eh_jogador():
			continue
		# Anônimo de propósito (densidade, não identidade — docs §4.2).
		draw_circle(cobra.posicao * escala, RAIO_PONTO_COBRA * fator,
			T.COR_TEXTO_SECUNDARIO)
	var jogador: SnakeModel = _motor.jogador()
	if jogador.viva:
		draw_circle(jogador.posicao * escala, RAIO_PONTO_JOGADOR * fator,
			ArenaRender.cor_de(jogador))
