class_name Configuracoes
extends Control
## Configurações — composição fiel ao blueprint "10" (M3). Funcionais desde
## já: Vibração, Modo daltonismo (símbolos nas cobras — item do M3),
## Sair e Excluir conta. Guardam lugar: sliders de áudio (sons são M3),
## Idioma (i18n M3), Privacidade e responsáveis, Remover anúncios e
## Restaurar compras (Billing M3).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_HOME: String = "res://src/ui/home/home.tscn"
const CENA_CONTA: String = "res://src/ui/conta/conta.tscn"

var _coluna: VBoxContainer


func _ready() -> void:
	_montar_fundo()
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_MD + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_bottom", T.ESP_LG + T.ESP_MICRO)
	add_child(margem)
	var externa: VBoxContainer = VBoxContainer.new()
	externa.add_theme_constant_override("separation", T.ESP_XS + 2)
	margem.add_child(externa)
	externa.add_child(_cabecalho())
	# Header fixo; seções roláveis — hoje o conteúdo cabe nos 412×915, mas
	# proporções mais curtas / i18n / linhas futuras não podem cortar mudo.
	var rolagem: ScrollContainer = ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Deadzone: sem ela, os botões que cobrem as linhas engolem o arrasto e
	# o scroll engasga. (SHOW_NEVER desligava a rolagem no aparelho — a
	# barra fica em AUTO, estilizada como fiapo discreto.)
	rolagem.scroll_deadzone = 24
	var barra: VScrollBar = rolagem.get_v_scroll_bar()
	barra.custom_minimum_size = Vector2(4.0, 0.0)
	var trilho_vazio: StyleBoxEmpty = StyleBoxEmpty.new()
	for parte: StringName in [&"scroll", &"scroll_focus"]:
		barra.add_theme_stylebox_override(parte, trilho_vazio)
	var fiapo: StyleBoxFlat = StyleBoxFlat.new()
	fiapo.bg_color = Color(T.COR_TEXTO_PRIMARIO, 0.18)
	fiapo.set_corner_radius_all(2)
	for parte: StringName in [&"grabber", &"grabber_highlight", &"grabber_pressed"]:
		barra.add_theme_stylebox_override(parte, fiapo)
	externa.add_child(rolagem)
	_coluna = VBoxContainer.new()
	_coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coluna.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_coluna.add_theme_constant_override("separation", T.ESP_XS + 2)
	rolagem.add_child(_coluna)
	_montar_conteudo()


func _montar_conteudo() -> void:

	_coluna.add_child(_titulo_secao("ÁUDIO"))
	var audio: VBoxContainer = _card_lista()
	# Sliders guardam lugar até o áudio chegar (M3).
	audio.add_child(_linha_slider("🔊", "Sons do jogo", 0.75, true))
	audio.add_child(_linha_slider("🎵", "Música", 0.4, false))
	audio.get_parent().modulate.a = 0.55

	_coluna.add_child(_titulo_secao("JOGO"))
	var jogo: VBoxContainer = _card_lista()
	jogo.add_child(_linha_toggle("📳", "Vibração (háptica)", "",
		ProgressoLocal.vibracao(),
		func(ligada: bool) -> void: ProgressoLocal.definir_vibracao(ligada), true))
	# Dificuldade do Arcade NÃO tem linha aqui (playtest 13/08: "não está
	# prevista no desenho") — fica interna no padrão CHEIA até o design
	# prever um lugar para ela.
	jogo.add_child(_linha_navegacao("🌐", "Idioma", "Português (BR) ›",
		Callable(), true))
	jogo.add_child(_linha_toggle("", "Modo daltonismo", "símbolos nas cobras",
		ProgressoLocal.daltonismo(),
		func(ligado: bool) -> void: ProgressoLocal.definir_daltonismo(ligado),
		false, _desenhar_icone_daltonismo))

	_coluna.add_child(_titulo_secao("CONTA"))
	var conta: VBoxContainer = _card_lista()
	if Rede.logado() and Rede.tem_perfil():
		conta.add_child(_linha_navegacao("", "Conectado como %s" % Rede.username(),
			"›", func() -> void: get_tree().change_scene_to_file(CENA_CONTA),
			true, _desenhar_g_google))
	else:
		conta.add_child(_linha_navegacao("", "Entrar com Google", "›",
			func() -> void: get_tree().change_scene_to_file(CENA_CONTA),
			true, _desenhar_g_google))
	conta.add_child(_linha_navegacao("🔒", "Privacidade e responsáveis", "›",
		Callable(), true))
	conta.add_child(_linha_navegacao("🚫", "Remover anúncios", "›",
		Callable(), true))
	conta.add_child(_linha_navegacao("🔄", "Restaurar compras", "›",
		Callable(), true))
	var pode_sair: bool = Rede.logado()
	conta.add_child(_linha_navegacao("🚪", "Sair da conta", "›",
		(func() -> void:
			Rede.sair()
			get_tree().change_scene_to_file(CENA_HOME)) if pode_sair else Callable(),
		true))
	var excluir: Control = _linha_navegacao("", "Excluir conta e dados", "›",
		(_abrir_confirmacao_exclusao) if pode_sair else Callable(),
		false, _desenhar_lixeira, T.COR_COMIDA_COMUM_REALCE)
	conta.add_child(excluir)

	_coluna.add_child(_espaco_flexivel())

	var rodape: Label = Label.new()
	rodape.text = "Snakito v%s · feito com 💚" % Rede.VERSAO_CLIENTE
	rodape.theme_type_variation = &"TextoLegenda"
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(rodape)


