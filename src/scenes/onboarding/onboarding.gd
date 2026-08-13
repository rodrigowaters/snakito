class_name Onboarding
extends Node2D
## Onboarding SEM TEXTO (docs §8): ~30s, 4 passos, sempre pulável.
## Mostra em vez de contar — vinhetas com o GameEngine REAL em piloto
## automático e bots honestos, para o que se aprende aqui ser exatamente o
## que acontece na arena:
##   1. comer comida → crescer (pulso + pontos)
##   2. devorar uma cobra menor (perseguição com turbo → confete)
##   3. ser devorado por uma maior (game over suave, véu acolhedor)
##   4. escolher a dificuldade do Arcade — dois cards DESENHADOS
##      (arena tranquila × arena cheia), toque escolhe.
## Nenhuma regra de jogo aqui (regra dura #1): o motor manda, a cena mostra.

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_HOME: String = "res://src/ui/home/home.tscn"

enum Passo { COMER, DEVORAR, SER_DEVORADO, ESCOLHA }

## Mesmo enquadramento do jogo — o tutorial não pode mentir a escala.
const ZOOM: float = 1.6
## Teto de duração por vinheta: se algo improvável travar a coreografia,
## o passo avança sozinho — tutorial preso é pior que tutorial imperfeito.
const TEMPO_MAX_PASSO: float = 12.0
## Comidas da vinheta 1 (tamanho 4 no fim — devora a vítima de tamanho 1).
const COMIDAS_ALVO: int = 3
## Distâncias de spawn coreografadas (unidades de mundo).
const DIST_COMIDA: float = 150.0
const DIST_VITIMA: float = 260.0
## DENTRO da visão do predador (caçador 25 enxerga 370) — bot honesto não
## persegue o que não vê; a 420 ele vagava e a vinheta caía no fallback.
const DIST_PREDADOR: float = 300.0
## Respiro entre vinhetas — sem ele a próxima lição atropela a anterior.
const PAUSA_ENTRE_PASSOS: float = 0.7

var motor: GameEngine
var render: ArenaRender
var efeitos: Efeitos
var camera: Camera2D

var passo: Passo = Passo.COMER
var _tempo_passo: float = 0.0
var _vitima: SnakeModel = null
var _predador: SnakeModel = null
var _encerrando_vinheta: bool = false
# Estado do tick anterior (mini-detector de eventos, como em jogo.gd).
var _comidas_previas: int = 0
var _abates_previos: int = 0
var _vivas_previas: Dictionary[int, bool] = {}

var _ui: CanvasLayer
var _veu: ColorRect
var _pontinhos: Control
var _fantasma: Control
var _cards: Control


func _ready() -> void:
	# Arena mínima e vazia: cada vinheta põe em cena só o que ensina.
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.semente = 8
	# Grande o bastante para as perseguições não empurrarem tudo para a
	# parede; pequena o bastante para a parede aparecer (ela também ensina).
	config.tamanho_arena = Vector2(1300.0, 1300.0)
	config.duracao_seg = 120
	config.qtd_comida = 0
	config.fazendeiros = 0
	config.cacadores = 0
	config.oportunistas = 0
	config.aplicar_buffs = false
	config.vitoria_por_dominio = false  # devorar a figura da vinheta não "vence"
	motor = GameEngine.new(config)

	render = ArenaRender.new()
	render.motor = motor
	render.mostrar_badges = false  # tutorial sem texto (docs §8)
	add_child(render)
	efeitos = Efeitos.new()
	add_child(efeitos)
	camera = Camera2D.new()
	camera.position = motor.jogador().posicao
	camera.zoom = Vector2(ZOOM, ZOOM)
	add_child(camera)
	camera.make_current()

	_montar_ui()
	render.registrar_tick()
	_memorizar_estado()
	_espalhar_comida()


func _physics_process(delta: float) -> void:
	if passo == Passo.ESCOLHA or _encerrando_vinheta:
		return
	_tempo_passo += delta
	if _tempo_passo > TEMPO_MAX_PASSO:
		_avancar_passo()
		return

	motor.avancar(_autopiloto(), passo == Passo.DEVORAR)
	_processar_eventos()
	render.registrar_tick()
	var jogador: SnakeModel = motor.jogador()
	camera.position = camera.position.lerp(jogador.posicao, minf(1.0, 6.0 * delta))

	match passo:
		Passo.COMER:
			if jogador.comidas >= COMIDAS_ALVO:
				_avancar_passo()
			elif motor.arena.comidas.is_empty():
				_espalhar_comida()
		Passo.DEVORAR:
			if jogador.abates >= 1:
				_avancar_passo()
		Passo.SER_DEVORADO:
			if not jogador.viva:
				_game_over_suave()


