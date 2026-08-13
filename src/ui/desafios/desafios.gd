class_name Desafios
extends Control
## Seleção de desafios — composição fiel ao blueprint "07 Desafios" (M2).
## Adaptações registradas: subtítulo pedagógico no lugar de "RENOVAM EM 2
## DIAS" (não há rotação — nossos desafios são lições fixas por seed);
## pill de prêmio presente e ZERADA (valores chegam com a economia, M3);
## Desafios 3–4 guardam lugar (M3); rodapé do buff de Evolução apagado.

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
	voltar.theme_type_variation = &"ChipQuadrado"
	voltar.custom_minimum_size = Vector2(float(T.TOQUE_MIN) - 4.0, float(T.TOQUE_MIN) - 4.0)
	voltar.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # quadrado de fato
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	# Seta desenhada (o glifo "←" renderiza descentralizado — métrica de
	# fonte; desenho é centrado por construção).
	voltar.draw.connect(func() -> void:
		var centro: Vector2 = voltar.size * 0.5
		var braco: float = voltar.size.x * 0.18
		var cor: Color = T.COR_TEXTO_PRIMARIO
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(braco, 0.0), cor, 2.0)
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(-braco * 0.15, -braco * 0.85), cor, 2.0)
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(-braco * 0.15, braco * 0.85), cor, 2.0))
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


## Card do blueprint: [chip do ícone][título colorido + meta][pill de
## prêmio amarela] + rodapé opcional de estado; borda na cor do desafio.
## Card inteiro é o botão de jogar (desafios existentes).
func _card_desafio(ficha: Dictionary) -> Control:
	var cor: Color = T.CORES_COBRA_BASE[ficha["cor"]]
	var existe: bool = int(ficha["desafio"]) >= 0
	var concluido: bool = existe \
		and ProgressoLocal.desafio_concluido(ficha["desafio"])

	# PanelContainer auto-dimensiona pelo conteúdo (Button não); o toque é
	# de um botão invisível full-rect por cima do conteúdo.
	var card: PanelContainer = PanelContainer.new()
	# Vidro com borda NA COR do desafio (d.borda do blueprint); os futuros
	# ficam com a borda de vidro neutra.
	var caixa_card: StyleBoxFlat = StyleBoxFlat.new()
	caixa_card.bg_color = T.COR_SUPERFICIE_VIDRO
	caixa_card.set_corner_radius_all(T.RAIO_CARD)
	caixa_card.set_border_width_all(T.BORDA_FINA)
	caixa_card.border_color = Color(cor, 0.4) if existe else T.COR_SUPERFICIE_VIDRO_BORDA
	caixa_card.content_margin_left = float(T.ESP_MD)
	caixa_card.content_margin_right = float(T.ESP_MD)
	caixa_card.content_margin_top = float(T.ESP_MD)
	caixa_card.content_margin_bottom = float(T.ESP_MD)
	card.add_theme_stylebox_override("panel", caixa_card)

	var pilha_card: VBoxContainer = VBoxContainer.new()
	pilha_card.add_theme_constant_override("separation", T.ESP_XS + 2)
	card.add_child(pilha_card)

	# Linha principal: chip do ícone · título/meta · pill de prêmio.
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha_card.add_child(linha)

	var chip: PanelContainer = PanelContainer.new()
	var caixa_chip: StyleBoxFlat = StyleBoxFlat.new()
	caixa_chip.bg_color = Color(cor, 0.14)
	caixa_chip.set_corner_radius_all(T.RAIO_BOTAO)
	chip.add_theme_stylebox_override("panel", caixa_chip)
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
	linha.add_child(chip)

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var titulo: Label = Label.new()
	titulo.text = ficha["titulo"]
	titulo.theme_type_variation = &"TituloMd"
	titulo.add_theme_font_size_override("font_size", T.TAM_BOTAO)  # 16.5 no desenho
	titulo.add_theme_color_override("font_color", cor)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(titulo)
	var meta: Label = Label.new()
	meta.text = ficha["meta"]
	meta.theme_type_variation = &"TextoCorpoSm"
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(meta)
	linha.add_child(pilha)

	# Pill de prêmio do blueprint — zerada até a economia (M3).
	var premio: PanelContainer = PanelContainer.new()
	var caixa_premio: StyleBoxFlat = StyleBoxFlat.new()
	caixa_premio.bg_color = Color(T.COR_MOEDA, 0.12)
	caixa_premio.set_corner_radius_all(T.RAIO_PILULA)
	caixa_premio.content_margin_left = float(T.ESP_SM) - 1.0
	caixa_premio.content_margin_right = float(T.ESP_SM) - 1.0
	caixa_premio.content_margin_top = float(T.ESP_MICRO) + 1.0
	caixa_premio.content_margin_bottom = float(T.ESP_MICRO) + 1.0
	premio.add_theme_stylebox_override("panel", caixa_premio)
	premio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	premio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var conteudo_premio: HBoxContainer = HBoxContainer.new()
	conteudo_premio.add_theme_constant_override("separation", T.ESP_MICRO + 1)
	conteudo_premio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	premio.add_child(conteudo_premio)
	var moedinha: Control = Control.new()
	moedinha.custom_minimum_size = Vector2(float(T.ESP_SM) + 1.0, 0.0)
	moedinha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moedinha.draw.connect(func() -> void:
		var centro: Vector2 = moedinha.size * 0.5
		moedinha.draw_circle(centro, 6.5, T.COR_MOEDA_BORDA)
		moedinha.draw_circle(centro, 4.5, T.COR_MOEDA))
	conteudo_premio.add_child(moedinha)
	var valor_premio: Label = Label.new()
	valor_premio.text = "+0"  # valores de prêmio chegam com a economia (M3)
	valor_premio.theme_type_variation = &"TextoCorpoSm"
	valor_premio.add_theme_color_override("font_color", T.COR_MOEDA)
	valor_premio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo_premio.add_child(valor_premio)
	linha.add_child(premio)

	# Rodapé de estado (d.rodape do blueprint).
	if concluido:
		var rodape: Label = Label.new()
		rodape.text = "✓ Concluído"
		rodape.theme_type_variation = &"TextoCorpoSm"
		rodape.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
		rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pilha_card.add_child(rodape)
	elif not existe:
		var rodape: Label = Label.new()
		rodape.text = "Em breve"
		rodape.theme_type_variation = &"TextoCorpoSm"
		rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pilha_card.add_child(rodape)

	if not existe:
		pilha_card.modulate.a = 0.55  # guardando lugar (M3)
	else:
		# Botão invisível cobrindo o card — o toque em qualquer ponto joga.
		var toque: Button = Button.new()
		toque.flat = true
		toque.set_anchors_preset(Control.PRESET_FULL_RECT)
		toque.pressed.connect(func() -> void:
			Sessao.desafio_pendente = int(ficha["desafio"])
			get_tree().change_scene_to_file(CENA_JOGO))
		card.add_child(toque)
	return card


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return espaco
