class_name Home
extends Control
## Tela inicial — composição fiel ao blueprint "01 Home" (1d+1e) do Claude
## Design (`docs/design/Snakito Telas.dc.html`), M2. Gradientes REAIS:
## título verde→azul por letra (RichTextLabel) e CTA por polígono com cor
## por vértice. Adaptações registradas: economia exibida zerada (liga no
## M3, decisão 11/08); ⚙ presente e desabilitado até Configurações (M3);
## grade usa os destinos existentes. Árvore em código, só tokens/Theme.

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"

## Célula da grade de navegação (blueprint: 84px de altura, 4 colunas).
const ALTURA_CELULA_NAV: float = 84.0
## Mascote do hero (blueprint: 210×152) e viewBox do SVG original.
const MASCOTE_TAMANHO: Vector2 = Vector2(210.0, 152.0)
const MASCOTE_VIEWBOX: Vector2 = Vector2(200.0, 150.0)


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
	margem.add_theme_constant_override("margin_top", T.ESP_2XL + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(margem)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_SM)
	margem.add_child(coluna)

	coluna.add_child(_barra_topo())
	coluna.add_child(_hero())
	coluna.add_child(_rodape_navegacao())


# ------------------------------------------------------------ barra do topo

## Blueprint: avatar | economia no centro | ⚙ — space-between. Economia
## exibida zerada (liga no M3); ⚙ desabilitado até Configurações (M3).
func _barra_topo() -> Control:
	var barra: HBoxContainer = HBoxContainer.new()
	barra.add_theme_constant_override("separation", T.ESP_XS)

	var avatar: Button = Button.new()
	avatar.theme_type_variation = &"ChipQuadrado"
	avatar.custom_minimum_size = Vector2(float(T.TOQUE_MIN), float(T.TOQUE_MIN))
	# Com perfil → Informações do jogador (02b); sem → Conta (login).
	avatar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(
			"res://src/ui/info_jogador/info_jogador.tscn"
			if Rede.tem_perfil() else "res://src/ui/conta/conta.tscn"))
	# Blueprint do avatar: cabeça de 36px SÓ com olhos (sem sorriso) e brilho
	# radial no topo-esquerda.
	avatar.draw.connect(func() -> void:
		_desenhar_cabeca_avatar(avatar, avatar.size * 0.5, avatar.size.y * 0.375))
	barra.add_child(avatar)

	barra.add_child(_espaco_flexivel())
	barra.add_child(_contador_moedas())
	barra.add_child(_contador("🎟️", ProgressoLocal.tickets()))
	barra.add_child(_espaco_flexivel())

	var config: Button = Button.new()
	config.theme_type_variation = &"ChipQuadrado"
	config.text = "⚙"
	config.custom_minimum_size = Vector2(float(T.TOQUE_MIN), float(T.TOQUE_MIN))
	config.disabled = true  # Configurações chega no M3 — o lugar já é dela
	# Desabilitado mas FIEL: mesmo vidro e mesmo glifo branco do desenho
	# (o estado desabilitado padrão apagava o chip e fugia do blueprint).
	var tema: Theme = ThemeDB.get_project_theme()
	config.add_theme_stylebox_override("disabled",
		tema.get_stylebox(&"normal", &"ChipQuadrado"))
	config.add_theme_color_override("font_disabled_color", T.COR_TEXTO_PRIMARIO)
	barra.add_child(config)
	return barra


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return espaco


## Pílula do contador de moedas — a moedinha é desenhada (círculo dourado
## com borda, como no blueprint), não emoji: consistência entre aparelhos.
func _contador_moedas() -> Control:
	var pilula: PanelContainer = _contador("", ProgressoLocal.moedas())
	var moeda: Control = Control.new()
	moeda.custom_minimum_size = Vector2(float(T.ESP_LG), 0.0)
	moeda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moeda.draw.connect(func() -> void:
		var centro: Vector2 = moeda.size * 0.5
		moeda.draw_circle(centro, 10.0, T.COR_MOEDA_BORDA)
		moeda.draw_circle(centro, 7.0, T.COR_MOEDA))
	var linha: HBoxContainer = pilula.get_child(0)
	linha.add_child(moeda)
	linha.move_child(moeda, 0)
	return pilula