# ----------------------------------------------------------------- blocos

func _cabecalho() -> Control:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	var voltar: Button = Button.new()
	voltar.theme_type_variation = &"ChipQuadrado"
	voltar.custom_minimum_size = Vector2(float(T.TOQUE_MIN) - 4.0, float(T.TOQUE_MIN) - 4.0)
	voltar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	voltar.draw.connect(func() -> void:
		var centro: Vector2 = voltar.size * 0.5
		var braco: float = voltar.size.x * 0.18
		var cor: Color = T.COR_TEXTO_PRIMARIO
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(braco, 0.0), cor, 2.0)
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(-braco * 0.15, -braco * 0.85), cor, 2.0)
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(-braco * 0.15, braco * 0.85), cor, 2.0))
	linha.add_child(voltar)
	var titulo: Label = Label.new()
	titulo.text = "Configurações"
	titulo.theme_type_variation = &"TituloLg"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(titulo)
	return linha


func _titulo_secao(texto: String) -> Label:
	var titulo: Label = Label.new()
	titulo.text = texto
	titulo.theme_type_variation = &"TextoLegenda"
	return titulo


## Card de lista; devolve o VBox interno para receber linhas.
func _card_lista() -> VBoxContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", 0)
	card.add_child(pilha)
	_coluna.add_child(card)
	return pilha


## Linha base: [ícone][rótulo(+sub)][conteúdo à direita].
func _linha_base(
	emoji: String,
	rotulo: String,
	sub: String,
	divisoria: bool,
	desenho: Callable = Callable(),
	cor_rotulo: Color = Color.TRANSPARENT,
) -> Array:  # [envelope, hbox_da_linha]
	# Envelope PanelContainer transparente: overlays (botão de toque) se
	# EMPILHAM nele em vez de entrar no layout do HBox — um filho a mais no
	# HBox empurrava o chevron para a esquerda.
	var envelope: PanelContainer = PanelContainer.new()
	envelope.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var pilha: VBoxContainer = VBoxContainer.new()
	envelope.add_child(pilha)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN))
	linha.add_theme_constant_override("separation", T.ESP_SM)
	pilha.add_child(linha)
	if desenho.is_valid():
		var icone_desenhado: Control = Control.new()
		icone_desenhado.custom_minimum_size = Vector2(float(T.ESP_LG) + 2.0, 0.0)
		icone_desenhado.draw.connect(func() -> void:
			desenho.call(icone_desenhado))
		linha.add_child(icone_desenhado)
	else:
		var icone: Label = Label.new()
		icone.text = emoji
		icone.theme_type_variation = &"TextoCorpo"
		icone.custom_minimum_size = Vector2(float(T.ESP_LG) + 2.0, 0.0)
		icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		linha.add_child(icone)
	var textos: VBoxContainer = VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	var nome: Label = Label.new()
	nome.text = rotulo
	nome.theme_type_variation = &"TextoCorpo"
	if cor_rotulo != Color.TRANSPARENT:
		nome.add_theme_color_override("font_color", cor_rotulo)
	textos.add_child(nome)
	if sub != "":
		var subtitulo: Label = Label.new()
		subtitulo.text = sub
		subtitulo.theme_type_variation = &"TextoCorpoSm"
		textos.add_child(subtitulo)
	linha.add_child(textos)
	if divisoria:
		var traco: ColorRect = ColorRect.new()
		traco.color = Color(T.COR_TEXTO_PRIMARIO, 0.07)
		traco.custom_minimum_size = Vector2(0.0, 1.0)
		pilha.add_child(traco)
	return [envelope, linha]