## Direção da cobra do jogador nesta vinheta (coreografia, não input).
func _autopiloto() -> Vector2:
	var jogador: SnakeModel = motor.jogador()
	match passo:
		Passo.COMER:
			if not motor.arena.comidas.is_empty():
				return (motor.arena.comidas[0] - jogador.posicao).normalized()
		Passo.DEVORAR:
			if _vitima != null and _vitima.viva:
				return (_vitima.posicao - jogador.posicao).normalized()
		Passo.SER_DEVORADO:
			if _predador != null and _predador.viva:
				# Foge SEM turbo — o predador com turbo alcança: a lição é
				# exatamente "cobra 10% maior devora em um toque". O viés
				# para o centro evita a fuga reta que pregava na parede.
				var fuga: Vector2 = (jogador.posicao - _predador.posicao).normalized()
				var centro: Vector2 = \
					(motor.arena.tamanho * 0.5 - jogador.posicao).normalized()
				return (fuga * 0.65 + centro * 0.35).normalized()
	return Vector2.ZERO


func _avancar_passo() -> void:
	_tempo_passo = 0.0
	_encerrando_vinheta = true
	await get_tree().create_timer(PAUSA_ENTRE_PASSOS).timeout
	_encerrando_vinheta = false
	match passo:
		Passo.COMER:
			passo = Passo.DEVORAR
			_entrar_vitima()
		Passo.DEVORAR:
			passo = Passo.SER_DEVORADO
			_entrar_predador()
		Passo.SER_DEVORADO:
			passo = Passo.ESCOLHA
			# A arena já ensinou o que tinha para ensinar — a escolha fica
			# só com o véu de fundo (cards translúcidos vazavam o mundo).
			render.visible = false
			efeitos.visible = false
			_cards.visible = true
	_pontinhos.queue_redraw()


# ------------------------------------------------------------- coreografia

## Uma comida por vez, sempre à frente do rumo atual — o olho segue a cobra.
func _espalhar_comida() -> void:
	var jogador: SnakeModel = motor.jogador()
	var frente: Vector2 = jogador.direcao if jogador.direcao != Vector2.ZERO else Vector2.RIGHT
	# Leve desvio alternado para a trajetória curvar (mostra que a cobra vira).
	var desvio: float = 0.5 if motor.jogador().comidas % 2 == 0 else -0.5
	var ponto: Vector2 = jogador.posicao + frente.rotated(desvio) * DIST_COMIDA
	motor.arena.comidas.append(_dentro_da_arena(ponto))


## Vinheta 2: fazendeiro de tamanho 1, honesto — vê a ameaça e foge; sem
## vantagem de turbo (multiplicador 1.0) para a perseguição durar ~2s.
func _entrar_vitima() -> void:
	var jogador: SnakeModel = motor.jogador()
	_vitima = SnakeModel.new(
		100, SnakeModel.Personalidade.FAZENDEIRO,
		_dentro_da_arena(jogador.posicao + jogador.direcao * DIST_VITIMA))
	_vitima.multiplicador_turbo = 1.0
	motor.arena.adicionar_cobra(_vitima)
	_vivas_previas[_vitima.id] = true


## Vinheta 3: caçador grande nasce atrás — a IA honesta dele faz o resto
## (enxerga, alcança com turbo e devora o jogador sem turbo).
func _entrar_predador() -> void:
	var jogador: SnakeModel = motor.jogador()
	var atras: Vector2 = -jogador.direcao if jogador.direcao != Vector2.ZERO else Vector2.LEFT
	_predador = SnakeModel.new(
		101, SnakeModel.Personalidade.CACADOR,
		_dentro_da_arena(jogador.posicao + atras * DIST_PREDADOR), 25)
	_predador.agressividade = 1.0
	motor.arena.adicionar_cobra(_predador)
	_vivas_previas[_predador.id] = true


