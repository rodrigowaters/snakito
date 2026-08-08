class_name Jogo
extends Node2D
## Cena da partida: dona do GameEngine. A cada tick de física, entrega o input
## ao motor e manda o render/HUD refletirem o novo estado. NENHUMA regra de
## jogo aqui (regra dura #1).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_RESULTADO: String = "res://src/ui/resultado/resultado.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"

## Suavização da câmera (posição) e do zoom.
const CAMERA_SUAVIZACAO: float = 6.0
## Zoom nunca aproxima além de 1:1 nem afasta além deste fator.
const ZOOM_MIN: float = 0.55
## Pausa dramática entre o fim da partida e a tela de resultado.
const DELAY_RESULTADO_MORTE: float = 1.2
const DELAY_RESULTADO_TEMPO: float = 0.6
## Vibração na morte, em ms (docs §7; no desktop é no-op).
const VIBRACAO_MORTE_MS: int = 500

var motor: GameEngine
var render: ArenaRender
var camera: Camera2D
var hud: Hud
var efeitos: Efeitos

var _transicionando: bool = false
# Estado do tick anterior, por id — para detectar eventos (comer/abate/morte)
# sem sujar o domínio com sinais.
var _comidas_previas: Dictionary[int, int] = {}
var _pontos_previos: Dictionary[int, int] = {}
var _abates_previos: Dictionary[int, int] = {}
var _vivas_previas: Dictionary[int, bool] = {}


func _ready() -> void:
	motor = GameEngine.new(Sessao.config_para_jogar())

	render = ArenaRender.new()
	render.motor = motor
	add_child(render)

	efeitos = Efeitos.new()
	add_child(efeitos)

	camera = Camera2D.new()
	camera.position = motor.jogador().posicao
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	hud.sair_pedido.connect(_sair_para_home)
	add_child(hud)
	hud.atualizar(motor)
	_memorizar_estado()


func _physics_process(delta: float) -> void:
	if _transicionando:
		return
	if motor.estado == GameEngine.Estado.ENCERRADA:
		_transicionando = true
		_ir_para_resultado()
		return

	motor.avancar(_direcao_do_input(), hud.turbo_desejado())
	_processar_eventos()
	render.registrar_tick()
	hud.atualizar(motor)
	_seguir_jogador(delta)

	# Desafio ativo: resolver (meta atingida ou falha) encerra a partida já.
	if Sessao.regras_desafio != null \
			and Sessao.regras_desafio.avaliar(motor) != ChallengeRules.Estado.EM_ANDAMENTO:
		_transicionando = true
		_ir_para_resultado()


## Compara o estado com o tick anterior e dispara os feedbacks do docs §7.
func _processar_eventos() -> void:
	for cobra: SnakeModel in motor.arena.cobras:
		# Comeu → pulso de crescimento; jogador também vê os pontos subirem.
		var comidas_novas: int = cobra.comidas - _comidas_previas.get(cobra.id, cobra.comidas)
		if comidas_novas > 0 and cobra.viva:
			render.pulsar_crescimento(cobra.id)
			if cobra.eh_jogador():
				efeitos.pontos_flutuantes(
					cobra.posicao, comidas_novas * GameEngine.PONTOS_COMIDA)
		# Abateu (só jogador ganha rótulo — 30 bots geram spam).
		if cobra.eh_jogador() and cobra.abates > _abates_previos.get(cobra.id, cobra.abates):
			var delta_pontos: int = cobra.pontos - _pontos_previos.get(cobra.id, cobra.pontos)
			efeitos.pontos_flutuantes(
				cobra.posicao, delta_pontos - comidas_novas * GameEngine.PONTOS_COMIDA)
			render.pulsar_crescimento(cobra.id)
		# Morreu neste tick → confete na cor da vítima; jogador ganha flash+háptica.
		if not cobra.viva and _vivas_previas.get(cobra.id, false):
			efeitos.confete(cobra.posicao, ArenaRender.cor_de(cobra))
			if cobra.eh_jogador():
				hud.flash_morte()
				Input.vibrate_handheld(VIBRACAO_MORTE_MS)
	_memorizar_estado()


func _memorizar_estado() -> void:
	for cobra: SnakeModel in motor.arena.cobras:
		_comidas_previas[cobra.id] = cobra.comidas
		_pontos_previos[cobra.id] = cobra.pontos
		_abates_previos[cobra.id] = cobra.abates
		_vivas_previas[cobra.id] = cobra.viva


func _ir_para_resultado() -> void:
	Sessao.ultimo_motor = motor
	var espera: float = DELAY_RESULTADO_TEMPO if motor.jogador().viva else DELAY_RESULTADO_MORTE
	await get_tree().create_timer(espera).timeout
	get_tree().change_scene_to_file(CENA_RESULTADO)


## Joystick tem prioridade; teclado (setas/WASD via ações ui_*) serve ao
## desenvolvimento no desktop.
func _direcao_do_input() -> Vector2:
	var direcao: Vector2 = hud.joystick.direcao()
	if direcao == Vector2.ZERO:
		direcao = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	return direcao


## Câmera segue o jogador; o zoom abre conforme a visão cresce — é a leitura
## de render do "quanto maior, maior o raio de visão" (docs §2.2).
func _seguir_jogador(delta: float) -> void:
	var jogador: SnakeModel = motor.jogador()
	camera.position = camera.position.lerp(jogador.posicao, minf(1.0, CAMERA_SUAVIZACAO * delta))
	var alvo_zoom: float = clampf(SnakeModel.VISAO_BASE / jogador.raio_visao(), ZOOM_MIN, 1.0)
	var zoom_atual: float = lerpf(camera.zoom.x, alvo_zoom, minf(1.0, CAMERA_SUAVIZACAO * delta))
	camera.zoom = Vector2(zoom_atual, zoom_atual)


func _sair_para_home() -> void:
	get_tree().change_scene_to_file(CENA_HOME)
