class_name InfoJogador
extends Control
## Informações do jogador — composição fiel ao blueprint "02b" (M2+).
## Adaptações registradas: "FASES VENCIDAS" vira "DESAFIOS VENCIDOS" (fases
## são pós-lançamento); recorde/abates são estatísticas LOCAIS acumuladas
## (offline-first); "✏️ Editar apelido" guarda lugar (edição pede policy de
## UPDATE no perfil — M3); Skins mostra a coleção atual (4 grátis); Evolução
## e o card JORNADA guardam lugar apagados; botão "Conta e segurança" é
## adaptação nossa (o avatar da Home agora abre ESTA tela — a Conta precisa
## de porta).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_HOME: String = "res://src/ui/home/home.tscn"

## Meses para "jogando desde {mês}" (i18n no M3).
const MESES: Array[String] = [
	"janeiro", "fevereiro", "março", "abril", "maio", "junho",
	"julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
]


func _ready() -> void:
	if not Rede.logado() or not Rede.tem_perfil():
		# Sem perfil não há o que mostrar — a Conta assume.
		get_tree().change_scene_to_file.call_deferred("res://src/ui/conta/conta.tscn")
		return
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
	coluna.add_child(_perfil())
	coluna.add_child(_cards_stats())
	coluna.add_child(_inventario())
	coluna.add_child(_jornada())
	coluna.add_child(_espaco_flexivel())
	# Decisão 13/08: sem botão de Conta aqui — sair/excluir/apelido vão
	# morar na tela de Configurações (M3, atrás do ⚙ da Home). Até lá, a
	# gestão de conta fica sem porta para quem está logado com perfil.


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
	titulo.text = "Informações do jogador"
	titulo.theme_type_variation = &"TituloLg"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(titulo)
	return linha


## Avatar grande + nome + "jogando desde…" + pill editar (guarda lugar).
func _perfil() -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.add_theme_constant_override("separation", T.ESP_XS + 2)

	var chip: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = T.COR_SUPERFICIE_VIDRO
	caixa.set_corner_radius_all(T.RAIO_MODAL + 2)
	caixa.set_border_width_all(T.BORDA_FINA)
	caixa.border_color = T.COR_SUPERFICIE_VIDRO_BORDA
	chip.add_theme_stylebox_override("panel", caixa)
	chip.custom_minimum_size = Vector2(96.0, 96.0)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var cara: Control = Control.new()
	cara.custom_minimum_size = Vector2(96.0, 96.0)
	cara.draw.connect(func() -> void:
		_desenhar_cara_grande(cara))
	chip.add_child(cara)
	pilha.add_child(chip)

	var nome: Label = Label.new()
	nome.text = Rede.username()
	nome.theme_type_variation = &"TituloLg"
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(nome)

	var sub: Label = Label.new()
	sub.text = "%s · skin %s" % [_texto_desde(), _nome_da_skin()]
	sub.theme_type_variation = &"TextoCorpoSm"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(sub)

	var linha_editar: HBoxContainer = HBoxContainer.new()
	linha_editar.alignment = BoxContainer.ALIGNMENT_CENTER
	var editar: Button = Button.new()
	editar.text = "Editar apelido"
	editar.theme_type_variation = &"Chip"
	editar.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	editar.icon = _textura_lapis()
	editar.add_theme_color_override("icon_normal_color", Color.WHITE)  # sem tingir
	editar.pressed.connect(_abrir_edicao_apelido.bind(nome))
	linha_editar.add_child(editar)
	pilha.add_child(linha_editar)
	return pilha


## Modal de edição do apelido (policy 0006: dono atualiza só o username).
func _abrir_edicao_apelido(rotulo_nome: Label) -> void:
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

	var titulo: Label = Label.new()
	titulo.text = "Novo apelido"
	titulo.theme_type_variation = &"TituloMd"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(titulo)
	var aviso: Label = Label.new()
	aviso.text = "Sem nome real — é público no ranking!"
	aviso.theme_type_variation = &"TextoCorpoSm"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(aviso)
	var campo: LineEdit = LineEdit.new()
	campo.text = Rede.username()
	campo.max_length = 20
	campo.custom_minimum_size = Vector2(240.0, 0.0)
	pilha.add_child(campo)
	var erro: Label = Label.new()
	erro.theme_type_variation = &"TextoPerigo"
	erro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(erro)

	var salvar: Button = Button.new()
	salvar.text = "Salvar"
	salvar.theme_type_variation = &"BotaoPrimario"
	salvar.pressed.connect(func() -> void:
		salvar.disabled = true
		var motivo: String = await Rede.renomear(campo.text.strip_edges())
		if motivo == "":
			rotulo_nome.text = Rede.username()
			veu.queue_free()
			centro.queue_free()
		else:
			erro.text = motivo
			salvar.disabled = false)
	pilha.add_child(salvar)
	var cancelar: Button = Button.new()
	cancelar.text = "Cancelar"
	cancelar.theme_type_variation = &"BotaoSecundario"
	cancelar.pressed.connect(func() -> void:
		veu.queue_free()
		centro.queue_free())
	pilha.add_child(cancelar)
	campo.grab_focus()


