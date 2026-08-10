class_name Desafios
extends Control
## Seleção de desafios (M1): um card por desafio com objetivo, estado de
## conclusão e botão de jogar. Strings pt-BR daqui até o i18n do M2.

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"

## Conteúdo dos cards — objetivos conforme docs §2.5.
const FICHAS: Array[Dictionary] = [
	{
		"desafio": ChallengeRules.Desafio.FARMING_PURO,
		"titulo": "Desafio 1 · Farming puro",
		"objetivo": "Chegue a 50 pontos em 1 minuto sem matar ninguém",
	},
	{
		"desafio": ChallengeRules.Desafio.AGRESSAO_CONTROLADA,
		"titulo": "Desafio 2 · Agressão controlada",
		"objetivo": "Devore 3 bots antes de 2 minutos — sendo caçado",
	},
]


func _ready() -> void:
	_montar_fundo()
	_montar_conteudo()


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


func _montar_conteudo() -> void:
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL)
	margem.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(margem)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_MD)
	margem.add_child(coluna)

	var titulo: Label = Label.new()
	titulo.text = "Desafios"
	titulo.theme_type_variation = &"TituloHero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)

	var subtitulo: Label = Label.new()
	subtitulo.text = "A mesma arena, sempre — compare suas decisões"
	subtitulo.theme_type_variation = &"TextoSecundario"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(subtitulo)

	coluna.add_child(_espaco(T.ESP_LG))

	for ficha: Dictionary in FICHAS:
		coluna.add_child(_card_desafio(ficha))

	coluna.add_child(_espaco(T.ESP_LG))

	var voltar: Button = Button.new()
	voltar.text = "Voltar"
	voltar.theme_type_variation = &"BotaoSecundario"
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	coluna.add_child(voltar)


func _card_desafio(ficha: Dictionary) -> PanelContainer:
	var desafio: ChallengeRules.Desafio = ficha["desafio"]
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS)
	card.add_child(pilha)

	var linha_titulo: HBoxContainer = HBoxContainer.new()
	pilha.add_child(linha_titulo)
	var titulo: Label = Label.new()
	titulo.text = ficha["titulo"]
	titulo.theme_type_variation = &"TituloMd"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_titulo.add_child(titulo)
	if ProgressoLocal.desafio_concluido(desafio):
		var selo: Label = Label.new()
		selo.text = "✓ Concluído"
		selo.theme_type_variation = &"TextoSucesso"
		linha_titulo.add_child(selo)

	var objetivo: Label = Label.new()
	objetivo.text = ficha["objetivo"]
	objetivo.theme_type_variation = &"TextoSecundario"
	objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pilha.add_child(objetivo)

	var jogar: Button = Button.new()
	jogar.text = "Jogar"
	jogar.theme_type_variation = &"BotaoPrimario"
	jogar.pressed.connect(func() -> void:
		Sessao.desafio_pendente = int(desafio)
		get_tree().change_scene_to_file(CENA_JOGO))
	pilha.add_child(jogar)

	return card


func _espaco(altura: int) -> Control:
	var espaco: Control = Control.new()
	espaco.custom_minimum_size = Vector2(0.0, float(altura))
	return espaco
