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

var motor: GameEngine
var render: ArenaRender
var camera: Camera2D
var hud: Hud


func _ready() -> void:
	motor = GameEngine.new(Sessao.config_para_jogar())

	render = ArenaRender.new()
	render.motor = motor
	add_child(render)

	camera = Camera2D.new()
	camera.position = motor.jogador().posicao
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	hud.sair_pedido.connect(_sair_para_home)
	add_child(hud)
	hud.atualizar(motor)


func _physics_process(delta: float) -> void:
	if motor.estado == GameEngine.Estado.ENCERRADA:
		Sessao.ultimo_motor = motor
		get_tree().change_scene_to_file(CENA_RESULTADO)
		return

	motor.avancar(_direcao_do_input())
	render.registrar_tick()
	hud.atualizar(motor)
	_seguir_jogador(delta)


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
