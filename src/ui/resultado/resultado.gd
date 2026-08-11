class_name Resultado
extends Control
## Tela pós-partida — composição fiel ao blueprint "05 Pós-partida" (8c) do
## Claude Design, M2. Adaptações registradas: aba "Ranking da fase" guarda
## lugar (fases são pós-lançamento); "Moedas ganhas" exibida zerada (economia
## liga no M3); ⇪ Compartilhar guarda lugar (plugin de share é M3); emojis
## ⚔/⏱ trocados por 🏹/⏳ (Godot ignora U+FE0F e renderizava monocromático).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"


func _ready() -> void:
	var motor: GameEngine = Sessao.ultimo_motor
	if motor == null:
		# Cena aberta sem partida (ex.: rodada direto no editor) — volta à Home.
		get_tree().change_scene_to_file.call_deferred(CENA_HOME)
		return
	_montar_fundo()
	_montar_conteudo(motor)


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


func _montar_conteudo(motor: GameEngine) -> void:
	var jogador: SnakeModel = motor.jogador()
	var regras: ChallengeRules = Sessao.regras_desafio

	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_MD + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_bottom", T.ESP_LG + T.ESP_MICRO)
	add_child(margem)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_SM)
	margem.add_child(coluna)

	coluna.add_child(_abas())
	coluna.add_child(_cabecalho(motor, jogador, regras))
	coluna.add_child(_linhas_de_pontos(jogador))

	# Análise estratégica v1 (docs §4.3): o que aprender desta partida.
	var achados: Array[StrategyAnalyzer.Achado] = \
		StrategyAnalyzer.analisar(motor, regras)
	if not achados.is_empty():
		coluna.add_child(_card_analise(achados))

	# Seed + repetir (Arcade; desafio é sempre a mesma arena por definição).
	if regras == null:
		coluna.add_child(_linha_seed(motor))

	coluna.add_child(_espaco_flexivel())
	coluna.add_child(_botoes_finais(regras))


# ---------------------------------------------------------------------- topo

## Abas do blueprint: Resultado ativa; "Ranking da fase" guarda o lugar
## (fases/tela 06 são pós-lançamento).
func _abas() -> Control:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_XS)
	var ativa: Button = Button.new()
	ativa.flat = true
	ativa.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN) - float(T.ESP_MICRO))
	ativa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ativa.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(ativa, ativa.size, ativa.size.y * 0.5,
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM))
	var rotulo_ativa: Label = Label.new()
	rotulo_ativa.text = "Resultado"
	rotulo_ativa.theme_type_variation = &"TextoCorpoSm"
	rotulo_ativa.add_theme_color_override("font_color", T.COR_TEXTO_SOBRE_PRIMARIO)
	rotulo_ativa.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo_ativa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_ativa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo_ativa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ativa.add_child(rotulo_ativa)
	linha.add_child(ativa)

	var futura: Button = Button.new()
	futura.text = "Ranking da fase"
	futura.theme_type_variation = &"Chip"
	futura.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN) - float(T.ESP_MICRO))
	futura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	futura.disabled = true
	futura.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	linha.add_child(futura)
	return linha


## Cabeçalho do blueprint: legenda · posição gigante amarela · recorde.
func _cabecalho(motor: GameEngine, jogador: SnakeModel, regras: ChallengeRules) -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.add_theme_constant_override("separation", T.ESP_MICRO)

	# A morte tem tela própria (04b Renascimento) — aqui é só o contexto,
	# como no blueprint 05 ("FASE OCEANO · 28 COBRAS"; sem fases: ARENA).
	var legenda: Label = Label.new()
	legenda.text = "ARENA · %d COBRAS" % motor.arena.cobras.size()
	legenda.theme_type_variation = &"TextoLegenda"
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(legenda)

	var posicao_atual: int = motor.posicao_no_ranking(jogador)
	var posicao: Label = Label.new()
	posicao.text = "%dº" % posicao_atual
	posicao.theme_type_variation = &"TituloPosicao"
	posicao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(posicao)

	var sub: Label = Label.new()
	if regras == null:
		# Recorde local do Arcade (blueprint: "sua melhor posição até hoje!").
		sub.text = "sua melhor posição até hoje!" \
			if ProgressoLocal.registrar_posicao(posicao_atual) \
			else "seu recorde: %dº" % ProgressoLocal.melhor_posicao()
	else:
		sub.text = _texto_desafio(regras)
	sub.theme_type_variation = &"TextoSecundario"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(sub)
	return pilha


