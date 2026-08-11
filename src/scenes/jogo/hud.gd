class_name Hud
extends CanvasLayer
## HUD da partida (docs §4.2): pontuação, tempo restante, posição e tamanho,
## + botão de pausa e modal de pausa. Constrói a árvore em código consumindo
## SOMENTE variações do Theme — nenhum valor visual literal.

const T := preload("res://src/ui/theme/tokens.gd")

## Últimos segundos em que o timer troca para a cor de alerta.
const LIMIAR_ALERTA_SEG: int = 30

## Duração e alpha de pico do flash vermelho de morte (docs §7).
const FLASH_MORTE_DURACAO: float = 0.6
const FLASH_MORTE_ALFA: float = 0.45

signal sair_pedido

var joystick: JoystickVirtual

var _pontos: Label
var _tempo: Label
var _posicao: Label
var _tamanho: Label
var _modal_pausa: Control
var _flash: ColorRect
var _energia: ProgressBar
var _turbo_pressionado: bool = false
var _meta: Label
var _convite: Label
var _minimapa: Minimapa


func _ready() -> void:
	# O HUD continua processando com a árvore pausada (botões do modal).
	process_mode = Node.PROCESS_MODE_ALWAYS

	joystick = JoystickVirtual.new()
	add_child(joystick)

	_montar_barra_topo()
	_montar_turbo()
	_montar_flash()
	_montar_convite_de_inicio()
	_montar_modal_pausa()


## Convite "toque para começar" — some no primeiro toque.
func _montar_convite_de_inicio() -> void:
	_convite = Label.new()
	_convite.text = "Toque e arraste\npara começar"
	_convite.theme_type_variation = &"TituloLg"
	_convite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_convite.set_anchors_preset(Control.PRESET_CENTER)
	_convite.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_convite.grow_vertical = Control.GROW_DIRECTION_BOTH
	_convite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_convite)
	# Pulso suave para chamar o olho sem gritar.
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_convite, "modulate:a", 0.45, 0.8)
	tween.tween_property(_convite, "modulate:a", 1.0, 0.8)


func esconder_convite_de_inicio() -> void:
	_convite.visible = false


## O jogador está segurando o turbo? (botão na tela ou Shift no desktop)
func turbo_desejado() -> bool:
	return _turbo_pressionado or Input.is_key_pressed(KEY_SHIFT)


## Flash vermelho de morte + decaimento (docs §7: "flash vermelho, som suave").
func flash_morte() -> void:
	_flash.color = Color(T.COR_PERIGO_ACAO, FLASH_MORTE_ALFA)
	var tween: Tween = create_tween()
	tween.tween_property(_flash, "color:a", 0.0, FLASH_MORTE_DURACAO) \
		.set_ease(Tween.EASE_OUT)


## Botão de turbo (segurar = acelerar) + barra de energia, canto inferior
## direito — oposto ao polegar do joystick (docs §2.6/§4.2).
func _montar_turbo() -> void:
	var canto: MarginContainer = MarginContainer.new()
	canto.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	canto.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	canto.grow_vertical = Control.GROW_DIRECTION_BEGIN
	canto.add_theme_constant_override("margin_right", T.ESP_LG)
	canto.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(canto)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_XS)
	canto.add_child(coluna)

	_energia = ProgressBar.new()
	_energia.max_value = SnakeModel.ENERGIA_MAX
	_energia.value = SnakeModel.ENERGIA_MAX
	_energia.show_percentage = false
	_energia.custom_minimum_size = Vector2(float(T.TOQUE_HEROI), float(T.ESP_XS))
	coluna.add_child(_energia)

	var turbo: Button = Button.new()
	turbo.text = "⚡"
	turbo.theme_type_variation = &"BotaoPrimario"
	turbo.custom_minimum_size = Vector2(float(T.TOQUE_HEROI), float(T.TOQUE_HEROI))
	turbo.button_down.connect(func() -> void: _turbo_pressionado = true)
	turbo.button_up.connect(func() -> void: _turbo_pressionado = false)
	coluna.add_child(turbo)


