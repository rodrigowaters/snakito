class_name Ranking
extends Control
## Ranking global — composição fiel ao blueprint "08 Ranking" (M2): pódio
## top 3 com coroa e pedestais, lista com avatar-bolinha e sublinha de
## stats, e a linha "Você" FIXA no rodapé com dica de progresso.
## Adaptações registradas: tabs Mês/Geral guardam lugar (o backend agrega
## por semana ISO — docs §6); avatar é bolinha na cor derivada do apelido
## (não há fotos — coleta mínima).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_HOME: String = "res://src/ui/home/home.tscn"

## Alturas dos pedestais do pódio (blueprint: 1º 64 · 2º 48 · 3º 40).
const PEDESTAL_ALTURAS: Array[float] = [64.0, 48.0, 40.0]
const AVATAR_PODIO: Array[float] = [70.0, 58.0, 58.0]

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
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", T.ESP_SM)
	margem.add_child(_coluna)

	_coluna.add_child(_cabecalho())
	_coluna.add_child(_tabs())

	if not Rede.logado() or not Rede.tem_perfil():
		_montar_deslogado()
	else:
		await _montar_ranking()


# ------------------------------------------------------------------ header

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
	titulo.text = "Ranking"
	titulo.theme_type_variation = &"TituloLg"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(titulo)
	return linha


## Tabs do blueprint: Semana ativa; Mês/Geral guardam lugar (backend agrega
## por semana ISO — períodos extras são decisão futura de produto).
func _tabs() -> Control:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_XS)
	var semana: Button = Button.new()
	semana.flat = true
	semana.custom_minimum_size = Vector2(96.0, 40.0)
	semana.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(semana, semana.size, semana.size.y * 0.5,
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM))
	var rotulo_semana: Label = Label.new()
	rotulo_semana.text = "Semana"
	rotulo_semana.theme_type_variation = &"TextoCorpoSm"
	rotulo_semana.add_theme_color_override("font_color", T.COR_TEXTO_SOBRE_PRIMARIO)
	rotulo_semana.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo_semana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_semana.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo_semana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	semana.add_child(rotulo_semana)
	linha.add_child(semana)
	var tema: Theme = ThemeDB.get_project_theme()
	for nome: String in ["Mês", "Geral"]:
		var tab: Button = Button.new()
		tab.text = nome
		tab.theme_type_variation = &"Chip"
		tab.custom_minimum_size = Vector2(80.0, 40.0)
		tab.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
		tab.disabled = true  # períodos extras: decisão de produto futura
		# Desabilitada mas FIEL: mantém o vidro em pílula e o texto cinza do
		# desenho (o estado disabled padrão troca raio e fundo).
		tab.add_theme_stylebox_override("disabled",
			tema.get_stylebox(&"normal", &"Chip"))
		tab.add_theme_color_override("font_disabled_color", T.COR_TEXTO_SECUNDARIO)
		linha.add_child(tab)
	return linha


# ------------------------------------------------------------------ estados

func _montar_deslogado() -> void:
	var meio: VBoxContainer = VBoxContainer.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_theme_constant_override("separation", T.ESP_MD)
	_coluna.add_child(meio)
	var aviso: Label = Label.new()
	aviso.text = "Entre com sua conta para competir\nno ranking global"
	aviso.theme_type_variation = &"TextoSecundario"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meio.add_child(aviso)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_child(linha)
	var conta: Button = Button.new()
	conta.text = "Ir para a Conta"
	conta.theme_type_variation = &"BotaoPrimario"
	conta.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/conta/conta.tscn"))
	linha.add_child(conta)


func _montar_ranking() -> void:
	var carregando: Label = Label.new()
	carregando.text = "Carregando…"
	carregando.theme_type_variation = &"TextoSecundario"
	carregando.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(carregando)

	var linhas: Array = await Rede.ranking_semanal()
	carregando.queue_free()

	if linhas.is_empty():
		var vazio: Label = Label.new()
		vazio.text = "Ninguém pontuou esta semana ainda.\nSeja a primeira cobra do ranking!"
		vazio.theme_type_variation = &"TextoSecundario"
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_coluna.add_child(vazio)
		return

	# Pódio top 3 (2º · 1º · 3º) + lista rolável do 4º em diante.
	_coluna.add_child(_podio(linhas))
	var rolagem: ScrollContainer = ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_coluna.add_child(rolagem)
	var lista: VBoxContainer = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", T.ESP_XS)
	rolagem.add_child(lista)
	for i: int in range(3, linhas.size()):
		lista.add_child(_item(linhas[i]))

	_coluna.add_child(_linha_voce(linhas))