# ------------------------------------------------------------------- pontos

## Linhas do blueprint: cada parcela num card de vidro; TOTAL sem fundo em
## verde; "Moedas ganhas" em card âmbar (zerada — economia liga no M3).
func _linhas_de_pontos(jogador: SnakeModel) -> Control:
	var pontos_comida: int = jogador.comidas * GameEngine.PONTOS_COMIDA
	@warning_ignore("integer_division")
	var segundos: int = jogador.ticks_vividos / GameEngine.TICKS_POR_SEGUNDO
	var pontos_sobrevivencia: int = segundos * GameEngine.PONTOS_POR_SEGUNDO
	# Abates ficam com o restante (a curva por vítima não é reconstituível
	# só das estatísticas agregadas).
	var pontos_abates: int = jogador.pontos - pontos_comida - pontos_sobrevivencia

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS)
	pilha.add_child(_linha_card("🍎", "Comida · %d itens" % jogador.comidas,
		"+%s" % Hud.formatar_milhar(pontos_comida), T.COR_TEXTO_PRIMARIO))
	pilha.add_child(_linha_card("🏹", "Caçadas · %d cobras devoradas" % jogador.abates,
		"+%s" % Hud.formatar_milhar(pontos_abates), T.COR_TEXTO_PRIMARIO))
	@warning_ignore("integer_division")
	pilha.add_child(_linha_card("⏳", "Sobrevivência · %d:%02d" % [segundos / 60, segundos % 60],
		"+%s" % Hud.formatar_milhar(pontos_sobrevivencia), T.COR_TEXTO_PRIMARIO))

	# TOTAL: sem fundo, valor grande em verde (blueprint).
	var total: HBoxContainer = HBoxContainer.new()
	var rotulo_total: Label = Label.new()
	rotulo_total.text = "TOTAL"
	rotulo_total.theme_type_variation = &"TextoLegenda"
	rotulo_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotulo_total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total.add_child(rotulo_total)
	var valor_total: Label = Label.new()
	valor_total.text = Hud.formatar_milhar(jogador.pontos)
	valor_total.theme_type_variation = &"TituloLg"
	valor_total.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	total.add_child(valor_total)
	var total_margem: MarginContainer = MarginContainer.new()
	for lado: String in ["left", "right"]:
		total_margem.add_theme_constant_override("margin_" + lado, T.ESP_MD)
	total_margem.add_child(total)
	pilha.add_child(total_margem)

	pilha.add_child(_linha_moedas())
	return pilha


func _linha_card(emoji: String, texto: String, valor: String, cor_valor: Color) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	card.add_child(linha)
	var icone: Label = Label.new()
	icone.text = emoji
	icone.theme_type_variation = &"TextoCorpo"
	icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(icone)
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = &"TextoSecundario"
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(rotulo)
	var numero: Label = Label.new()
	numero.text = valor
	numero.theme_type_variation = &"TituloMd"
	numero.add_theme_color_override("font_color", cor_valor)
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(numero)
	return card