func _contador(emoji: String, valor: int) -> PanelContainer:
	var pilula: PanelContainer = PanelContainer.new()
	pilula.theme_type_variation = &"PilulaContador"
	pilula.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN) - float(T.ESP_MICRO))
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_MICRO + 2)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilula.add_child(linha)
	if emoji != "":
		var icone: Label = Label.new()
		icone.text = emoji
		icone.theme_type_variation = &"TextoCorpo"
		linha.add_child(icone)
	var numero: Label = Label.new()
	numero.text = str(valor)
	numero.theme_type_variation = &"TextoCorpo"
	linha.add_child(numero)
	return pilula


# -------------------------------------------------------------------- hero

func _hero() -> Control:
	var hero: VBoxContainer = VBoxContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", T.ESP_SM)

	# Mascote: cobra de 4 círculos crescentes na cor da skin, com carinha —
	# desenho do blueprint reproduzido em _draw (sem asset).
	var mascote: Control = Control.new()
	mascote.custom_minimum_size = MASCOTE_TAMANHO
	mascote.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascote.draw.connect(_desenhar_mascote.bind(mascote))
	hero.add_child(mascote)

	hero.add_child(_titulo_gradiente())

	# Pílula "skin equipada" (blueprint 1e): abraça o conteúdo — bolinha com
	# brilho radial (ícone gerado) + texto cinza 13px extrabold.
	var centro: HBoxContainer = HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	var pilula: Button = Button.new()
	pilula.theme_type_variation = &"Chip"
	pilula.text = "%s equipada" % _nome_da_skin()
	pilula.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	pilula.icon = _textura_bolinha_skin()
	# A variação Chip modula ícones com a cor do texto (cinza) — a bolinha
	# tem cor própria: modulação neutra.
	for estado: StringName in [&"icon_normal_color", &"icon_pressed_color", &"icon_hover_color", &"icon_focus_color"]:
		pilula.add_theme_color_override(estado, Color.WHITE)
	pilula.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/skins/skins.tscn"))
	centro.add_child(pilula)
	hero.add_child(centro)
	return hero


## Bolinha da skin com o brilho radial do design, como textura de ícone
## (borda esvanece → círculo antisserrilhado; cantos ficam transparentes).
func _textura_bolinha_skin() -> Texture2D:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	var gradiente: Gradient = Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.5, 0.92, 1.0])
	gradiente.colors = PackedColorArray([
		cor.lightened(0.4), cor, cor, Color(cor, 0.0)])
	var textura: GradientTexture2D = GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = T.ESP_MD
	textura.height = T.ESP_MD
	return textura


## Logo com o gradiente verde→azul REAL do design, interpolado por letra
## (Label não pinta gradiente; por glifo o olho não distingue do contínuo).
func _titulo_gradiente() -> RichTextLabel:
	var titulo: RichTextLabel = RichTextLabel.new()
	titulo.bbcode_enabled = true
	titulo.fit_content = true
	titulo.scroll_active = false
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tema: Theme = ThemeDB.get_project_theme()
	titulo.add_theme_font_override("normal_font", tema.get_font(&"font", &"TituloHero"))
	titulo.add_theme_font_size_override("normal_font_size",
		tema.get_font_size(&"font_size", &"TituloHero"))
	var texto: String = "Snakito"
	var partes: String = ""
	for i: int in texto.length():
		var cor: Color = T.COR_CTA_PRIMARIO_INICIO.lerp(
			T.CORES_COBRA_BASE[1], float(i) / float(texto.length() - 1))
		partes += "[color=#%s]%s[/color]" % [cor.to_html(false), texto[i]]
	titulo.text = "[center]%s[/center]" % partes
	return titulo


# ------------------------------------------------------- rodapé (CTA + nav)

