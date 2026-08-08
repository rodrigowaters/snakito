class_name Home
extends Control
## Tela inicial do MVP: Jogar Arcade + entradas futuras desabilitadas
## (Desafios e Ranking chegam no M1). Árvore construída em código, consumindo
## só tokens e variações do Theme.

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"


func _ready() -> void:
	# Anchors do root vivem no .tscn (definir só em _ready não dimensiona
	# o root Control — a janela não redispara o layout).
	_montar_fundo()
	_montar_conteudo()
	_logar_plugins_android()


## Diagnóstico de integração (spike + suporte): confirma no logcat quais
## singletons de plugin nativo chegaram ao runtime.
func _logar_plugins_android() -> void:
	if OS.get_name() != "Android":
		return
	var relevantes: PackedStringArray = PackedStringArray()
	for singleton: String in Engine.get_singleton_list():
		if "Billing" in singleton or "AdMob" in singleton or "Poing" in singleton:
			relevantes.append(singleton)
	print("plugins android no runtime: ", relevantes)


func _montar_fundo() -> void:
	# Gradiente do app (tokens app/bg) via GradientTexture2D — sem shader.
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
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	margem.add_child(coluna)

	var titulo: Label = Label.new()
	titulo.text = "Snakito"
	titulo.theme_type_variation = &"TituloHero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)

	var subtitulo: Label = Label.new()
	subtitulo.text = "Cresça, cace e vença a arena"
	subtitulo.theme_type_variation = &"TextoSecundario"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(subtitulo)

	coluna.add_child(_espaco(T.ESP_2XL))

	var jogar: Button = Button.new()
	jogar.text = "Jogar Arcade"
	jogar.theme_type_variation = &"BotaoHeroi"
	jogar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_JOGO))
	coluna.add_child(jogar)

	for texto: String in ["Desafios", "Ranking"]:
		var botao: Button = Button.new()
		botao.text = texto + "  ·  em breve"
		botao.theme_type_variation = &"BotaoSecundario"
		botao.disabled = true
		coluna.add_child(botao)


func _espaco(altura: int) -> Control:
	var espaco: Control = Control.new()
	espaco.custom_minimum_size = Vector2(0.0, float(altura))
	return espaco
