class_name Desafios
extends Control
## Seleção de desafios — composição fiel ao blueprint "07 Desafios" (M2).
## Adaptações registradas: subtítulo pedagógico no lugar de "RENOVAM EM 2
## DIAS" (não há rotação — nossos desafios são lições fixas por seed);
## pill de prêmio em moedas vira selo de estado (valores de prêmio são
## decisão do M3, junto com a economia); Desafios 3–4 guardam lugar
## (chegam no M3); rodapé do buff de Evolução apagado (Evolução é futuro).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"

## Cards — objetivos conforme docs §2.5; cor/ícone por desafio. Índices de
## cor na paleta de cobras; desafio -1 = ainda não existe (M3).
const FICHAS: Array[Dictionary] = [
	{
		"desafio": ChallengeRules.Desafio.FARMING_PURO,
		"icone": "🍎", "cor": 0,
		"titulo": "Farming puro",
		"meta": "50 pontos em 1 min sem matar ninguém",
	},
	{
		"desafio": ChallengeRules.Desafio.AGRESSAO_CONTROLADA,
		"icone": "🏹", "cor": 4,
		"titulo": "Agressão controlada",
		"meta": "Devore 3 bots antes de 2 min — sendo caçado",
	},
	{
		"desafio": -1,
		"icone": "💪", "cor": 1,
		"titulo": "Defesa",
		"meta": "Sobreviva 3 min com 2 caçadores gigantes",
	},
	{
		"desafio": -1,
		"icone": "🥉", "cor": 5,
		"titulo": "Integração total",
		"meta": "Termine no Top 3 de uma arena com 20 bots",
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
		margem.add_theme_constant_override("margin_" + lado, T.ESP_MD + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_bottom", T.ESP_LG + T.ESP_MICRO)
	add_child(margem)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_MD)
	margem.add_child(coluna)

	coluna.add_child(_cabecalho())

	var lista: VBoxContainer = VBoxContainer.new()
	lista.add_theme_constant_override("separation", T.ESP_SM)
	coluna.add_child(lista)
	for ficha: Dictionary in FICHAS:
		lista.add_child(_card_desafio(ficha))

	coluna.add_child(_espaco_flexivel())

	# Rodapé do blueprint — guarda lugar (buffs de Evolução são futuro).
	var rodape: Label = Label.new()
	rodape.text = "Complete os 4 e ganhe 1 buff de Evolução grátis 🎁"
	rodape.theme_type_variation = &"TextoLegenda"
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.modulate.a = 0.55
	coluna.add_child(rodape)


## Header do blueprint: ← voltar · título + legenda · pill de moedas.
func _cabecalho() -> Control:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)

	var voltar: Button = Button.new()
	voltar.text = "←"
	voltar.theme_type_variation = &"ChipQuadrado"
	voltar.custom_minimum_size = Vector2(float(T.TOQUE_MIN) - 4.0, float(T.TOQUE_MIN) - 4.0)
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	linha.add_child(voltar)

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var titulo: Label = Label.new()
	titulo.text = "Desafios"
	titulo.theme_type_variation = &"TituloLg"
	pilha.add_child(titulo)
	var legenda: Label = Label.new()
	legenda.text = "MESMA ARENA, SEMPRE"
	legenda.theme_type_variation = &"TextoLegenda"
	pilha.add_child(legenda)
	linha.add_child(pilha)

	var moedas: PanelContainer = PanelContainer.new()
	moedas.theme_type_variation = &"PilulaContador"
	moedas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var conteudo: HBoxContainer = HBoxContainer.new()
	conteudo.add_theme_constant_override("separation", T.ESP_MICRO + 2)
	moedas.add_child(conteudo)
	var moedinha: Control = Control.new()
	moedinha.custom_minimum_size = Vector2(float(T.ESP_MD) + 2.0, 0.0)
	moedinha.draw.connect(func() -> void:
		var centro: Vector2 = moedinha.size * 0.5
		moedinha.draw_circle(centro, 8.0, T.COR_MOEDA_BORDA)
		moedinha.draw_circle(centro, 5.5, T.COR_MOEDA))
	conteudo.add_child(moedinha)
	var saldo: Label = Label.new()
	saldo.text = str(ProgressoLocal.moedas())
	saldo.theme_type_variation = &"TextoCorpo"
	conteudo.add_child(saldo)
	linha.add_child(moedas)
	return linha


## Card do blueprint: ícone em chip colorido · título colorido + meta ·
## selo de estado. Card inteiro é o botão de jogar (desafios existentes).
func _card_desafio(ficha: Dictionary) -> Control:
	var cor: Color = T.CORES_COBRA_BASE[ficha["cor"]]
	var existe: bool = int(ficha["desafio"]) >= 0
	var concluido: bool = existe \
		and ProgressoLocal.desafio_concluido(ficha["desafio"])

	var card: Button = Button.new()
	card.theme_type_variation = &"CartaoNav"
	# Altura do card do blueprint (ícone 48 + respiro; o conteúdo é filho
	# full-rect e não dimensiona o Button sozinho).
	card.custom_minimum_size = Vector2(0.0, 88.0)
	if not existe:
		card.disabled = true
	else:
		card.pressed.connect(func() -> void:
			Sessao.desafio_pendente = int(ficha["desafio"])
			get_tree().change_scene_to_file(CENA_JOGO))

	var conteudo: HBoxContainer = HBoxContainer.new()
	conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
	conteudo.add_theme_constant_override("separation", T.ESP_SM)
	conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_SM)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(conteudo)
	card.add_child(margem)

	# Chip do ícone na cor do desafio.
	var chip: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = Color(cor, 0.14)
	caixa.set_corner_radius_all(T.RAIO_BOTAO)
	chip.add_theme_stylebox_override("panel", caixa)
	chip.custom_minimum_size = Vector2(float(T.TOQUE_MIN), float(T.TOQUE_MIN))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icone: Label = Label.new()
	icone.text = ficha["icone"]
	icone.theme_type_variation = &"TituloMd"
	icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icone)
	conteudo.add_child(chip)

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var titulo: Label = Label.new()
	titulo.text = ficha["titulo"]
	titulo.theme_type_variation = &"TituloMd"
	titulo.add_theme_color_override("font_color", cor)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(titulo)
	var meta: Label = Label.new()
	meta.text = ficha["meta"]
	meta.theme_type_variation = &"TextoCorpoSm"
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(meta)
	conteudo.add_child(pilha)

	# Selo de estado (a pill de prêmio em moedas chega com a economia, M3).
	var selo: Label = Label.new()
	if not existe:
		selo.text = "EM BREVE"
		selo.theme_type_variation = &"TextoLegenda"
	elif concluido:
		selo.text = "✓"
		selo.theme_type_variation = &"TituloMd"
		selo.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	else:
		selo.text = "▶"
		selo.theme_type_variation = &"TituloMd"
	selo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo.add_child(selo)

	if not existe:
		margem.modulate.a = 0.5  # guardando lugar (M3)
	return card


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return espaco