func _rodape_navegacao() -> Control:
	var rodape: VBoxContainer = VBoxContainer.new()
	rodape.add_theme_constant_override("separation", T.ESP_SM)

	# CTA hero com o gradiente REAL do design (COR_CTA_PRIMARIO_INICIO→FIM):
	# polígono arredondado com cor por vértice, texto em Label filho.
	var jogar: Button = Button.new()
	jogar.theme_type_variation = &"BotaoHeroi"
	jogar.flat = true
	jogar.custom_minimum_size = Vector2(0.0, float(T.TOQUE_HEROI))
	jogar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_JOGO))
	jogar.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(jogar, jogar.size, float(T.RAIO_CARD),
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM))
	jogar.button_down.connect(func() -> void: jogar.modulate.a = 0.85)
	jogar.button_up.connect(func() -> void: jogar.modulate.a = 1.0)
	var texto_jogar: Label = Label.new()
	texto_jogar.text = "▶ Jogar Arcade"
	texto_jogar.theme_type_variation = &"RotuloCtaHeroi"
	texto_jogar.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto_jogar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_jogar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_jogar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jogar.add_child(texto_jogar)
	rodape.add_child(jogar)

	# Grade de navegação 4×1 EXATAMENTE como o blueprint 1d: Desafios ·
	# Ranking · Loja · Evolução. Loja (M3) e Evolução (pós-lançamento)
	# guardam o lugar desabilitadas — Skins e Conta já têm os caminhos do
	# próprio desenho (pílula "equipada" e avatar do topo).
	var grade: GridContainer = GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", T.ESP_XS)
	grade.add_child(_celula_nav("🎯", "Desafios", "res://src/ui/desafios/desafios.tscn"))
	grade.add_child(_celula_nav("🏆", "Ranking", "res://src/ui/ranking/ranking.tscn"))
	grade.add_child(_celula_nav("🛍", "Loja"))
	# ⬆️ desenhado à mão: o Godot ignora o seletor U+FE0F e renderizava o
	# glifo monocromático no lugar do emoji colorido do blueprint.
	grade.add_child(_celula_nav("", "Evolução", "", _desenhar_icone_evolucao))
	rodape.add_child(grade)

	# Gatilho do crash de teste do Sentry — só em builds de debug.
	if OS.is_debug_build():
		var crash: Button = Button.new()
		crash.text = "🐛 Crash de teste (Sentry)"
		crash.theme_type_variation = &"BotaoDestrutivo"
		crash.pressed.connect(_crash_de_teste)
		rodape.add_child(crash)
	return rodape


## `cena` vazia = destino ainda não existe: célula presente e desabilitada
## (mesmo padrão do ⚙ — o desenho manda, a feature chega depois).
## `desenho` (opcional) troca o emoji por um ícone desenhado à mão.
func _celula_nav(
	emoji: String,
	nome: String,
	cena: String = "",
	desenho: Callable = Callable(),
) -> Button:
	var celula: Button = Button.new()
	celula.theme_type_variation = &"CartaoNav"
	celula.custom_minimum_size = Vector2(0.0, ALTURA_CELULA_NAV)
	celula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if cena == "":
		celula.disabled = true
		# Desabilitada mas fiel: mesmo vidro do desenho (o disabled padrão
		# troca o stylebox); o conteúdo apagado sinaliza o "em breve".
		celula.add_theme_stylebox_override("disabled",
			ThemeDB.get_project_theme().get_stylebox(&"normal", &"CartaoNav"))
	else:
		celula.pressed.connect(func() -> void:
			get_tree().change_scene_to_file(cena))
	# Conteúdo empilhado (ícone sobre rótulo) — filhos ignoram o mouse para
	# o toque cair sempre no Button.
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.set_anchors_preset(Control.PRESET_FULL_RECT)
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.add_theme_constant_override("separation", T.ESP_MICRO)
	pilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if desenho.is_valid():
		var icone_desenhado: Control = Control.new()
		icone_desenhado.custom_minimum_size = \
			Vector2(0.0, float(T.ALTURA_LINHA_TITULO_MD))
		icone_desenhado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icone_desenhado.draw.connect(func() -> void:
			desenho.call(icone_desenhado))
		pilha.add_child(icone_desenhado)
	else:
		var icone: Label = Label.new()
		icone.text = emoji
		icone.theme_type_variation = &"TituloMd"
		icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pilha.add_child(icone)
	var rotulo: Label = Label.new()
	rotulo.text = nome
	rotulo.theme_type_variation = &"RotuloNav"
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(rotulo)
	if celula.disabled:
		pilha.modulate.a = 0.45  # conteúdo apagado junto com o botão
	celula.add_child(pilha)
	return celula


# ---------------------------------------------------------------- desenhos