## Game over acolhedor (docs §8/11c): véu suave + a fantasminha do design
## subindo serena — sem tela de derrota.
func _game_over_suave() -> void:
	_encerrando_vinheta = true
	var tween: Tween = create_tween()
	tween.tween_property(_veu, "color:a", 0.65, 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(_fantasma, "modulate:a", 1.0, 0.7) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_fantasma, "position:y",
		_fantasma.position.y - 24.0, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_callback(func() -> void:
		_fantasma.visible = false
		_encerrando_vinheta = false
		_avancar_passo())


func _dentro_da_arena(ponto: Vector2) -> Vector2:
	var margem: float = 60.0
	return Vector2(
		clampf(ponto.x, margem, motor.arena.tamanho.x - margem),
		clampf(ponto.y, margem, motor.arena.tamanho.y - margem))


## Mesmos feedbacks do §7 usados no jogo — o tutorial ensina a linguagem.
func _processar_eventos() -> void:
	var jogador: SnakeModel = motor.jogador()
	if jogador.comidas > _comidas_previas:
		render.pulsar_crescimento(jogador.id)
		efeitos.pontos_flutuantes(
			jogador.posicao,
			(jogador.comidas - _comidas_previas) * GameEngine.PONTOS_COMIDA)
	if jogador.abates > _abates_previos:
		render.pulsar_crescimento(jogador.id)
	for cobra: SnakeModel in motor.arena.cobras:
		if not cobra.viva and _vivas_previas.get(cobra.id, false):
			efeitos.confete(cobra.posicao, ArenaRender.cor_de(cobra))
			if cobra.eh_jogador() and ProgressoLocal.vibracao():
				Input.vibrate_handheld(200)  # suave — metade da morte real
	_memorizar_estado()


func _memorizar_estado() -> void:
	_comidas_previas = motor.jogador().comidas
	_abates_previos = motor.jogador().abates
	for cobra: SnakeModel in motor.arena.cobras:
		_vivas_previas[cobra.id] = cobra.viva


# ---------------------------------------------------------------------- UI

func _montar_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)

	# Véu do game over suave (e fundo da escolha final). Tom bem mais escuro
	# que a arena — na mesma cor o escurecimento era imperceptível.
	_veu = ColorRect.new()
	_veu.color = Color(T.COR_APP_FUNDO_FIM.darkened(0.6), 0.0)
	_veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_veu)

	# Pular (»): sempre disponível — respeito por quem já sabe jogar.
	var pular: Button = Button.new()
	pular.text = "»"
	pular.theme_type_variation = &"BotaoSecundario"
	pular.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pular.position = Vector2(-72.0 - float(T.ESP_MD), float(T.ESP_MD))
	pular.custom_minimum_size = Vector2(72.0, float(T.TOQUE_PADRAO))
	pular.pressed.connect(_concluir.bind(ProgressoLocal.dificuldade()))
	_ui.add_child(pular)

	# Progresso do blueprint 11: passo ativo é uma PÍLULA verde alongada;
	# os demais, bolinhas apagadas (sem números, sem texto).
	_pontinhos = Control.new()
	_pontinhos.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pontinhos.position += Vector2(0.0, -float(T.ESP_XL))
	_pontinhos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pontinhos.draw.connect(func() -> void:
		var x: float = -46.0  # largura total ≈ 92 (3 bolinhas + pílula + vãos)
		for i: int in 4:
			if i == int(passo):
				_pontinhos.draw_colored_polygon(
					DesenhoUi.poligono_arredondado(
						Rect2(x, -3.5, 20.0, 7.0), 3.5), T.CORES_COBRA_BASE[0])
				x += 26.0
			else:
				_pontinhos.draw_circle(Vector2(x + 3.5, 0.0), 3.5,
					Color(T.COR_TEXTO_PRIMARIO, 0.2))
				x += 13.0)
	_ui.add_child(_pontinhos)

	# Fantasminha do 11c — aparece no game over suave da vinheta 3.
	_fantasma = Control.new()
	_fantasma.set_anchors_preset(Control.PRESET_CENTER)
	_fantasma.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_fantasma.grow_vertical = Control.GROW_DIRECTION_BOTH
	_fantasma.custom_minimum_size = Vector2(180.0, 110.0)
	_fantasma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fantasma.draw.connect(func() -> void:
		DesenhoUi.fantasma(_fantasma, _fantasma.size))
	_fantasma.modulate.a = 0.0
	_ui.add_child(_fantasma)

	_montar_cards_escolha()


## Passo 4 (blueprint 11d): dificuldade escolhida OLHANDO, não lendo — dois
## cards EMPILHADOS de mini-arena: a tranquila azulada com borda verde e
## selo ✓ (recomendada), a cheia avermelhada de perigo. Toque escolhe.
func _montar_cards_escolha() -> void:
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL + T.ESP_XL)
	margem.add_theme_constant_override("margin_bottom", T.ESP_2XL + T.ESP_MD)
	margem.visible = false
	_cards = margem
	_ui.add_child(margem)
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_SM)
	margem.add_child(pilha)
	pilha.add_child(_card_dificuldade(ProgressoLocal.Dificuldade.TRANQUILA))
	pilha.add_child(_card_dificuldade(ProgressoLocal.Dificuldade.CHEIA))


