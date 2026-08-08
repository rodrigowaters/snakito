class_name ArenaRender
extends Node2D
## Desenha o estado do GameEngine: grade, comida e cobras. SÓ leitura —
## nenhuma regra de jogo aqui (regra dura #1). Um único _draw() por frame,
## com culling pelo retângulo visível da câmera.

const T := preload("res://src/ui/theme/tokens.gd")

## Escala do mundo: 1 célula da grade do design (26dp) vira 26×ESCALA unidades
## de mundo. Única constante de render que não é token — documentada aqui.
const ESCALA_MUNDO: float = 2.0
## Espaçamento entre segmentos do corpo, em frações do raio da cabeça.
const ESPACO_SEGMENTO: float = 0.9
## Limite de segmentos desenhados por cobra (performance na arena de 30 bots).
const MAX_SEGMENTOS: int = 24
## Pontos de trilha guardados por cobra (a 3 unidades/tick cobre o corpo máximo).
const MAX_TRILHA: int = 400

var motor: GameEngine

## Trilha de posições recentes da cabeça, por id (estado de RENDER, não de jogo:
## a colisão do domínio é pela cabeça; o corpo é visual).
var _trilhas: Dictionary[int, PackedVector2Array] = {}


## Chamar 1x por tick de física, depois de motor.avancar().
func registrar_tick() -> void:
	for cobra: SnakeModel in motor.arena.cobras:
		if not cobra.viva:
			_trilhas.erase(cobra.id)
			continue
		if not _trilhas.has(cobra.id):
			_trilhas[cobra.id] = PackedVector2Array()
		var trilha: PackedVector2Array = _trilhas[cobra.id]
		trilha.insert(0, cobra.posicao)
		if trilha.size() > MAX_TRILHA:
			trilha.resize(MAX_TRILHA)
		_trilhas[cobra.id] = trilha
	queue_redraw()


func _draw() -> void:
	if motor == null:
		return
	var visivel: Rect2 = _retangulo_visivel().grow(64.0)
	_desenhar_fundo(visivel)
	_desenhar_comidas(visivel)
	for cobra: SnakeModel in motor.arena.cobras:
		if cobra.viva:
			_desenhar_cobra(cobra, visivel)


## Cor base de uma cobra: jogador = verde (skin padrão do MVP); bots ciclam
## a paleta de 8 cores do design.
static func cor_de(cobra: SnakeModel) -> Color:
	return T.CORES_COBRA_BASE[cobra.id % T.CORES_COBRA_BASE.size()]


static func cor_escura_de(cobra: SnakeModel) -> Color:
	return T.CORES_COBRA_ESCURA[cobra.id % T.CORES_COBRA_ESCURA.size()]


func _retangulo_visivel() -> Rect2:
	var inversa: Transform2D = get_viewport_transform().affine_inverse()
	var topo: Vector2 = inversa * Vector2.ZERO
	var base: Vector2 = inversa * get_viewport_rect().size
	return Rect2(topo, base - topo).abs()


func _desenhar_fundo(visivel: Rect2) -> void:
	var arena: Rect2 = motor.arena.limites()
	draw_rect(arena, T.COR_ARENA_FUNDO)
	# Grade sutil, só nas linhas visíveis.
	var celula: float = T.ARENA_GRADE_TAMANHO * ESCALA_MUNDO
	var recorte: Rect2 = visivel.intersection(arena)
	var x: float = floorf(recorte.position.x / celula) * celula
	while x <= recorte.end.x:
		draw_line(Vector2(x, recorte.position.y), Vector2(x, recorte.end.y), T.COR_ARENA_GRADE)
		x += celula
	var y: float = floorf(recorte.position.y / celula) * celula
	while y <= recorte.end.y:
		draw_line(Vector2(recorte.position.x, y), Vector2(recorte.end.x, y), T.COR_ARENA_GRADE)
		y += celula
	# Parede da arena.
	draw_rect(arena, T.COR_SUPERFICIE_VIDRO_BORDA, false, 4.0)


func _desenhar_comidas(visivel: Rect2) -> void:
	for posicao: Vector2 in motor.arena.comidas:
		if not visivel.has_point(posicao):
			continue
		# Halo suave + miolo, como no design (food/comum + realce).
		draw_circle(posicao, ArenaModel.RAIO_COMIDA * 1.8, Color(T.COR_COMIDA_COMUM, 0.25))
		draw_circle(posicao, ArenaModel.RAIO_COMIDA, T.COR_COMIDA_COMUM)
		draw_circle(posicao, ArenaModel.RAIO_COMIDA * 0.45, T.COR_COMIDA_COMUM_REALCE)


func _desenhar_cobra(cobra: SnakeModel, visivel: Rect2) -> void:
	var raio: float = cobra.raio()
	if not visivel.grow(raio).has_point(cobra.posicao):
		return
	var base: Color = cor_de(cobra)
	var escura: Color = cor_escura_de(cobra)

	# Corpo: segmentos amostrados na trilha, do rabo (menor, mais transparente)
	# para a cabeça — mesmo desenho do logo/design system.
	var segmentos: PackedVector2Array = _pontos_do_corpo(cobra)
	for i: int in range(segmentos.size() - 1, -1, -1):
		var fracao: float = 1.0 - float(i + 1) / float(segmentos.size() + 1)
		var raio_seg: float = raio * lerpf(0.55, 0.92, fracao)
		draw_circle(segmentos[i], raio_seg, Color(base, lerpf(0.45, 0.95, fracao)))

	# Cabeça com contorno no tom escuro da skin.
	draw_circle(cobra.posicao, raio + 1.5, escura)
	draw_circle(cobra.posicao, raio, base)
	_desenhar_olhos(cobra, raio)


func _desenhar_olhos(cobra: SnakeModel, raio: float) -> void:
	var frente: Vector2 = cobra.direcao if cobra.direcao != Vector2.ZERO else Vector2.RIGHT
	var lado: Vector2 = frente.orthogonal()
	var raio_olho: float = raio * 0.28
	for sinal: float in [-1.0, 1.0]:
		var centro: Vector2 = cobra.posicao + frente * raio * 0.45 + lado * sinal * raio * 0.38
		draw_circle(centro, raio_olho, T.COR_SIMBOLO_DALTONISMO)
		draw_circle(centro + frente * raio_olho * 0.35, raio_olho * 0.5, T.COR_ARENA_FUNDO)


func _pontos_do_corpo(cobra: SnakeModel) -> PackedVector2Array:
	var pontos: PackedVector2Array = PackedVector2Array()
	if not _trilhas.has(cobra.id):
		return pontos
	var trilha: PackedVector2Array = _trilhas[cobra.id]
	var espaco: float = cobra.raio() * ESPACO_SEGMENTO
	var alvo: int = mini(3 + cobra.tamanho, MAX_SEGMENTOS)
	var acumulado: float = 0.0
	var proximo_em: float = espaco
	for i: int in range(1, trilha.size()):
		acumulado += trilha[i - 1].distance_to(trilha[i])
		if acumulado >= proximo_em:
			pontos.append(trilha[i])
			proximo_em += espaco
			if pontos.size() >= alvo:
				break
	return pontos
