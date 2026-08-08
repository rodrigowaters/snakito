class_name Hud
extends CanvasLayer
## HUD da partida (docs §4.2): pontuação, tempo restante, posição e tamanho,
## + botão de pausa e modal de pausa. Constrói a árvore em código consumindo
## SOMENTE variações do Theme — nenhum valor visual literal.

const T := preload("res://src/ui/theme/tokens.gd")

## Últimos segundos em que o timer troca para a cor de alerta.
const LIMIAR_ALERTA_SEG: int = 30

signal sair_pedido

var joystick: JoystickVirtual

var _pontos: Label
var _tempo: Label
var _posicao: Label
var _tamanho: Label
var _modal_pausa: Control


func _ready() -> void:
	# O HUD continua processando com a árvore pausada (botões do modal).
	process_mode = Node.PROCESS_MODE_ALWAYS

	joystick = JoystickVirtual.new()
	add_child(joystick)

	_montar_barra_topo()
	_montar_modal_pausa()


func atualizar(motor: GameEngine) -> void:
	var jogador: SnakeModel = motor.jogador()
	_pontos.text = str(jogador.pontos)
	var restante: int = maxi(0, motor.config.duracao_seg - int(motor.segundos_decorridos()))
	@warning_ignore("integer_division")
	_tempo.text = "%d:%02d" % [restante / 60, restante % 60]
	_tempo.theme_type_variation = &"TextoAlerta" if restante <= LIMIAR_ALERTA_SEG else &"TextoCorpo"
	_posicao.text = "%dº/%d" % [motor.posicao_no_ranking(jogador), motor.arena.cobras.size()]
	_tamanho.text = "×%d" % jogador.tamanho


func _montar_barra_topo() -> void:
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margem.add_theme_constant_override("margin_left", T.ESP_MD)
	margem.add_theme_constant_override("margin_right", T.ESP_MD)
	margem.add_theme_constant_override("margin_top", T.ESP_SM)
	add_child(margem)

	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"HudPainel"
	margem.add_child(painel)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_MD)
	painel.add_child(linha)

	_pontos = _rotulo(linha, &"TituloMd")
	_tamanho = _rotulo(linha, &"TextoSecundario")
	var espaco: Control = Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(espaco)
	_tempo = _rotulo(linha, &"TextoCorpo")
	_posicao = _rotulo(linha, &"TextoSecundario")

	var pausa: Button = Button.new()
	pausa.text = "⏸"
	pausa.theme_type_variation = &"BotaoSecundario"
	pausa.pressed.connect(_abrir_pausa)
	linha.add_child(pausa)


func _rotulo(pai: Container, variacao: StringName) -> Label:
	var rotulo: Label = Label.new()
	rotulo.theme_type_variation = variacao
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pai.add_child(rotulo)
	return rotulo


func _montar_modal_pausa() -> void:
	_modal_pausa = Control.new()
	_modal_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_pausa.visible = false
	add_child(_modal_pausa)

	# Véu escurecendo a arena atrás do modal.
	var veu: ColorRect = ColorRect.new()
	veu.color = T.COR_SUPERFICIE_HUD
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_pausa.add_child(veu)

	var centro: CenterContainer = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_pausa.add_child(centro)

	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"ModalPainel"
	centro.add_child(painel)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_MD)
	painel.add_child(coluna)

	var titulo: Label = Label.new()
	titulo.text = "Pausado"
	titulo.theme_type_variation = &"TituloLg"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)

	var continuar: Button = Button.new()
	continuar.text = "Continuar"
	continuar.theme_type_variation = &"BotaoPrimario"
	continuar.pressed.connect(_fechar_pausa)
	coluna.add_child(continuar)

	var sair: Button = Button.new()
	sair.text = "Sair da partida"
	sair.theme_type_variation = &"BotaoDestrutivo"
	sair.pressed.connect(func() -> void:
		_fechar_pausa()
		sair_pedido.emit())
	coluna.add_child(sair)


func _abrir_pausa() -> void:
	_modal_pausa.visible = true
	get_tree().paused = true


func _fechar_pausa() -> void:
	_modal_pausa.visible = false
	get_tree().paused = false
