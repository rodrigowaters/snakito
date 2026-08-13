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

## Pulso de escala ao comer (docs §7: crescimento suave, 0.3s ease out).
const PULSO_CRESCIMENTO: float = 1.25
const PULSO_DURACAO: float = 0.3

var motor: GameEngine
## Badges de pontos sobre as cobras (blueprint 04).
var mostrar_badges: bool = true

## Fator de escala visual corrente por id (1.0 = sem pulso).
var _pulsos: Dictionary[int, float] = {}


## Dispara o pulso de crescimento de uma cobra (Tween 0.3s ease out — §7).
func pulsar_crescimento(id: int) -> void:
	_pulsos[id] = PULSO_CRESCIMENTO
	var tween: Tween = create_tween()
	tween.tween_method(
		func(valor: float) -> void: _pulsos[id] = valor,
		PULSO_CRESCIMENTO, 1.0, PULSO_DURACAO,
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## Chamar 1x por tick de física, depois de motor.avancar().
## (O corpo agora é estado do DOMÍNIO — docs §2.7; aqui só se redesenha.)
func registrar_tick() -> void:
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
	# Badges por cima de todas as cobras (blueprint 04).
	if mostrar_badges:
		for cobra: SnakeModel in motor.arena.cobras:
			if cobra.viva and visivel.has_point(cobra.posicao):
				_desenhar_badge_pontos(cobra)


## Cor base de uma cobra: jogador = skin equipada (ProgressoLocal, com cache
## em memória — zero I/O no _draw); bots ciclam as OUTRAS 7 cores — a cor do
## jogador é exclusiva dele. Bots com a cor do jogador criavam crise de
## identidade em tela ("qual cobra sou eu?!", playtest 10/08).
static func cor_de(cobra: SnakeModel) -> Color:
	return _cor_na(T.CORES_COBRA_BASE, cobra)


static func cor_escura_de(cobra: SnakeModel) -> Color:
	return _cor_na(T.CORES_COBRA_ESCURA, cobra)


static func _cor_na(paleta: Array[Color], cobra: SnakeModel) -> Color:
	return paleta[_indice_cor_de(cobra)]


func _retangulo_visivel() -> Rect2:
	# get_canvas_transform (mundo → coords de design do viewport) — e NÃO
	# get_viewport_transform, que no aparelho inclui o stretch da tela e
	# encolhia o culling: com zoom 1.6 só ~1/4 do mundo era desenhado
	# (playtest 10/08, "o jogo está ocupando 1/4 da tela").
	return get_canvas_transform().affine_inverse() * get_viewport_rect()


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
		# Halo suave + miolo, como no design (food/comum + realce). O desenho
		# é maior que a colisão (RAIO_COMIDA) de propósito: legibilidade no
		# celular — e errar "para o generoso" no toque nunca frustra.
		draw_circle(posicao, ArenaModel.RAIO_COMIDA * 2.4, Color(T.COR_COMIDA_COMUM, 0.22))
		draw_circle(posicao, ArenaModel.RAIO_COMIDA * 1.35, T.COR_COMIDA_COMUM)
		draw_circle(posicao, ArenaModel.RAIO_COMIDA * 0.6, T.COR_COMIDA_COMUM_REALCE)


func _desenhar_cobra(cobra: SnakeModel, visivel: Rect2) -> void:
	var raio: float = cobra.raio() * _pulsos.get(cobra.id, 1.0)
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
	# Modo daltonismo (tokens §4): símbolo da cor estampado na cabeça e a
	# cada N segmentos — canal redundante além da cor.
	if ProgressoLocal.daltonismo():
		_desenhar_simbolo(cobra.posicao + Vector2(0.0, raio * 0.35),
			raio * T.SIMBOLO_ESCALA * 0.5, _indice_cor_de(cobra))
		var passo: int = T.SIMBOLO_INTERVALO_SEGMENTOS
		for i: int in range(passo - 1, segmentos.size(), passo):
			var raio_seg: float = raio * lerpf(0.55, 0.92,
				1.0 - float(i + 1) / float(segmentos.size() + 1))
			_desenhar_simbolo(segmentos[i], raio_seg * T.SIMBOLO_ESCALA * 0.5,
				_indice_cor_de(cobra))
	_desenhar_olhos(cobra, raio)


## Badge de pontos sobre a cabeça (blueprint 04): pílula escura com a borda
## codificando a AMEAÇA em relação ao jogador — leitura de risco em jogo:
## vermelha = pode te devorar · verde = você pode devorar · branca = você
## mesmo ou porte parecido (knockback).
const BADGE_ALTURA: float = 20.0
const BADGE_FONTE: int = 11
const BADGE_FOLGA: float = 10.0

func _desenhar_badge_pontos(cobra: SnakeModel) -> void:
	var jogador: SnakeModel = motor.jogador()
	var borda: Color
	var cor_texto: Color
	if cobra.eh_jogador() or not jogador.viva:
		borda = Color(T.COR_TEXTO_PRIMARIO, 0.5)
		cor_texto = T.COR_TEXTO_PRIMARIO
	elif cobra.pode_devorar(jogador):
		borda = T.COR_COMIDA_COMUM          # #FF6B6B — perigo (design 04)
		cor_texto = T.COR_COMIDA_COMUM_REALCE
	elif jogador.pode_devorar(cobra):
		borda = T.CORES_COBRA_BASE[0]       # #4ADE80 — presa (design 04)
		cor_texto = T.CORES_COBRA_BASE[0]
	else:
		borda = Color(T.COR_TEXTO_PRIMARIO, 0.5)
		cor_texto = T.COR_TEXTO_PRIMARIO

	var fonte: Font = ThemeDB.get_project_theme().get_font(&"font", &"TituloMd")
	var texto: String = Hud.formatar_milhar(cobra.pontos)
	var largura_texto: float = fonte.get_string_size(
		texto, HORIZONTAL_ALIGNMENT_CENTER, -1, BADGE_FONTE).x
	var largura: float = largura_texto + BADGE_ALTURA * 0.7
	var centro: Vector2 = cobra.posicao \
		+ Vector2(0.0, -cobra.raio() - BADGE_FOLGA - BADGE_ALTURA * 0.5)
	var raio_pilula: float = BADGE_ALTURA * 0.5

	# Cápsula: dois círculos + retângulo central; contorno com arcos.
	var esquerda: Vector2 = centro + Vector2(-largura * 0.5 + raio_pilula, 0.0)
	var direita: Vector2 = centro + Vector2(largura * 0.5 - raio_pilula, 0.0)
	draw_circle(esquerda, raio_pilula, T.COR_SUPERFICIE_HUD)
	draw_circle(direita, raio_pilula, T.COR_SUPERFICIE_HUD)
	draw_rect(Rect2(esquerda - Vector2(0.0, raio_pilula),
		Vector2(direita.x - esquerda.x, BADGE_ALTURA)), T.COR_SUPERFICIE_HUD)
	draw_arc(esquerda, raio_pilula, PI * 0.5, PI * 1.5, 10, borda, 1.5)
	draw_arc(direita, raio_pilula, -PI * 0.5, PI * 0.5, 10, borda, 1.5)
	draw_line(esquerda + Vector2(0.0, -raio_pilula),
		direita + Vector2(0.0, -raio_pilula), borda, 1.5)
	draw_line(esquerda + Vector2(0.0, raio_pilula),
		direita + Vector2(0.0, raio_pilula), borda, 1.5)
	draw_string(fonte,
		centro + Vector2(-largura_texto * 0.5, BADGE_FONTE * 0.36),
		texto, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONTE, cor_texto)


## Índice da cor da cobra na paleta (jogador = skin; bots pulam esse índice).
static func _indice_cor_de(cobra: SnakeModel) -> int:
	var skin: int = ProgressoLocal.skin_equipada()
	if cobra.eh_jogador():
		return skin
	var indice: int = (cobra.id - 1) % (T.CORES_COBRA_BASE.size() - 1)
	if indice >= skin:
		indice += 1
	return indice


## Símbolo geométrico do modo daltonismo (tokens SIMBOLOS_COBRA): branco com
## traço escuro de apoio, um por cor de cobra.
func _desenhar_simbolo(centro: Vector2, raio: float, indice_cor: int) -> void:
	var simbolo: int = T.SIMBOLOS_COBRA[indice_cor]
	var branco: Color = T.COR_SIMBOLO_DALTONISMO
	var traco: Color = T.COR_SIMBOLO_DALTONISMO_TRACO
	match simbolo:
		T.SimboloDaltonismo.CIRCULO:
			draw_circle(centro, raio, branco)
			draw_arc(centro, raio, 0.0, TAU, 16, traco, 1.2)
		T.SimboloDaltonismo.TRIANGULO:
			_poligono_simbolo(centro, raio, 3, -PI * 0.5, branco, traco)
		T.SimboloDaltonismo.QUADRADO:
			_poligono_simbolo(centro, raio, 4, PI * 0.25, branco, traco)
		T.SimboloDaltonismo.LOSANGO:
			_poligono_simbolo(centro, raio, 4, 0.0, branco, traco)
		T.SimboloDaltonismo.ESTRELA:
			var pontos: PackedVector2Array = PackedVector2Array()
			for i: int in 10:
				var alcance: float = raio if i % 2 == 0 else raio * 0.45
				var angulo: float = -PI * 0.5 + TAU * float(i) / 10.0
				pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * alcance)
			draw_colored_polygon(pontos, branco)
		T.SimboloDaltonismo.HEXAGONO:
			_poligono_simbolo(centro, raio, 6, 0.0, branco, traco)
		T.SimboloDaltonismo.CRUZ:
			var braco: float = raio * 0.38
			draw_rect(Rect2(centro - Vector2(braco, raio), Vector2(braco * 2.0, raio * 2.0)), branco)
			draw_rect(Rect2(centro - Vector2(raio, braco), Vector2(raio * 2.0, braco * 2.0)), branco)
		T.SimboloDaltonismo.MEIA_LUA:
			draw_circle(centro, raio, branco)
			draw_circle(centro + Vector2(raio * 0.5, 0.0), raio * 0.75, traco)


