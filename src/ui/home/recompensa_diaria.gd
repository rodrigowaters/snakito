class_name RecompensaDiaria
extends CanvasLayer
## Modal da Recompensa diária — composição fiel ao blueprint "01b".
## Aparece na 1ª abertura do dia (gatilho na Home, spec dos tokens);
## coletar credita as moedas e fecha. Sequência de 7 dias: perder um dia
## reinicia; dia 7 vale em dobro (👑).

const T := preload("res://src/ui/theme/tokens.gd")

signal coletada

var _dia: int = 1


## CanvasLayer como o Renascimento (04b): filhos FULL_RECT ancoram na
## viewport — Control programático com anchors em _ready fica 0×0 (a
## armadilha registrada de anchors).
func _ready() -> void:
	layer = 10
	_dia = Economia.dia_para_coletar()

	# Véu escuro do blueprint (78%) — segura o toque atrás da modal.
	var veu: ColorRect = ColorRect.new()
	veu.color = Color(T.COR_APP_FUNDO_INICIO.darkened(0.4), 0.78)
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veu)

	var centro: CenterContainer = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(364.0, 0.0)  # 412 − 24px por lado
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = T.COR_SUPERFICIE_MODAL
	caixa.border_color = T.COR_SUPERFICIE_VIDRO_BORDA
	caixa.set_border_width_all(1)
	caixa.set_corner_radius_all(T.RAIO_MODAL)
	caixa.content_margin_left = float(T.ESP_MD) + 4.0
	caixa.content_margin_right = float(T.ESP_MD) + 4.0
	caixa.content_margin_top = float(T.ESP_LG)
	caixa.content_margin_bottom = float(T.ESP_LG)
	card.add_theme_stylebox_override("panel", caixa)
	centro.add_child(card)

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_MD)
	card.add_child(pilha)

	pilha.add_child(_cabecalho())
	pilha.add_child(_grade_dias())
	pilha.add_child(_cta())

	var rodape: Label = Label.new()
	var proximo: int = _dia % Economia.RECOMPENSAS_DIARIAS.size() + 1
	rodape.text = "Volte amanhã para o dia %d · perder um dia reinicia a sequência" % proximo
	rodape.theme_type_variation = &"TextoLegenda"
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pilha.add_child(rodape)


func _cabecalho() -> Control:
	var topo: VBoxContainer = VBoxContainer.new()
	topo.add_theme_constant_override("separation", T.ESP_MICRO)
	var presente: Label = Label.new()
	presente.text = "🎁"
	presente.add_theme_font_size_override("font_size", T.TAM_TITULO_LG + 4)
	presente.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo.add_child(presente)
	var titulo: Label = Label.new()
	titulo.text = "Recompensa diária"
	titulo.theme_type_variation = &"TituloLg"
	titulo.add_theme_font_size_override("font_size", T.TAM_TITULO_LG - 2)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo.add_child(titulo)
	var legenda: Label = Label.new()
	legenda.text = "DIA %d DA SUA SEQUÊNCIA" % _dia
	legenda.theme_type_variation = &"TextoLegenda"
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo.add_child(legenda)
	return topo


## Grade do blueprint: dias 1–4 em cima; 5, 6 e o dia 7 (dobro, span 2)
## embaixo. Passado = ✓ verde · hoje = destaque azul · futuro = apagado.
func _grade_dias() -> Control:
	var linhas: VBoxContainer = VBoxContainer.new()
	linhas.add_theme_constant_override("separation", T.ESP_XS)
	var cima: HBoxContainer = HBoxContainer.new()
	cima.add_theme_constant_override("separation", T.ESP_XS)
	for dia: int in [1, 2, 3, 4]:
		cima.add_child(_chip_dia(dia, 1))
	linhas.add_child(cima)
	var baixo: HBoxContainer = HBoxContainer.new()
	baixo.add_theme_constant_override("separation", T.ESP_XS)
	baixo.add_child(_chip_dia(5, 1))
	baixo.add_child(_chip_dia(6, 1))
	baixo.add_child(_chip_dia(7, 2))
	linhas.add_child(baixo)
	return linhas