## Ícone da Evolução — desenho compartilhado (DesenhoUi).
func _desenhar_icone_evolucao(alvo: Control) -> void:
	var lado: float = alvo.size.y
	DesenhoUi.icone_evolucao(alvo, Rect2(
		Vector2((alvo.size.x - lado) * 0.5, 0.0), Vector2(lado, lado)))


## Cobra do blueprint: 4 círculos crescentes (rabo→cabeça) na cor da skin,
## cabeça com olhos e sorriso.
func _desenhar_mascote(alvo: Control) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	var escala: Vector2 = alvo.size / MASCOTE_VIEWBOX
	var corpo: Array[Vector3] = [  # (cx, cy, raio) do blueprint
		Vector3(52.0, 112.0, 16.0), Vector3(76.0, 98.0, 19.0),
		Vector3(104.0, 86.0, 23.0), Vector3(138.0, 76.0, 28.0),
	]
	var alfas: Array[float] = [0.5, 0.7, 0.85, 1.0]
	for i: int in corpo.size():
		alvo.draw_circle(
			Vector2(corpo[i].x, corpo[i].y) * escala,
			corpo[i].z * escala.x, Color(cor, alfas[i]))
	var cabeca: Vector2 = Vector2(138.0, 76.0) * escala
	_desenhar_brilho(alvo, cabeca, 28.0 * escala.x)
	_desenhar_carinha(alvo, cabeca, 28.0 * escala.x)


## Cabeça do avatar (blueprint: SÓ olhos, sem sorriso, com brilho radial).
func _desenhar_cabeca_avatar(alvo: Control, centro: Vector2, raio: float) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	alvo.draw_circle(centro, raio, cor)
	_desenhar_brilho(alvo, centro, raio)
	_desenhar_olhos_avatar(alvo, centro, raio)


## Brilho radial do design (radial-gradient 32%/28%): círculo claro
## deslocado ao topo-esquerda, contido na cabeça.
func _desenhar_brilho(alvo: Control, centro: Vector2, raio: float) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	alvo.draw_circle(
		centro + Vector2(-raio * 0.25, -raio * 0.3), raio * 0.55,
		Color(cor.lightened(0.35), 0.55))


func _desenhar_olhos_avatar(alvo: Control, centro: Vector2, raio: float) -> void:
	for lado: float in [-1.0, 1.0]:
		var olho: Vector2 = centro + Vector2(lado * raio * 0.33, -raio * 0.12)
		alvo.draw_circle(olho, raio * 0.2, T.COR_SIMBOLO_DALTONISMO)
		alvo.draw_circle(olho + Vector2(raio * 0.04, raio * 0.04),
			raio * 0.1, T.COR_APP_FUNDO_INICIO)


## Olhos + sorriso (proporções do SVG do blueprint).
func _desenhar_carinha(alvo: Control, centro: Vector2, raio: float) -> void:
	for lado: float in [-1.0, 1.0]:
		var olho: Vector2 = centro + Vector2(lado * raio * 0.36, -raio * 0.28)
		alvo.draw_circle(olho, raio * 0.23, T.COR_SIMBOLO_DALTONISMO)
		alvo.draw_circle(olho + Vector2(raio * 0.05, raio * 0.04),
			raio * 0.11, T.COR_APP_FUNDO_INICIO)
	alvo.draw_arc(centro + Vector2(0.0, raio * 0.18), raio * 0.30,
		deg_to_rad(35.0), deg_to_rad(145.0), 12,
		T.COR_APP_FUNDO_INICIO, maxf(2.0, raio * 0.12))


func _nome_da_skin() -> String:
	var indice: int = ProgressoLocal.skin_equipada()
	for skin: Dictionary in Skins.SKINS:
		if int(skin["indice"]) == indice:
			return str(skin["nome"])
	return "Skin"


## Envia um evento de erro e, em seguida, derruba o app de verdade — testa o
## caminho de evento imediato E o de crash nativo (sobe no próximo boot).
func _crash_de_teste() -> void:
	SentrySDK.capture_message("Crash de teste — spike Snakito", SentrySDK.LEVEL_ERROR)
	await get_tree().create_timer(2.0).timeout
	OS.crash("Crash de teste do spike Snakito (proposital)")