## Lápis desenhado (✏️ cai na armadilha do U+FE0F): corpo âmbar na diagonal,
## ponta escura e borracha rosa, gerado como textura de ícone.
func _textura_lapis() -> Texture2D:
	var lado: int = T.ESP_MD
	var imagem: Image = Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var corpo: Color = T.COR_MOEDA
	var ponta: Color = T.COR_APP_FUNDO_INICIO
	var borracha: Color = T.CORES_COBRA_BASE[2]
	for i: int in lado:
		for j: int in lado:
			# Diagonal (ponta embaixo-esquerda, borracha em cima-direita):
			# distância ao eixo x=y controla a espessura.
			var ao_longo: float = float(i + (lado - 1 - j)) / float(2 * lado - 2)
			var afastamento: int = absi(i - (lado - 1 - j))
			if afastamento > 3:
				continue
			if ao_longo < 0.22:
				imagem.set_pixel(i, j, ponta if afastamento <= 1 else corpo.darkened(0.25))
			elif ao_longo > 0.82:
				imagem.set_pixel(i, j, borracha)
			else:
				imagem.set_pixel(i, j, corpo)
	return ImageTexture.create_from_image(imagem)


## Cabeça 72px do blueprint: olhos grandes + boca aberta sorrindo (arco em U).
func _desenhar_cara_grande(alvo: Control) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	var centro: Vector2 = alvo.size * 0.5
	var raio: float = 36.0
	alvo.draw_circle(centro, raio, cor)
	alvo.draw_circle(centro + Vector2(-raio * 0.25, -raio * 0.3), raio * 0.55,
		Color(cor.lightened(0.35), 0.55))
	for lado: float in [-1.0, 1.0]:
		var olho: Vector2 = centro + Vector2(lado * raio * 0.33, -raio * 0.18)
		alvo.draw_circle(olho, raio * 0.19, T.COR_SIMBOLO_DALTONISMO)
		alvo.draw_circle(olho + Vector2(raio * 0.04, raio * 0.04),
			raio * 0.1, T.COR_APP_FUNDO_INICIO)
	# Boca aberta em "U" (borda grossa, sem topo — como no desenho).
	alvo.draw_arc(centro + Vector2(0.0, raio * 0.28), raio * 0.3,
		deg_to_rad(15.0), deg_to_rad(165.0), 14, T.COR_APP_FUNDO_INICIO, 4.0)


func _texto_desde() -> String:
	var iso: String = Rede.criado_em()
	if iso.length() < 7:
		return "jogando com a gente"
	var mes: int = int(iso.substr(5, 2))
	if mes < 1 or mes > 12:
		return "jogando com a gente"
	return "jogando desde %s" % MESES[mes - 1]


func _nome_da_skin() -> String:
	var indice: int = ProgressoLocal.skin_equipada()
	for skin: Dictionary in CatalogoSkins.SKINS:
		if int(skin["indice"]) == indice:
			return str(skin["nome"])
	return "própria"


## Grid dos 3 cards de estatística (verde / amarelo / azul).
func _cards_stats() -> Control:
	var desafios_vencidos: int = 0
	for desafio: ChallengeRules.Desafio in ChallengeRules.Desafio.values():
		if ProgressoLocal.desafio_concluido(desafio):
			desafios_vencidos += 1

	var grade: GridContainer = GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", T.ESP_XS + 2)
	grade.add_child(_card_stat(str(desafios_vencidos), "DESAFIOS\nVENCIDOS",
		T.CORES_COBRA_BASE[0]))
	grade.add_child(_card_stat(Hud.formatar_milhar(ProgressoLocal.recorde_pontos()),
		"RECORDE DE\nPONTOS", T.COR_MOEDA))
	grade.add_child(_card_stat(Hud.formatar_milhar(ProgressoLocal.total_abates()),
		"COBRAS\nDEVORADAS", T.CORES_COBRA_BASE[1]))
	return grade


