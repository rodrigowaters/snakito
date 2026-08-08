class_name Resultado
extends Control
## Tela pós-partida (docs §4.3): posição final, breakdown de pontos
## (comida + abates + sobrevivência), seed visível e "Repetir esta arena".

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"


func _ready() -> void:
	var motor: GameEngine = Sessao.ultimo_motor
	if motor == null:
		# Cena aberta sem partida (ex.: rodada direto no editor) — volta à Home.
		get_tree().change_scene_to_file.call_deferred(CENA_HOME)
		return
	_montar_fundo()
	_montar_conteudo(motor)


func _montar_fundo() -> void:
	var gradiente: Gradient = Gradient.new()
	gradiente.colors = PackedColorArray([T.COR_APP_FUNDO_INICIO, T.COR_APP_FUNDO_FIM])
	var textura: GradientTexture2D = GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2.ZERO
	textura.fill_to = Vector2.DOWN.rotated(deg_to_rad(T.APP_FUNDO_ANGULO - 180.0))
	var fundo: TextureRect = TextureRect.new()
	fundo.texture = textura
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)


func _montar_conteudo(motor: GameEngine) -> void:
	var jogador: SnakeModel = motor.jogador()

	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	margem.add_theme_constant_override("margin_top", T.ESP_XL)
	margem.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(margem)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_SM)
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	margem.add_child(coluna)

	var desfecho: Label = Label.new()
	desfecho.text = "Fim da partida!" if jogador.viva else "Você foi devorado!"
	desfecho.theme_type_variation = &"TituloLg"
	desfecho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(desfecho)

	var posicao: Label = Label.new()
	posicao.text = "%dº de %d" % [motor.posicao_no_ranking(jogador), motor.arena.cobras.size()]
	posicao.theme_type_variation = &"TituloHero"
	posicao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(posicao)

	var pontos: Label = Label.new()
	pontos.text = "%d pontos" % jogador.pontos
	pontos.theme_type_variation = &"TituloScore"
	pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(pontos)

	coluna.add_child(_card_breakdown(motor, jogador))

	var seed_rotulo: Label = Label.new()
	seed_rotulo.text = "ARENA #%d" % motor.rng.semente
	seed_rotulo.theme_type_variation = &"TextoLegenda"
	seed_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(seed_rotulo)

	var jogar: Button = Button.new()
	jogar.text = "Jogar novamente"
	jogar.theme_type_variation = &"BotaoPrimario"
	jogar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_JOGO))
	coluna.add_child(jogar)

	var repetir: Button = Button.new()
	repetir.text = "Repetir esta arena"
	repetir.theme_type_variation = &"BotaoSecundario"
	repetir.pressed.connect(func() -> void:
		Sessao.proxima_semente = motor.rng.semente
		get_tree().change_scene_to_file(CENA_JOGO))
	coluna.add_child(repetir)

	var menu: Button = Button.new()
	menu.text = "Menu"
	menu.theme_type_variation = &"BotaoSecundario"
	menu.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	coluna.add_child(menu)


## Breakdown: comida e sobrevivência saem das estatísticas × constantes do
## motor; abates ficam com o restante (a curva por vítima não é reconstituível
## só das estatísticas agregadas).
func _card_breakdown(motor: GameEngine, jogador: SnakeModel) -> PanelContainer:
	var pontos_comida: int = jogador.comidas * GameEngine.PONTOS_COMIDA
	@warning_ignore("integer_division")
	var pontos_sobrevivencia: int = (jogador.ticks_vividos / GameEngine.TICKS_POR_SEGUNDO) \
		* GameEngine.PONTOS_POR_SEGUNDO
	var pontos_abates: int = jogador.pontos - pontos_comida - pontos_sobrevivencia
	@warning_ignore("integer_division")
	var segundos: int = jogador.ticks_vividos / GameEngine.TICKS_POR_SEGUNDO

	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var linhas: VBoxContainer = VBoxContainer.new()
	linhas.add_theme_constant_override("separation", T.ESP_XS)
	card.add_child(linhas)
	_linha(linhas, "Comida ×%d" % jogador.comidas, pontos_comida)
	_linha(linhas, "Abates ×%d" % jogador.abates, pontos_abates)
	_linha(linhas, "Sobrevivência %ds" % segundos, pontos_sobrevivencia)
	return card


func _linha(pai: Container, texto: String, valor: int) -> void:
	var linha: HBoxContainer = HBoxContainer.new()
	pai.add_child(linha)
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = &"TextoCorpo"
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	var pontos: Label = Label.new()
	pontos.text = "+%d" % valor
	pontos.theme_type_variation = &"TextoSucesso"
	linha.add_child(pontos)
