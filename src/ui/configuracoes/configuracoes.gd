class_name Configuracoes
extends Control
## Configurações — composição fiel ao blueprint "10" (M3). Funcionais desde
## já: Vibração, Lado do turbo (canhotos — pedido de playtest 13/08; o modo
## daltonismo foi REMOVIDO na mesma decisão),
## Sair e Excluir conta. Sons/Música são TOGGLES
## por decisão de 13/08 (o desenho tinha sliders; liga/desliga é mais
## simples p/ 7+) — persistem e o som consome no M3-sons. "Remover
## anúncios" navega para a Loja (aba Pacotes). Guarda lugar: Idioma
## (i18n M3). Restaurar compras chama o Play; Privacidade abre o
## formulário do UMP quando o consentimento exigir revisão.

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
	# Layout FIXO como o blueprint (decisão 13/08 após 2 rodadas): o conteúdo
	# cabe garantido no stretch de celular (412×915+); scroll em tela com
	# botões de linha briga com o touch do aparelho (rota touch→mouse — a
	# armadilha do joystick). Se uma tela transbordar de verdade (Loja),
	# resolve-se lá com validação no aparelho.
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", T.ESP_XS + 2)
	margem.add_child(_coluna)
	_montar_conteudo()


func _montar_conteudo() -> void:
	_coluna.add_child(_cabecalho())

	_coluna.add_child(_titulo_secao("ÁUDIO"))
	var audio: VBoxContainer = _card_lista()
	# TOGGLES por decisão (13/08 — o desenho tinha sliders): liga/desliga é
	# mais simples para 7+; persistem e o som consome no M3-sons.
	audio.add_child(_linha_toggle("🔊", "Sons do jogo", "",
		ProgressoLocal.sons_ligados(),
		func(ligados: bool) -> void: ProgressoLocal.definir_sons(ligados), true))
	audio.add_child(_linha_toggle("🎵", "Música", "",
		ProgressoLocal.musica_ligada(),
		func(ligada: bool) -> void: ProgressoLocal.definir_musica(ligada), false))

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
	# No lugar do modo daltonismo (REMOVIDO em 13/08 por decisão do Rodrigo
	# após playtest): lado do botão de turbo, para canhotos.
	jogo.add_child(_linha_lado_turbo(false))

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
	# Opções de privacidade do UMP: existem só quando o consentimento foi
	# dado e o GDPR exige poder revisá-lo (regra do próprio UMP).
	conta.add_child(_linha_navegacao("🔒", "Privacidade e responsáveis", "›",
		(Anuncios.abrir_privacidade) if Anuncios.privacidade_disponivel() \
			else Callable(),
		true))
	conta.add_child(_linha_navegacao("🚫", "Remover anúncios", "›",
		func() -> void:
			Loja.proxima_aba = Loja.Aba.PACOTES
			get_tree().change_scene_to_file("res://src/ui/loja/loja.tscn"),
		true))
	# Restaurar compras: pergunta ao Play o que a conta possui e revalida
	# (rede de segurança de quem trocou de aparelho). Exige loja pronta.
	conta.add_child(_linha_navegacao("🔄", "Restaurar compras", "›",
		(Compras.restaurar) if Compras.disponivel() else Callable(), true))
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
	# `deslize` anima 0..1 (playtest 13/08: "podia ter uma animação").
	var deslize: Array[float] = [1.0 if ativo else 0.0]
	interruptor.draw.connect(func() -> void:
		var caixa: Rect2 = Rect2(Vector2.ZERO, interruptor.size)
		var f: float = deslize[0]
		# Fundo: mistura vidro→gradiente conforme o deslize.
		interruptor.draw_colored_polygon(DesenhoUi.poligono_arredondado(
			caixa, caixa.size.y * 0.5), Color(T.COR_TEXTO_PRIMARIO, 0.12))
		if f > 0.01:
			DesenhoUi.gradiente_arredondado(interruptor, interruptor.size,
				caixa.size.y * 0.5,
				Color(T.COR_CTA_PRIMARIO_INICIO, f), Color(T.COR_CTA_PRIMARIO_FIM, f))
		var raio_botao: float = caixa.size.y * 0.5 - 4.0
		var x: float = lerpf(raio_botao + 4.0, caixa.size.x - raio_botao - 4.0, f)
		interruptor.draw_circle(Vector2(x, caixa.size.y * 0.5), raio_botao,
			T.COR_TEXTO_MUTED.lerp(T.COR_TEXTO_PRIMARIO, f)))
	interruptor.pressed.connect(func() -> void:
		estado[0] = not estado[0]
		acao.call(estado[0])
		var tween: Tween = interruptor.create_tween()
		tween.tween_method(func(valor: float) -> void:
			deslize[0] = valor
			interruptor.queue_redraw(),
			deslize[0], 1.0 if estado[0] else 0.0, 0.18) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC))
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


## Linha "Lado do turbo": seletor de dois estados (Esquerda | Direita).
## O joystick flutuante nasce onde o dedo toca — só o botão muda de canto.
func _linha_lado_turbo(divisoria: bool) -> Control:
	# Sem subtítulo: a largura MÍNIMA de rótulo+sub+2 chips passava da tela
	# e o card comia o respiro lateral (mesma armadilha da Loja).
	var partes: Array = _linha_base("⚡", "Lado do turbo", "", divisoria)
	var seletor: HBoxContainer = HBoxContainer.new()
	seletor.add_theme_constant_override("separation", T.ESP_MICRO + 2)
	seletor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var chips: Array[Control] = []
	for opcao: Array in [["Esquerda", true], ["Direita", false]]:
		var rotulo_opcao: String = opcao[0]
		var valor: bool = opcao[1]
		var chip: PanelContainer = PanelContainer.new()
		chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		chip.custom_minimum_size = Vector2(74.0, 34.0)
		var rotulo: Label = Label.new()
		rotulo.text = rotulo_opcao
		rotulo.theme_type_variation = &"TextoCorpo"
		rotulo.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_child(rotulo)
		chip.draw.connect(func() -> void:
			var ativa: bool = ProgressoLocal.turbo_a_esquerda() == valor
			if ativa:
				DesenhoUi.gradiente_arredondado(chip, chip.size, chip.size.y * 0.5,
					T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM)
			else:
				chip.draw_colored_polygon(DesenhoUi.poligono_arredondado(
					Rect2(Vector2.ZERO, chip.size), chip.size.y * 0.5),
					T.COR_SUPERFICIE_VIDRO)
			rotulo.add_theme_color_override("font_color",
				T.COR_TEXTO_SOBRE_PRIMARIO if ativa else T.COR_TEXTO_SECUNDARIO))
		var toque: Button = Button.new()
		toque.flat = true
		for estado: StringName in [&"normal", &"pressed", &"hover", &"focus"]:
			toque.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
		toque.pressed.connect(func() -> void:
			ProgressoLocal.definir_turbo_esquerda(valor)
			for c: Control in chips:
				c.queue_redraw())
		chip.add_child(toque)
		chips.append(chip)
		seletor.add_child(chip)
	partes[1].add_child(seletor)
	return partes[0]


# ------------------------------------------------------------------ ícones

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