func _poligono_simbolo(
	centro: Vector2,
	raio: float,
	lados: int,
	rotacao: float,
	cor: Color,
	traco: Color,
) -> void:
	var pontos: PackedVector2Array = PackedVector2Array()
	for i: int in lados:
		var angulo: float = rotacao + TAU * float(i) / float(lados)
		pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * raio)
	draw_colored_polygon(pontos, cor)
	var contorno: PackedVector2Array = pontos.duplicate()
	contorno.append(pontos[0])
	draw_polyline(contorno, traco, 1.2)


func _desenhar_olhos(cobra: SnakeModel, raio: float) -> void:
	var frente: Vector2 = cobra.direcao if cobra.direcao != Vector2.ZERO else Vector2.RIGHT
	var lado: Vector2 = frente.orthogonal()
	var raio_olho: float = raio * 0.28
	for sinal: float in [-1.0, 1.0]:
		var centro: Vector2 = cobra.posicao + frente * raio * 0.45 + lado * sinal * raio * 0.38
		draw_circle(centro, raio_olho, T.COR_SIMBOLO_DALTONISMO)
		draw_circle(centro + frente * raio_olho * 0.35, raio_olho * 0.5, T.COR_ARENA_FUNDO)


## Amostra o CORPO DO DOMÍNIO (docs §2.7 — o que se vê é o que colide) no
## espaçamento visual dos segmentos.
func _pontos_do_corpo(cobra: SnakeModel) -> PackedVector2Array:
	var pontos: PackedVector2Array = PackedVector2Array()
	var corpo: PackedVector2Array = cobra.corpo
	var espaco: float = cobra.raio() * ESPACO_SEGMENTO
	var acumulado: float = 0.0
	var proximo_em: float = espaco
	for i: int in range(1, corpo.size()):
		acumulado += corpo[i - 1].distance_to(corpo[i])
		if acumulado >= proximo_em:
			pontos.append(corpo[i])
			proximo_em += espaco
			if pontos.size() >= MAX_SEGMENTOS:
				break
	return pontos