## Linha com interruptor do blueprint (pill 58×34, gradiente quando ligado).
func _linha_toggle(
	emoji: String,
	rotulo: String,
	sub: String,
	ativo: bool,
	acao: Callable,
	divisoria: bool,
	desenho: Callable = Callable(),
) -> Control:
	var partes: Array = _linha_base(emoji, rotulo, sub, divisoria, desenho)
	var interruptor: Button = Button.new()
	interruptor.flat = true
	interruptor.custom_minimum_size = Vector2(58.0, 34.0)
	interruptor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var estado: Array[bool] = [ativo]
	interruptor.draw.connect(func() -> void:
		var caixa: Rect2 = Rect2(Vector2.ZERO, interruptor.size)
		if estado[0]:
			DesenhoUi.gradiente_arredondado(interruptor, interruptor.size,
				caixa.size.y * 0.5, T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM)
		else:
			interruptor.draw_colored_polygon(DesenhoUi.poligono_arredondado(
				caixa, caixa.size.y * 0.5), Color(T.COR_TEXTO_PRIMARIO, 0.12))
		var raio_botao: float = caixa.size.y * 0.5 - 4.0
		var x: float = caixa.size.x - raio_botao - 4.0 if estado[0] else raio_botao + 4.0
		interruptor.draw_circle(Vector2(x, caixa.size.y * 0.5), raio_botao,
			T.COR_TEXTO_PRIMARIO if estado[0] else T.COR_TEXTO_MUTED))
	interruptor.pressed.connect(func() -> void:
		estado[0] = not estado[0]
		acao.call(estado[0])
		interruptor.queue_redraw())
	partes[1].add_child(interruptor)
	return partes[0]


## Linha de navegação/valor ("Idioma — Português (BR) ›"). Ação inválida =
## guardando lugar (linha apagada).
func _linha_navegacao(
	emoji: String,
	rotulo: String,
	valor: String,
	acao: Callable,
	divisoria: bool,
	desenho: Callable = Callable(),
	cor_rotulo: Color = Color.TRANSPARENT,
) -> Control:
	var partes: Array = _linha_base(emoji, rotulo, "", divisoria, desenho, cor_rotulo)
	var direita: Label = Label.new()
	direita.text = valor
	direita.theme_type_variation = &"TextoCorpoSm"
	if cor_rotulo != Color.TRANSPARENT:
		direita.add_theme_color_override("font_color", cor_rotulo)
	direita.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	partes[1].add_child(direita)
	if acao.is_valid():
		var toque: Button = Button.new()
		toque.flat = true
		toque.pressed.connect(acao)
		partes[0].add_child(toque)  # empilha no envelope, cobrindo a linha
	else:
		partes[0].modulate.a = 0.55  # guardando lugar
	return partes[0]


## Slider decorativo do blueprint (áudio guarda lugar até o M3 do som).
func _linha_slider(emoji: String, rotulo: String, fracao: float, divisoria: bool) -> Control:
	var partes: Array = _linha_base(emoji, rotulo, "", divisoria)
	var trilho: Control = Control.new()
	trilho.custom_minimum_size = Vector2(110.0, 24.0)
	trilho.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trilho.draw.connect(func() -> void:
		var meio: float = trilho.size.y * 0.5
		trilho.draw_colored_polygon(DesenhoUi.poligono_arredondado(
			Rect2(0.0, meio - 5.0, trilho.size.x, 10.0), 5.0),
			Color(T.COR_TEXTO_PRIMARIO, 0.1))
		# Preenchimento na MESMA linha do trilho (transform desloca a origem
		# do helper, que desenha em (0,0)).
		trilho.draw_set_transform(Vector2(0.0, meio - 5.0), 0.0, Vector2.ONE)
		DesenhoUi.gradiente_arredondado(trilho,
			Vector2(trilho.size.x * fracao, 10.0), 5.0,
			T.COR_CTA_PRIMARIO_FIM, T.COR_CTA_PRIMARIO_INICIO)
		trilho.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Botão branco com sombrinha, centrado no fim do preenchimento.
		trilho.draw_circle(Vector2(trilho.size.x * fracao, meio) + Vector2(0.0, 1.5),
			12.0, Color(T.COR_APP_FUNDO_INICIO, 0.35))
		trilho.draw_circle(Vector2(trilho.size.x * fracao, meio), 12.0,
			T.COR_TEXTO_PRIMARIO))
	partes[1].add_child(trilho)
	return partes[0]