func _card_stat(valor: String, rotulo: String, cor: Color) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.add_theme_constant_override("separation", T.ESP_MICRO)
	card.add_child(pilha)
	var numero: Label = Label.new()
	numero.text = valor
	numero.theme_type_variation = &"TituloMd"
	numero.add_theme_color_override("font_color", cor)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(numero)
	var etiqueta: Label = Label.new()
	etiqueta.text = rotulo
	etiqueta.theme_type_variation = &"TextoLegenda"
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(etiqueta)
	return card


## Lista do inventário: moedas, tickets, skins, evolução (em breve).
func _inventario() -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", 0)
	card.add_child(pilha)
	# Moedinha e seta da Evolução desenhadas (🪙/⬆️ caem na armadilha do
	# emoji — render monocromático).
	pilha.add_child(_linha_inventario("", "Moedas",
		Hud.formatar_milhar(ProgressoLocal.moedas()), T.COR_MOEDA, true,
		func(alvo: Control) -> void:
			DesenhoUi.moedinha(alvo, alvo.size * 0.5, 10.0)))
	pilha.add_child(_linha_inventario("🎟️", "Tickets de pulo",
		str(ProgressoLocal.tickets()), T.COR_TEXTO_PRIMARIO, true))
	pilha.add_child(_linha_inventario("🐍", "Skins na coleção",
		"%d / %d" % [CatalogoSkins.SKINS.size(), CatalogoSkins.SKINS.size()],
		T.COR_TEXTO_PRIMARIO, true))
	var evolucao: Control = _linha_inventario("", "Evolução", "em breve",
		T.COR_TEXTO_SECUNDARIO, false,
		func(alvo: Control) -> void:
			var lado: float = 20.0
			DesenhoUi.icone_evolucao(alvo, Rect2(
				Vector2((alvo.size.x - lado) * 0.5, (alvo.size.y - lado) * 0.5),
				Vector2(lado, lado))))
	evolucao.modulate.a = 0.55  # guardando lugar (pós-lançamento)
	pilha.add_child(evolucao)
	return card


func _linha_inventario(
	emoji: String,
	rotulo: String,
	valor: String,
	cor_valor: Color,
	divisoria: bool,
	desenho: Callable = Callable(),
) -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	var linha: HBoxContainer = HBoxContainer.new()
	linha.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN) + 2.0)
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
	var nome: Label = Label.new()
	nome.text = rotulo
	nome.theme_type_variation = &"TextoCorpo"
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(nome)
	var numero: Label = Label.new()
	numero.text = valor
	numero.theme_type_variation = &"TituloMd"
	numero.add_theme_font_size_override("font_size", T.TAM_CORPO + 1)
	numero.add_theme_color_override("font_color", cor_valor)
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(numero)
	if divisoria:
		var traco: ColorRect = ColorRect.new()
		traco.color = Color(T.COR_TEXTO_PRIMARIO, 0.07)
		traco.custom_minimum_size = Vector2(0.0, 1.0)
		pilha.add_child(traco)
	return pilha


## Card JORNADA — guarda lugar (mapa/fases são pós-lançamento).
func _jornada() -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS)
	card.add_child(pilha)
	var titulo: Label = Label.new()
	titulo.text = "JORNADA"
	titulo.theme_type_variation = &"TextoLegenda"
	pilha.add_child(titulo)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	pilha.add_child(linha)
	var fase: Label = Label.new()
	fase.text = "Fase 1 de 30"
	fase.theme_type_variation = &"TextoCorpoSm"
	linha.add_child(fase)
	var barra: Control = Control.new()
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.custom_minimum_size = Vector2(0.0, 10.0)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.draw.connect(func() -> void:
		barra.draw_colored_polygon(DesenhoUi.poligono_arredondado(
			Rect2(Vector2.ZERO, barra.size), 5.0),
			Color(T.COR_TEXTO_PRIMARIO, 0.08)))
	linha.add_child(barra)
	var bioma: Label = Label.new()
	bioma.text = "🌊 Oceano"
	bioma.theme_type_variation = &"TextoCorpoSm"
	bioma.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	linha.add_child(bioma)
	card.modulate.a = 0.55  # guardando lugar (pós-lançamento)
	return card


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return espaco