# -------------------------------------------------------------------- pódio

func _podio(linhas: Array) -> Control:
	var base: HBoxContainer = HBoxContainer.new()
	base.alignment = BoxContainer.ALIGNMENT_CENTER
	base.add_theme_constant_override("separation", T.ESP_SM)
	# Ordem visual do blueprint: 2º · 1º · 3º.
	for indice: int in [1, 0, 2]:
		if indice < linhas.size():
			base.add_child(_coluna_podio(linhas[indice], indice))
	return base


func _coluna_podio(linha: Dictionary, indice: int) -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.alignment = BoxContainer.ALIGNMENT_END
	pilha.add_theme_constant_override("separation", T.ESP_MICRO + 1)

	if indice == 0:
		var coroa: Label = Label.new()
		coroa.text = "👑"
		coroa.theme_type_variation = &"TituloMd"
		coroa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pilha.add_child(coroa)

	var nome_str: String = str(linha.get("username", "?"))
	var avatar: Control = Control.new()
	var lado: float = AVATAR_PODIO[indice]
	avatar.custom_minimum_size = Vector2(lado, lado)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar.draw.connect(func() -> void:
		var centro: Vector2 = avatar.size * 0.5
		var raio: float = lado * 0.5 - 2.0
		var cor: Color = _cor_do_nome(nome_str)
		if indice == 0:  # anel dourado do líder
			avatar.draw_circle(centro, raio + 3.0, T.COR_MOEDA)
		avatar.draw_circle(centro, raio, cor)
		avatar.draw_circle(centro + Vector2(-raio * 0.25, -raio * 0.3),
			raio * 0.55, Color(cor.lightened(0.35), 0.55)))
	pilha.add_child(avatar)

	var nome: Label = Label.new()
	nome.text = nome_str
	nome.theme_type_variation = &"TextoCorpoSm"
	nome.add_theme_color_override("font_color", T.COR_TEXTO_PRIMARIO)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(nome)

	# Pedestal com a posição e o score.
	var pedestal: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	if indice == 0:
		caixa.bg_color = Color(T.COR_MOEDA, 0.1)
		caixa.set_border_width_all(T.BORDA_FINA)
		caixa.border_color = Color(T.COR_MOEDA, 0.3)
	else:
		caixa.bg_color = T.COR_SUPERFICIE_VIDRO
	caixa.corner_radius_top_left = T.RAIO_CHIP
	caixa.corner_radius_top_right = T.RAIO_CHIP
	pedestal.add_theme_stylebox_override("panel", caixa)
	pedestal.custom_minimum_size = Vector2(70.0, PEDESTAL_ALTURAS[indice])
	var conteudo: VBoxContainer = VBoxContainer.new()
	conteudo.alignment = BoxContainer.ALIGNMENT_CENTER
	pedestal.add_child(conteudo)
	var posicao: Label = Label.new()
	posicao.text = "%dº" % int(linha.get("posicao", indice + 1))
	posicao.theme_type_variation = &"TituloMd"
	if indice == 0:
		posicao.add_theme_color_override("font_color", T.COR_MOEDA)
	posicao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(posicao)
	var pontos: Label = Label.new()
	pontos.text = _abreviar(int(linha.get("best_score", 0)))
	pontos.theme_type_variation = &"TextoLegenda"
	pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(pontos)
	pilha.add_child(pedestal)
	return pilha


# -------------------------------------------------------------------- lista

func _item(linha: Dictionary) -> PanelContainer:
	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"CardPainel"
	painel.add_child(_conteudo_linha(linha, false))
	return painel


