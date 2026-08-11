class_name Home
extends Control
## Tela inicial — composição fiel ao blueprint "01 Home" (1d+1e) do Claude
## Design (`docs/design/Snakito Telas.dc.html`), M2. Adaptações registradas:
## sem moedas/tickets/fase (economia é M3+) e sem ⚙ (Configurações é M3);
## a grade de navegação usa os destinos existentes (Desafios/Ranking/Skins/
## Conta). Árvore em código, consumindo só tokens e variações do Theme.

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"

## Célula da grade de navegação (blueprint: 84px de altura, 4 colunas).
const ALTURA_CELULA_NAV: float = 84.0
## Mascote do hero (blueprint: 210×152 — cobra de 4 círculos crescentes).
const MASCOTE_TAMANHO: Vector2 = Vector2(210.0, 152.0)


func _ready() -> void:
	# Primeira abertura: onboarding sem texto (docs §8) antes de tudo.
	# Deferred — trocar de cena dentro do _ready da cena atual é frágil.
	if not ProgressoLocal.onboarding_visto():
		get_tree().change_scene_to_file.call_deferred(
			"res://src/scenes/onboarding/onboarding.tscn")
		return
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

## Blueprint: chip-avatar à esquerda, contadores de economia no centro e ⚙
## à direita. Economia EXIBIDA desde já (zerada — ganhar/gastar é M3, decisão
## de 11/08); o ⚙ fica de fora até Configurações existir (M3). O avatar leva
## à Conta.
func _barra_topo() -> Control:
	var barra: HBoxContainer = HBoxContainer.new()
	barra.add_theme_constant_override("separation", T.ESP_XS)
	var avatar: Button = Button.new()
	avatar.theme_type_variation = &"Chip"
	avatar.custom_minimum_size = Vector2(float(T.TOQUE_MIN), float(T.TOQUE_MIN))
	avatar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/conta/conta.tscn"))
	avatar.draw.connect(func() -> void:
		_desenhar_cabecinha(avatar, avatar.size * 0.5, avatar.size.y * 0.36))
	barra.add_child(avatar)
	var espaco: Control = Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(espaco)
	barra.add_child(_contador_moedas())
	barra.add_child(_contador("🎟️", ProgressoLocal.tickets()))
	return barra


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

	var titulo: Label = Label.new()
	titulo.text = "Snakito"
	titulo.theme_type_variation = &"TituloHero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Gradiente verde→azul do logo: aproximado pela cor primária (mesma
	# pendência estética registrada dos CTAs — shader quando o polimento
	# importar).
	titulo.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	hero.add_child(titulo)

	# Pílula "skin equipada" — toque leva à tela de Skins (blueprint 1e).
	var centro: HBoxContainer = HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	var pilula: Button = Button.new()
	pilula.theme_type_variation = &"Chip"
	pilula.text = "● %s equipada" % _nome_da_skin()
	pilula.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/skins/skins.tscn"))
	pilula.add_theme_color_override("font_color",
		T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()])
	centro.add_child(pilula)
	hero.add_child(centro)
	return hero


# ------------------------------------------------------- rodapé (CTA + nav)

func _rodape_navegacao() -> Control:
	var rodape: VBoxContainer = VBoxContainer.new()
	rodape.add_theme_constant_override("separation", T.ESP_SM)

	var jogar: Button = Button.new()
	jogar.text = "▶ Jogar Arcade"
	jogar.theme_type_variation = &"BotaoHeroi"
	jogar.custom_minimum_size = Vector2(0.0, float(T.TOQUE_HEROI))
	jogar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_JOGO))
	rodape.add_child(jogar)

	# Grade de navegação 4×1 (blueprint 1d) com os destinos que existem.
	var grade: GridContainer = GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", T.ESP_XS)
	grade.add_child(_celula_nav("🎯", "Desafios", "res://src/ui/desafios/desafios.tscn"))
	grade.add_child(_celula_nav("🏆", "Ranking", "res://src/ui/ranking/ranking.tscn"))
	grade.add_child(_celula_nav("🎨", "Skins", "res://src/ui/skins/skins.tscn"))
	grade.add_child(_celula_nav("👤", "Conta", "res://src/ui/conta/conta.tscn"))
	rodape.add_child(grade)

	# Gatilho do crash de teste do Sentry — só em builds de debug.
	if OS.is_debug_build():
		var crash: Button = Button.new()
		crash.text = "🐛 Crash de teste (Sentry)"
		crash.theme_type_variation = &"BotaoDestrutivo"
		crash.pressed.connect(_crash_de_teste)
		rodape.add_child(crash)
	return rodape


func _celula_nav(emoji: String, nome: String, cena: String) -> Button:
	var celula: Button = Button.new()
	celula.theme_type_variation = &"BotaoSecundario"
	celula.custom_minimum_size = Vector2(0.0, ALTURA_CELULA_NAV)
	celula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	celula.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(cena))
	# Conteúdo empilhado (emoji sobre rótulo) — filhos ignoram o mouse para
	# o toque cair sempre no Button.
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.set_anchors_preset(Control.PRESET_FULL_RECT)
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.add_theme_constant_override("separation", T.ESP_MICRO)
	pilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icone: Label = Label.new()
	icone.text = emoji
	icone.theme_type_variation = &"TituloMd"
	icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(icone)
	var rotulo: Label = Label.new()
	rotulo.text = nome
	rotulo.theme_type_variation = &"TextoCorpoSm"
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilha.add_child(rotulo)
	celula.add_child(pilha)
	return celula


# ---------------------------------------------------------------- desenhos

## Cobra do blueprint: 4 círculos crescentes (rabo→cabeça) na cor da skin,
## cabeça com olhos e sorriso.
func _desenhar_mascote(alvo: Control) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	var escala: Vector2 = alvo.size / Vector2(200.0, 150.0)  # viewBox do design
	var corpo: Array[Vector3] = [  # (cx, cy, raio) do blueprint
		Vector3(52.0, 112.0, 16.0), Vector3(76.0, 98.0, 19.0),
		Vector3(104.0, 86.0, 23.0), Vector3(138.0, 76.0, 28.0),
	]
	var alfas: Array[float] = [0.5, 0.7, 0.85, 1.0]
	for i: int in corpo.size():
		alvo.draw_circle(
			Vector2(corpo[i].x, corpo[i].y) * escala,
			corpo[i].z * escala.x, Color(cor, alfas[i]))
	_desenhar_carinha(alvo, Vector2(138.0, 76.0) * escala, 28.0 * escala.x)


func _desenhar_cabecinha(alvo: Control, centro: Vector2, raio: float) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	alvo.draw_circle(centro, raio, cor)
	_desenhar_carinha(alvo, centro, raio)


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