## "Moedas ganhas" (blueprint): card âmbar com a moedinha desenhada.
## Zerada até a economia ligar (M3 — regra do design: ~5% dos pontos).
func _linha_moedas() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = Color(T.COR_MOEDA, 0.08)
	caixa.set_corner_radius_all(T.RAIO_BOTAO)
	caixa.set_border_width_all(T.BORDA_FINA)
	caixa.border_color = Color(T.COR_MOEDA, 0.3)
	caixa.content_margin_left = float(T.ESP_MD)
	caixa.content_margin_right = float(T.ESP_MD)
	caixa.content_margin_top = float(T.ESP_SM)
	caixa.content_margin_bottom = float(T.ESP_SM)
	card.add_theme_stylebox_override("panel", caixa)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	card.add_child(linha)
	var moeda: Control = Control.new()
	moeda.custom_minimum_size = Vector2(float(T.ESP_MD) + 2.0, 0.0)
	moeda.draw.connect(func() -> void:
		var centro: Vector2 = moeda.size * 0.5
		moeda.draw_circle(centro, 8.5, T.COR_MOEDA_BORDA)
		moeda.draw_circle(centro, 6.0, T.COR_MOEDA))
	linha.add_child(moeda)
	var rotulo: Label = Label.new()
	rotulo.text = "Moedas ganhas"
	rotulo.theme_type_variation = &"TextoSecundario"
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(rotulo)
	var valor: Label = Label.new()
	valor.text = "+0"  # economia liga no M3 (~5% dos pontos, regra do design)
	valor.theme_type_variation = &"TituloMd"
	valor.add_theme_color_override("font_color", T.COR_MOEDA)
	valor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(valor)
	return card


# ------------------------------------------------------------------- análise

## Texto pt-BR de cada achado do analisador (i18n no M3).
const TEXTOS_ACHADO: Dictionary[StrategyAnalyzer.Achado, String] = {
	StrategyAnalyzer.Achado.DESAFIO_PROIBIA_MATAR:
		"Este desafio pedia ZERO abates — paciência também é estratégia.",
	StrategyAnalyzer.Achado.GERENCIE_ENERGIA:
		"Você morreu sem energia: guarde turbo para fugir, não só para caçar.",
	StrategyAnalyzer.Achado.FUJA_DOS_MAIORES:
		"Cobras 10% maiores devoram no toque — fuja, cresça, e só então enfrente.",
	StrategyAnalyzer.Achado.CRESCA_ANTES_DE_CACAR:
		"Você caçou pequeno demais: coma antes, cace depois.",
	StrategyAnalyzer.Achado.COLETE_MAIS_RAPIDO:
		"Faltou ritmo: cada comida vale 10 pontos — trace rotas entre elas.",
	StrategyAnalyzer.Achado.CACE_PRESAS_CANSADAS:
		"Presas descansadas escapam: ataque quem já foge de outra cobra.",
	StrategyAnalyzer.Achado.BOM_DESEMPENHO:
		"Mandou bem! Repita a arena e compare suas decisões.",
}


## Card azul do blueprint: 💡 + ANÁLISE ESTRATÉGICA + dicas.
func _card_analise(achados: Array[StrategyAnalyzer.Achado]) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = Color(T.CORES_COBRA_BASE[1], 0.08)
	caixa.set_corner_radius_all(T.RAIO_CARD - 2)
	caixa.set_border_width_all(T.BORDA_FINA)
	caixa.border_color = Color(T.CORES_COBRA_BASE[1], 0.3)
	caixa.content_margin_left = float(T.ESP_MD)
	caixa.content_margin_right = float(T.ESP_MD)
	caixa.content_margin_top = float(T.ESP_SM + 2)
	caixa.content_margin_bottom = float(T.ESP_SM + 2)
	card.add_theme_stylebox_override("panel", caixa)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	card.add_child(linha)
	var icone: Label = Label.new()
	icone.text = "💡"
	icone.theme_type_variation = &"TituloMd"
	linha.add_child(icone)
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilha.add_theme_constant_override("separation", T.ESP_MICRO)
	linha.add_child(pilha)
	var titulo: Label = Label.new()
	titulo.text = "ANÁLISE ESTRATÉGICA"
	titulo.theme_type_variation = &"TextoLegenda"
	titulo.add_theme_color_override("font_color", T.CORES_COBRA_BASE[1])
	pilha.add_child(titulo)
	for achado: StrategyAnalyzer.Achado in achados:
		var dica: Label = Label.new()
		dica.text = TEXTOS_ACHADO[achado]
		dica.theme_type_variation = &"TextoCorpoSm"
		dica.add_theme_color_override("font_color", T.COR_TEXTO_PRIMARIO)
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pilha.add_child(dica)
	return card