## Cobras/comidas das mini-arenas, em frações do card: (x, y, raio, cor).
const MINI_CALMA: Array = [
	[0.28, 0.55, 7.0, 0], [0.36, 0.50, 9.0, 0],
	[0.72, 0.68, 7.0, 1], [0.80, 0.64, 8.0, 1],
]
const MINI_CALMA_COMIDA: Array = [[0.62, 0.32]]
const MINI_CHEIA: Array = [
	[0.18, 0.28, 7.0, 2], [0.32, 0.52, 8.0, 3], [0.48, 0.24, 9.0, 1],
	[0.66, 0.46, 8.0, 5], [0.82, 0.28, 7.0, 6], [0.55, 0.76, 10.0, 4],
	[0.25, 0.80, 8.0, 7], [0.85, 0.74, 9.0, 0],
]
const MINI_CHEIA_COMIDA: Array = [[0.40, 0.38], [0.72, 0.64]]


func _card_dificuldade(dificuldade: ProgressoLocal.Dificuldade) -> Button:
	var calma: bool = dificuldade == ProgressoLocal.Dificuldade.TRANQUILA
	var card: Button = Button.new()
	card.flat = true
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.pressed.connect(_concluir.bind(dificuldade))
	card.draw.connect(func() -> void:
		var tamanho: Vector2 = card.size
		var raio_card: float = float(T.RAIO_BOTAO)
		# Fundo da mini-arena (11d: azulada calma × avermelhada de perigo).
		var fundo: Color = T.COR_VINHETA_CALMA if calma else T.COR_VINHETA_PERIGO
		card.draw_colored_polygon(DesenhoUi.poligono_arredondado(
			Rect2(Vector2.ZERO, tamanho), raio_card), fundo)
		# Grade interna na cor do clima.
		var grade: Color = Color(T.CORES_COBRA_BASE[1], 0.06) if calma \
			else Color(T.COR_COMIDA_COMUM, 0.07)
		var passo_grade: float = 22.0
		var gx: float = passo_grade
		while gx < tamanho.x:
			card.draw_line(Vector2(gx, 4.0), Vector2(gx, tamanho.y - 4.0), grade)
			gx += passo_grade
		var gy: float = passo_grade
		while gy < tamanho.y:
			card.draw_line(Vector2(4.0, gy), Vector2(tamanho.x - 4.0, gy), grade)
			gy += passo_grade
		# Borda: verde de recomendada na calma; vidro na cheia.
		var pontos_borda: PackedVector2Array = DesenhoUi.poligono_arredondado(
			Rect2(Vector2.ONE, tamanho - Vector2.ONE * 2.0), raio_card)
		pontos_borda.append(pontos_borda[0])
		card.draw_polyline(pontos_borda,
			T.CORES_COBRA_BASE[0] if calma else T.COR_SUPERFICIE_VIDRO_BORDA,
			2.5 if calma else 1.0, true)
		# Cobrinhas (corpo + cabeça com olhos) e comidas.
		var cobras: Array = MINI_CALMA if calma else MINI_CHEIA
		for c: Array in cobras:
			var pos: Vector2 = Vector2(c[0], c[1]) * tamanho
			var r: float = c[2]
			var cor: Color = T.CORES_COBRA_BASE[c[3]]
			card.draw_circle(pos + Vector2(-r * 1.4, r * 0.5), r * 0.75, Color(cor, 0.7))
			card.draw_circle(pos, r, cor)
			for lado: float in [-1.0, 1.0]:
				card.draw_circle(pos + Vector2(lado * r * 0.35, -r * 0.25),
					r * 0.22, T.COR_SIMBOLO_DALTONISMO)
		var comidas: Array = MINI_CALMA_COMIDA if calma else MINI_CHEIA_COMIDA
		for ponto: Array in comidas:
			card.draw_circle(Vector2(ponto[0], ponto[1]) * tamanho, 4.0,
				T.COR_COMIDA_COMUM)
		# Selo ✓ da recomendada (11d) no canto superior direito.
		if calma:
			var selo_centro: Vector2 = Vector2(tamanho.x - 25.0, 25.0)
			card.draw_circle(selo_centro, 15.0, T.CORES_COBRA_BASE[0])
			var v: Color = T.COR_TEXTO_SOBRE_PRIMARIO
			card.draw_line(selo_centro + Vector2(-6.0, 0.0),
				selo_centro + Vector2(-2.0, 5.0), v, 3.0)
			card.draw_line(selo_centro + Vector2(-2.0, 5.0),
				selo_centro + Vector2(6.0, -5.0), v, 3.0))
	return card


func _concluir(dificuldade: ProgressoLocal.Dificuldade) -> void:
	ProgressoLocal.definir_dificuldade(dificuldade)
	ProgressoLocal.marcar_onboarding_visto()
	get_tree().change_scene_to_file(CENA_HOME)