func _chip_dia(dia: int, colunas: int) -> Control:
	var passado: bool = dia < _dia
	var hoje: bool = dia == _dia
	var dobro: bool = dia == Economia.RECOMPENSAS_DIARIAS.size()
	var chip: PanelContainer = PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.size_flags_stretch_ratio = float(colunas)
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.set_corner_radius_all(T.RAIO_CHIP + 2)
	caixa.set_content_margin_all(float(T.ESP_XS))
	if hoje:
		caixa.bg_color = Color(T.COR_INFO, 0.1)
		caixa.border_color = T.COR_FOCO
		caixa.set_border_width_all(2)
	elif passado:
		caixa.bg_color = Color(T.COR_SUCESSO, 0.08)
		caixa.border_color = Color(T.COR_SUCESSO, 0.35)
		caixa.set_border_width_all(1)
	elif dobro:
		caixa.bg_color = Color(T.COR_ALERTA, 0.08)
		caixa.border_color = T.COR_ALERTA
		caixa.set_border_width_all(1)
	else:
		caixa.bg_color = T.COR_FUNDO_DESABILITADO
		caixa.border_color = T.COR_CARD_BORDA
		caixa.set_border_width_all(1)
	chip.add_theme_stylebox_override("panel", caixa)
	if passado:
		chip.modulate.a = 0.65

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.add_theme_constant_override("separation", 3)
	chip.add_child(pilha)

	var rotulo: Label = Label.new()
	rotulo.text = "DIA %d · EM DOBRO" % dia if dobro else ("HOJE" if hoje else "DIA %d" % dia)
	rotulo.theme_type_variation = &"TextoLegenda"
	rotulo.add_theme_font_size_override("font_size", T.TAM_LEGENDA - 3)
	if hoje:
		rotulo.add_theme_color_override("font_color", T.COR_INFO)
	elif dobro:
		rotulo.add_theme_color_override("font_color", T.COR_ALERTA)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(rotulo)

	# Miolo: ✓ nos coletados, 👑 no dia 7, moedinha nos demais.
	if passado:
		var ok: Label = Label.new()
		ok.text = "✓"
		ok.theme_type_variation = &"TextoCorpoSm"
		ok.add_theme_color_override("font_color", T.COR_SUCESSO)
		ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pilha.add_child(ok)
	elif dobro and not hoje:
		var coroa: Label = Label.new()
		coroa.text = "👑"
		coroa.add_theme_font_size_override("font_size", T.TAM_CORPO)
		coroa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pilha.add_child(coroa)
	else:
		var moeda: Control = Control.new()
		moeda.custom_minimum_size = Vector2(0.0, 16.0)
		var raio: float = 8.0 if hoje else 7.0
		moeda.draw.connect(func() -> void:
			DesenhoUi.moedinha(moeda, moeda.size * 0.5, raio))
		if not hoje:
			moeda.modulate.a = 0.5
		pilha.add_child(moeda)

	var valor: Label = Label.new()
	valor.text = str(Economia.RECOMPENSAS_DIARIAS[dia - 1])
	valor.theme_type_variation = &"TextoCorpoSm"
	valor.add_theme_font_size_override("font_size", T.TAM_LEGENDA - 1)
	if dobro:
		valor.add_theme_color_override("font_color", T.COR_ALERTA)
	elif not hoje:
		valor.add_theme_color_override("font_color", T.COR_TEXTO_SECUNDARIO)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(valor)
	return chip


func _cta() -> Control:
	var botao: Button = Button.new()
	botao.theme_type_variation = &"BotaoPrimario"
	botao.text = "Coletar +%d" % Economia.RECOMPENSAS_DIARIAS[_dia - 1]
	botao.custom_minimum_size = Vector2(0.0, float(T.TOQUE_PADRAO))
	botao.pressed.connect(func() -> void:
		Economia.coletar_diaria()
		coletada.emit()
		queue_free())
	return botao