# --------------------------------------------------------------- seed/botões

## Linha da seed (blueprint): SEED à esquerda, pill "↻ Repetir esta arena".
func _linha_seed(motor: GameEngine) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var linha: HBoxContainer = HBoxContainer.new()
	card.add_child(linha)
	var rotulo: Label = Label.new()
	rotulo.text = "SEED #%d" % motor.rng.semente
	rotulo.theme_type_variation = &"TextoLegenda"
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(rotulo)
	var repetir: Button = Button.new()
	repetir.text = "↻ Repetir esta arena"
	repetir.theme_type_variation = &"Chip"
	repetir.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	repetir.pressed.connect(func() -> void:
		Sessao.proxima_semente = motor.rng.semente
		get_tree().change_scene_to_file(CENA_JOGO))
	linha.add_child(repetir)
	return card


func _botoes_finais(regras: ChallengeRules) -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS + 2)

	var jogar: Button = Button.new()
	jogar.theme_type_variation = &"BotaoHeroi"
	jogar.flat = true
	jogar.custom_minimum_size = Vector2(0.0, float(T.TOQUE_HEROI) - float(T.ESP_MICRO))
	jogar.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(jogar, jogar.size, float(T.RAIO_CARD) - 2.0,
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM))
	jogar.pressed.connect(func() -> void:
		_preparar_relancamento()
		get_tree().change_scene_to_file(CENA_JOGO))
	var texto_jogar: Label = Label.new()
	texto_jogar.text = "Tentar de novo" if regras != null else "Jogar de novo"
	texto_jogar.theme_type_variation = &"TituloMd"
	texto_jogar.add_theme_color_override("font_color", T.COR_TEXTO_SOBRE_PRIMARIO)
	texto_jogar.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto_jogar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_jogar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_jogar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jogar.add_child(texto_jogar)
	pilha.add_child(jogar)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_XS + 2)
	var menu: Button = Button.new()
	menu.text = "Menu"
	menu.theme_type_variation = &"BotaoSecundario"
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	linha.add_child(menu)
	var compartilhar: Button = Button.new()
	compartilhar.text = "⇪ Compartilhar"
	compartilhar.theme_type_variation = &"BotaoSecundario"
	compartilhar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compartilhar.disabled = true  # plugin de share nativo é M3
	linha.add_child(compartilhar)
	pilha.add_child(linha)
	return pilha


func _espaco_flexivel() -> Control:
	var espaco: Control = Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return espaco


## Estado do desafio para o subtítulo (no lugar do recorde do Arcade).
func _texto_desafio(regras: ChallengeRules) -> String:
	if regras.estado == ChallengeRules.Estado.CONCLUIDO:
		return "Desafio concluído! 🎉"
	match regras.motivo:
		ChallengeRules.Motivo.MATOU_ALGUEM:
			return "Desafio falhou: era sem matar!"
		ChallengeRules.Motivo.TEMPO_ESGOTADO:
			return "Desafio falhou: o tempo acabou"
		_:
			return "Desafio falhou: você foi devorado"


## Relançar do desafio corrente (seed é fixa — sempre a mesma arena).
func _preparar_relancamento() -> void:
	if Sessao.regras_desafio != null:
		Sessao.desafio_pendente = int(Sessao.regras_desafio.desafio)
