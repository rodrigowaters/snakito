class_name Ranking
extends Control
## Ranking global da semana (docs §4.1): requer login; estado offline
## elegante. Composição hi-fi (tela 08) fica na pendência de fidelidade.

const T := preload("res://src/ui/theme/tokens.gd")


func _ready() -> void:
	_montar_fundo()
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL)
	margem.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(margem)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_SM)
	margem.add_child(coluna)

	var titulo: Label = Label.new()
	titulo.text = "Ranking da semana"
	titulo.theme_type_variation = &"TituloLg"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)

	if not Rede.logado() or not Rede.tem_perfil():
		_montar_deslogado(coluna)
	else:
		await _montar_lista(coluna)

	var voltar: Button = Button.new()
	voltar.text = "Voltar"
	voltar.theme_type_variation = &"BotaoSecundario"
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/home/home.tscn"))
	coluna.add_child(voltar)


func _montar_deslogado(coluna: VBoxContainer) -> void:
	var aviso: Label = Label.new()
	aviso.text = "Entre com sua conta para competir\nno ranking global"
	aviso.theme_type_variation = &"TextoSecundario"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(aviso)
	var conta: Button = Button.new()
	conta.text = "Ir para a Conta"
	conta.theme_type_variation = &"BotaoPrimario"
	conta.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/conta/conta.tscn"))
	coluna.add_child(conta)


func _montar_lista(coluna: VBoxContainer) -> void:
	var carregando: Label = Label.new()
	carregando.text = "Carregando…"
	carregando.theme_type_variation = &"TextoSecundario"
	carregando.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(carregando)

	var linhas: Array = await Rede.ranking_semanal()
	carregando.queue_free()

	if linhas.is_empty():
		var vazio: Label = Label.new()
		vazio.text = "Ninguém pontuou esta semana ainda.\nSeja a primeira cobra do ranking!"
		vazio.theme_type_variation = &"TextoSecundario"
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coluna.add_child(vazio)
		return

	for linha: Dictionary in linhas:
		coluna.add_child(_item(linha))


func _item(linha: Dictionary) -> PanelContainer:
	var eh_meu: bool = linha.get("username", "") == Rede.username()
	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"CardPainel"
	var conteudo: HBoxContainer = HBoxContainer.new()
	conteudo.add_theme_constant_override("separation", T.ESP_SM)
	painel.add_child(conteudo)

	var posicao: Label = Label.new()
	posicao.text = "%dº" % int(linha.get("posicao", 0))
	posicao.theme_type_variation = &"TituloMd"
	posicao.custom_minimum_size = Vector2(float(T.TOQUE_MIN), 0.0)
	conteudo.add_child(posicao)

	var nome: Label = Label.new()
	nome.text = str(linha.get("username", "?")) + ("  (você)" if eh_meu else "")
	nome.theme_type_variation = &"TextoSucesso" if eh_meu else &"TextoCorpo"
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(nome)

	var pontos: Label = Label.new()
	pontos.text = str(int(linha.get("best_score", 0)))
	pontos.theme_type_variation = &"TituloMd"
	conteudo.add_child(pontos)
	return painel


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
