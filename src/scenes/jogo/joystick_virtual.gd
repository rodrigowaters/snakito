class_name JoystickVirtual
extends Control
## Joystick virtual flutuante: a base aparece onde o dedo toca, o polegar
## arrasta para apontar. Também aceita mouse (desenvolvimento no desktop).
## Expõe só `direcao()` — quem move a cobra é o GameEngine.

const T := preload("res://src/ui/theme/tokens.gd")

## Raio da base (área morta pequena + curso do polegar) e do botão.
const RAIO_BASE_JOYSTICK: float = float(T.TOQUE_HEROI)
const RAIO_BOTAO_JOYSTICK: float = float(T.TOQUE_MIN) * 0.5
## Fração do curso abaixo da qual o input é ignorado (área morta).
const AREA_MORTA: float = 0.2

var _ativo: bool = false
var _centro: Vector2 = Vector2.ZERO
var _ponta: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Direção apontada (unitária) ou Vector2.ZERO se solto/na área morta.
func direcao() -> Vector2:
	if not _ativo:
		return Vector2.ZERO
	var curso: Vector2 = _ponta - _centro
	if curso.length() < RAIO_BASE_JOYSTICK * AREA_MORTA:
		return Vector2.ZERO
	return curso.normalized()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		var toque: InputEventScreenTouch = evento
		_definir(toque.pressed, toque.position)
	elif evento is InputEventScreenDrag:
		var arrasto: InputEventScreenDrag = evento
		if _ativo:
			_ponta = arrasto.position
			queue_redraw()
	elif evento is InputEventMouseButton:
		var clique: InputEventMouseButton = evento
		if clique.button_index == MOUSE_BUTTON_LEFT:
			_definir(clique.pressed, clique.position)
	elif evento is InputEventMouseMotion and _ativo:
		var movimento: InputEventMouseMotion = evento
		_ponta = movimento.position
		queue_redraw()


func _definir(pressionado: bool, posicao: Vector2) -> void:
	_ativo = pressionado
	if pressionado:
		_centro = posicao
		_ponta = posicao
	queue_redraw()


func _draw() -> void:
	if not _ativo:
		return
	# Base de vidro + anel, botão sólido — mesma linguagem do design system.
	draw_circle(_centro, RAIO_BASE_JOYSTICK, T.COR_SUPERFICIE_VIDRO)
	draw_arc(_centro, RAIO_BASE_JOYSTICK, 0.0, TAU, 48,
		T.COR_SUPERFICIE_VIDRO_BORDA, float(T.BORDA_DESTAQUE))
	var curso: Vector2 = _ponta - _centro
	var limite: float = RAIO_BASE_JOYSTICK - RAIO_BOTAO_JOYSTICK * 0.5
	var botao: Vector2 = _centro + curso.limit_length(limite)
	draw_circle(botao, RAIO_BOTAO_JOYSTICK, Color(T.COR_TEXTO_PRIMARIO, 0.85))