# ------------------------------------------------------------------ ícones

## ◐ do daltonismo: círculo meio preenchido (semicírculo por polígono).
func _desenhar_icone_daltonismo(alvo: Control) -> void:
	var centro: Vector2 = alvo.size * 0.5
	var raio: float = 9.0
	alvo.draw_arc(centro, raio, 0.0, TAU, 24, T.COR_TEXTO_PRIMARIO, 1.5)
	var pontos: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angulo: float = -PI * 0.5 + PI * float(i) / 12.0
		pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * (raio - 1.0))
	alvo.draw_colored_polygon(pontos, T.COR_TEXTO_PRIMARIO)


## G do Google simplificado (4 arcos coloridos + barra azul).
func _desenhar_g_google(alvo: Control) -> void:
	var centro: Vector2 = alvo.size * 0.5
	var raio: float = 8.0
	var espessura: float = 3.4
	alvo.draw_arc(centro, raio, deg_to_rad(-10.0), deg_to_rad(50.0), 8, Color("#4285F4"), espessura)
	alvo.draw_arc(centro, raio, deg_to_rad(50.0), deg_to_rad(150.0), 10, Color("#34A853"), espessura)
	alvo.draw_arc(centro, raio, deg_to_rad(150.0), deg_to_rad(215.0), 8, Color("#FBBC05"), espessura)
	alvo.draw_arc(centro, raio, deg_to_rad(215.0), deg_to_rad(315.0), 10, Color("#EA4335"), espessura)
	alvo.draw_rect(Rect2(centro + Vector2(0.0, -1.7), Vector2(raio + 1.5, 3.4)), Color("#4285F4"))


## Lixeira desenhada (🗑 cai no U+FE0F): corpo + tampa + alça.
func _desenhar_lixeira(alvo: Control) -> void:
	var centro: Vector2 = alvo.size * 0.5
	var cor: Color = T.COR_COMIDA_COMUM_REALCE
	alvo.draw_rect(Rect2(centro + Vector2(-6.0, -4.0), Vector2(12.0, 12.0)), cor, false, 1.8)
	alvo.draw_line(centro + Vector2(-8.0, -6.0), centro + Vector2(8.0, -6.0), cor, 1.8)
	alvo.draw_line(centro + Vector2(-3.0, -8.5), centro + Vector2(3.0, -8.5), cor, 1.8)
	for dx: float in [-2.5, 2.5]:
		alvo.draw_line(centro + Vector2(dx, -1.5), centro + Vector2(dx, 5.5), cor, 1.4)


# ------------------------------------------------------------ exclusão

## Confirmação dupla da exclusão (mesma semântica da tela Conta).
func _abrir_confirmacao_exclusao() -> void:
	var veu: ColorRect = ColorRect.new()
	veu.color = T.COR_SUPERFICIE_HUD
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veu)
	var centro: CenterContainer = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"ModalPainel"
	centro.add_child(painel)
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_MD)
	painel.add_child(pilha)
	var aviso: Label = Label.new()
	aviso.text = "Isto apaga DEFINITIVAMENTE seu perfil,\nsuas partidas e sua posição no ranking."
	aviso.theme_type_variation = &"TextoPerigo"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(aviso)
	var confirmar: Button = Button.new()
	confirmar.text = "Excluir minha conta definitivamente"
	confirmar.theme_type_variation = &"BotaoDestrutivo"
	confirmar.pressed.connect(func() -> void:
		confirmar.disabled = true
		if await Rede.excluir_conta():
			get_tree().change_scene_to_file(CENA_HOME)
		else:
			confirmar.disabled = false)
	pilha.add_child(confirmar)
	var cancelar: Button = Button.new()
	cancelar.text = "Cancelar"
	cancelar.theme_type_variation = &"BotaoPrimario"
	cancelar.pressed.connect(func() -> void:
		veu.queue_free()
		centro.queue_free())
	pilha.add_child(cancelar)


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return espaco


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