## Linha "Você" fixa no rodapé (blueprint): destaque verde + dica de subida.
func _linha_voce(linhas: Array) -> Control:
	var minha: Dictionary = {}
	var acima: Dictionary = {}
	for i: int in linhas.size():
		if str(linhas[i].get("username", "")) == Rede.username():
			minha = linhas[i]
			if i > 0:
				acima = linhas[i - 1]
			break

	var painel: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = Color(T.CORES_COBRA_BASE[0], 0.1)
	caixa.set_corner_radius_all(T.RAIO_BOTAO)
	caixa.set_border_width_all(T.BORDA_DESTAQUE)
	caixa.border_color = T.CORES_COBRA_BASE[0]
	caixa.content_margin_left = float(T.ESP_MD)
	caixa.content_margin_right = float(T.ESP_MD)
	caixa.content_margin_top = float(T.ESP_XS)
	caixa.content_margin_bottom = float(T.ESP_XS)
	painel.add_theme_stylebox_override("panel", caixa)

	if minha.is_empty():
		var convite: Label = Label.new()
		convite.text = "Jogue esta semana para entrar no ranking!"
		convite.theme_type_variation = &"TextoCorpoSm"
		convite.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
		convite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		painel.add_child(convite)
		return painel

	var sub: String
	if int(minha.get("posicao", 1)) == 1:
		sub = "você lidera a semana! 👑"
	else:
		var faltam: int = int(acima.get("best_score", 0)) - int(minha.get("best_score", 0)) + 1
		sub = "sobe 1 posição c/ +%s pts" % Hud.formatar_milhar(faltam)
	painel.add_child(_conteudo_linha(minha, true, sub))
	return painel


func _conteudo_linha(linha: Dictionary, eh_voce: bool, sub_custom: String = "") -> Control:
	var conteudo: HBoxContainer = HBoxContainer.new()
	conteudo.add_theme_constant_override("separation", T.ESP_SM)

	var posicao: Label = Label.new()
	posicao.text = "%dº" % int(linha.get("posicao", 0))
	posicao.theme_type_variation = &"TituloMd"
	posicao.add_theme_font_size_override("font_size", T.TAM_CORPO)
	if eh_voce:
		posicao.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	else:
		posicao.add_theme_color_override("font_color", T.COR_TEXTO_SECUNDARIO)
	posicao.custom_minimum_size = Vector2(float(T.ESP_XL) + 4.0, 0.0)
	posicao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	conteudo.add_child(posicao)

	var nome_str: String = str(linha.get("username", "?"))
	var avatar: Control = Control.new()
	avatar.custom_minimum_size = Vector2(34.0, 34.0)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.draw.connect(func() -> void:
		var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()] \
			if eh_voce else _cor_do_nome(nome_str)
		var centro: Vector2 = avatar.size * 0.5
		avatar.draw_circle(centro, 16.0, cor)
		avatar.draw_circle(centro + Vector2(-4.0, -4.5), 8.5,
			Color(cor.lightened(0.35), 0.55)))
	conteudo.add_child(avatar)

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	var nome: Label = Label.new()
	nome.text = "Você" if eh_voce else nome_str
	nome.theme_type_variation = &"TextoCorpo"
	pilha.add_child(nome)
	var sub: Label = Label.new()
	sub.text = sub_custom if sub_custom != "" else "%d caçadas · %d partidas" % [
		int(linha.get("total_kills", 0)), int(linha.get("games", 0))]
	sub.theme_type_variation = &"TextoCorpoSm"
	pilha.add_child(sub)
	conteudo.add_child(pilha)

	var pontos: Label = Label.new()
	pontos.text = _abreviar(int(linha.get("best_score", 0)))
	pontos.theme_type_variation = &"TituloMd"
	pontos.add_theme_font_size_override("font_size", T.TAM_CORPO)
	pontos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	conteudo.add_child(pontos)
	return conteudo


# ------------------------------------------------------------------ apoio

## Cor estável derivada do apelido (não há fotos — coleta mínima).
func _cor_do_nome(nome: String) -> Color:
	return T.CORES_COBRA_BASE[abs(nome.hash()) % T.CORES_COBRA_BASE.size()]


## 61712 → "61.7k"; abaixo de mil, milhar normal.
static func _abreviar(valor: int) -> String:
	if valor >= 1000:
		return "%.1fk" % (float(valor) / 1000.0)
	return str(valor)


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