func _montar_flash() -> void:
	_flash = ColorRect.new()
	_flash.color = Color(T.COR_PERIGO_ACAO, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func atualizar(motor: GameEngine) -> void:
	var jogador: SnakeModel = motor.jogador()
	_pontos.text = formatar_milhar(jogador.pontos)
	var restante: int = maxi(0, motor.config.duracao_seg - int(motor.segundos_decorridos()))
	@warning_ignore("integer_division")
	_tempo.text = "%d:%02d" % [restante / 60, restante % 60]
	# Timer amarelo por padrão (blueprint 04); vermelho na reta final.
	_tempo.add_theme_color_override("font_color",
		T.COR_PERIGO_ACAO if restante <= LIMIAR_ALERTA_SEG else T.COR_ALERTA)
	_posicao.text = "%dº DE %d" % [motor.posicao_no_ranking(jogador), motor.arena.cobras.size()]
	_tamanho.text = "TAM. %d" % jogador.nivel  # nível: não desce com corte (§2.7)
	_energia.value = jogador.energia
	_minimapa.atualizar(motor)
	# Progresso do desafio ativo (Arcade não mostra nada).
	var regras: ChallengeRules = Sessao.regras_desafio
	_meta.visible = regras != null
	if regras != null:
		_meta.text = "META %d/%d" % [regras.progresso_atual(motor), regras.progresso_meta()]


## Barra única do blueprint 04: [pontos / POSIÇÃO] [tempo / TAM.] no
## space-between com [minimapa 48 + pausa 48] à direita.
func _montar_barra_topo() -> void:
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margem.add_theme_constant_override("margin_left", T.ESP_SM)
	margem.add_theme_constant_override("margin_right", T.ESP_SM)
	margem.add_theme_constant_override("margin_top", T.ESP_SM)
	add_child(margem)

	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"HudPainel"
	margem.add_child(painel)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_MD)
	painel.add_child(linha)

	var col_esquerda: VBoxContainer = VBoxContainer.new()
	col_esquerda.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_child(col_esquerda)
	_pontos = _rotulo(col_esquerda, &"TituloMd")
	_posicao = _rotulo(col_esquerda, &"TextoLegenda")

	linha.add_child(_espaco_flexivel())

	var col_centro: VBoxContainer = VBoxContainer.new()
	col_centro.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_child(col_centro)
	_tempo = _rotulo(col_centro, &"TituloMd")
	_tempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tamanho = _rotulo(col_centro, &"TextoLegenda")
	_tamanho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta = _rotulo(col_centro, &"TextoAlerta")
	_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta.visible = false

	linha.add_child(_espaco_flexivel())

	_minimapa = Minimapa.new(float(T.TOQUE_MIN))  # chip de 48 na barra (04)
	_minimapa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(_minimapa)

	var pausa: Button = Button.new()
	pausa.text = "❚❚"
	pausa.theme_type_variation = &"ChipQuadrado"
	pausa.custom_minimum_size = Vector2(float(T.TOQUE_MIN), float(T.TOQUE_MIN))
	pausa.pressed.connect(_abrir_pausa)
	linha.add_child(pausa)


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return espaco


func _rotulo(pai: Container, variacao: StringName) -> Label:
	var rotulo: Label = Label.new()
	rotulo.theme_type_variation = variacao
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pai.add_child(rotulo)
	return rotulo


## 2480 → "2.480" (separador de milhar pt-BR, como no design).
static func formatar_milhar(valor: int) -> String:
	var texto: String = str(valor)
	var saida: String = ""
	for i: int in texto.length():
		if i > 0 and (texto.length() - i) % 3 == 0:
			saida += "."
		saida += texto[i]
	return saida


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
