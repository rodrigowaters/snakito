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
var _cards: CenterContainer


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


## Game over acolhedor (docs §8): confete + véu suave, sem tela de derrota.
func _game_over_suave() -> void:
	_encerrando_vinheta = true
	var tween: Tween = create_tween()
	tween.tween_property(_veu, "color:a", 0.65, 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void:
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
			if cobra.eh_jogador():
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

	# Progresso: 4 pontinhos (sem números, sem texto).
	_pontinhos = Control.new()
	_pontinhos.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pontinhos.position += Vector2(0.0, -float(T.ESP_XL))
	_pontinhos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pontinhos.draw.connect(func() -> void:
		for i: int in 4:
			var centro: Vector2 = Vector2((float(i) - 1.5) * 24.0, 0.0)
			if i == int(passo):
				_pontinhos.draw_circle(centro, 6.0, T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()])
			else:
				_pontinhos.draw_circle(centro, 4.0, Color(T.COR_SIMBOLO_DALTONISMO, 0.35)))
	_ui.add_child(_pontinhos)

	_montar_cards_escolha()


## Passo 4 (docs §8): dificuldade escolhida OLHANDO, não lendo — um card
## calmo com poucas cobras × um card cheio. O desenho é a informação.
func _montar_cards_escolha() -> void:
	_cards = CenterContainer.new()
	_cards.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cards.visible = false
	_ui.add_child(_cards)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_LG)
	_cards.add_child(linha)
	linha.add_child(_card_dificuldade(ProgressoLocal.Dificuldade.TRANQUILA))
	linha.add_child(_card_dificuldade(ProgressoLocal.Dificuldade.CHEIA))


func _card_dificuldade(dificuldade: ProgressoLocal.Dificuldade) -> Button:
	var card: Button = Button.new()
	card.theme_type_variation = &"BotaoSecundario"
	card.custom_minimum_size = Vector2(150.0, 150.0)
	card.pressed.connect(_concluir.bind(dificuldade))
	# Mini-arena desenhada por cima do botão: 3 cobrinhas calmas × 9 agitadas.
	card.draw.connect(func() -> void:
		var tamanho: Vector2 = card.size
		var pontos_tranquila: Array[Vector2] = [
			Vector2(0.30, 0.35), Vector2(0.65, 0.55), Vector2(0.45, 0.75)]
		var pontos_cheia: Array[Vector2] = [
			Vector2(0.22, 0.28), Vector2(0.50, 0.22), Vector2(0.78, 0.32),
			Vector2(0.30, 0.50), Vector2(0.62, 0.52), Vector2(0.82, 0.62),
			Vector2(0.24, 0.72), Vector2(0.48, 0.80), Vector2(0.70, 0.78)]
		var calma: bool = dificuldade == ProgressoLocal.Dificuldade.TRANQUILA
		var pontos: Array[Vector2] = pontos_tranquila if calma else pontos_cheia
		var skin: int = ProgressoLocal.skin_equipada()
		for i: int in pontos.size():
			# Bots nunca usam a cor do jogador — mesma regra da arena.
			var indice: int = i % (T.CORES_COBRA_BASE.size() - 1)
			if indice >= skin:
				indice += 1
			card.draw_circle(pontos[i] * tamanho, 9.0 if calma else 7.0,
				T.CORES_COBRA_BASE[indice])
		# A cobrinha do jogador aparece nos dois — "você está aqui".
		card.draw_circle(Vector2(0.5, 0.62 if calma else 0.65) * tamanho, 10.0,
			T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]))
	return card


func _concluir(dificuldade: ProgressoLocal.Dificuldade) -> void:
	ProgressoLocal.definir_dificuldade(dificuldade)
	ProgressoLocal.marcar_onboarding_visto()
	get_tree().change_scene_to_file(CENA_HOME)
