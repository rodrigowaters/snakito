class_name Celebracao
extends Control
## Celebração de vitória — blueprint "12c Fase concluída" (M2). Sem o sistema
## de fases/chefe (pós-lançamento), a tela celebra o DESAFIO CONCLUÍDO e a
## ARENA DOMINADA no Arcade (última cobra viva — playtest 11/08). Adaptações
## registradas: pill do desafio/arcade no lugar da fase; placar "VOCÊ vs
## META" (desafio) ou "VOCÊ vs ARENA" (extermínio) no lugar de "VOCÊ vs
## CHEFE"; pill de moedas zerada (economia M3); CTA puxa o próximo passo.

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_JOGO: String = "res://src/scenes/jogo/jogo.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"
const CENA_RESULTADO: String = "res://src/ui/resultado/resultado.tscn"

## Confetes do topo do blueprint: (x, y, lado, rotação°, índice de cor).
const CONFETES: Array = [
	[46.0, 38.0, 11.0, 18.0, 3], [110.0, 126.0, 9.0, -14.0, 2],
	[170.0, 30.0, 12.0, 30.0, 1], [240.0, 140.0, 9.0, -22.0, 0],
	[300.0, 34.0, 10.0, 12.0, 5], [352.0, 72.0, 9.0, 40.0, 4],
	[80.0, 130.0, 8.0, -30.0, 6], [330.0, 140.0, 8.0, 24.0, 2],
	[200.0, 118.0, 9.0, -18.0, 7],
]

## Nomes curtos dos desafios (i18n no M3).
const NOMES_DESAFIO: Dictionary[ChallengeRules.Desafio, String] = {
	ChallengeRules.Desafio.FARMING_PURO: "FARMING PURO",
	ChallengeRules.Desafio.AGRESSAO_CONTROLADA: "AGRESSÃO CONTROLADA",
	ChallengeRules.Desafio.DEFESA: "DEFESA",
	ChallengeRules.Desafio.INTEGRACAO_TOTAL: "INTEGRAÇÃO TOTAL",
}

## Encadeamento: concluiu N → o CTA puxa N+1 (D4 fecha o ciclo no Arcade).
const PROXIMO_DESAFIO: Dictionary[ChallengeRules.Desafio, ChallengeRules.Desafio] = {
	ChallengeRules.Desafio.FARMING_PURO: ChallengeRules.Desafio.AGRESSAO_CONTROLADA,
	ChallengeRules.Desafio.AGRESSAO_CONTROLADA: ChallengeRules.Desafio.DEFESA,
	ChallengeRules.Desafio.DEFESA: ChallengeRules.Desafio.INTEGRACAO_TOTAL,
}

const TITULOS_CTA: Dictionary[ChallengeRules.Desafio, String] = {
	ChallengeRules.Desafio.AGRESSAO_CONTROLADA: "▶ Desafio 2 — Agressão controlada",
	ChallengeRules.Desafio.DEFESA: "▶ Desafio 3 — Defesa",
	ChallengeRules.Desafio.INTEGRACAO_TOTAL: "▶ Desafio 4 — Integração total",
}


func _ready() -> void:
	var motor: GameEngine = Sessao.ultimo_motor
	var valido: bool = motor != null \
		and (Sessao.regras_desafio != null or motor.arena_dominada())
	if not valido:
		get_tree().change_scene_to_file.call_deferred(CENA_HOME)
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

	# Confetes estáticos do topo (quadradinhos girados da paleta).
	var confetes: Control = Control.new()
	confetes.set_anchors_preset(Control.PRESET_TOP_WIDE)
	confetes.custom_minimum_size = Vector2(0.0, 220.0)
	confetes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confetes.draw.connect(func() -> void:
		for confete: Array in CONFETES:
			confetes.draw_set_transform(
				Vector2(confete[0], confete[1]), deg_to_rad(confete[3]), Vector2.ONE)
			var lado: float = confete[2]
			confetes.draw_rect(Rect2(-lado * 0.5, -lado * 0.5, lado, lado),
				T.CORES_COBRA_BASE[confete[4]])
		confetes.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	add_child(confetes)


func _montar_conteudo() -> void:
	var regras: ChallengeRules = Sessao.regras_desafio
	var motor: GameEngine = Sessao.ultimo_motor

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

	# Pill verde do contexto (blueprint: "🌊 FASE 3 · OCEANO").
	var linha_pill: HBoxContainer = HBoxContainer.new()
	linha_pill.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_child(linha_pill)
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _caixa_pill(T.CORES_COBRA_BASE[0]))
	var texto_pill: Label = Label.new()
	if regras != null:
		texto_pill.text = "🎯 DESAFIO %d · %s" % [int(regras.desafio) + 1,
			NOMES_DESAFIO.get(regras.desafio, "")]
	else:
		texto_pill.text = "🐍 ARCADE · %d COBRAS" % motor.arena.cobras.size()
	texto_pill.theme_type_variation = &"TextoLegenda"
	texto_pill.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	pill.add_child(texto_pill)
	linha_pill.add_child(pill)

	var meio: VBoxContainer = VBoxContainer.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_theme_constant_override("separation", T.ESP_MD)
	coluna.add_child(meio)

	# Domínio manda no título mesmo em desafio (playtest 13/08: concluir o
	# D3 aos 117s por extermínio parecia bug com o título genérico).
	var dominou: bool = motor.arena_dominada()
	var titulo: Label = Label.new()
	titulo.text = "Arena dominada!" if dominou \
		else "Desafio concluído!" if regras != null else "Arena dominada!"
	titulo.theme_type_variation = &"TituloHero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meio.add_child(titulo)

	# Mascote vitorioso (cor da skin, olhos felizes fechados + sparkle).
	var mascote: Control = Control.new()
	mascote.custom_minimum_size = Vector2(200.0, 130.0)
	mascote.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascote.draw.connect(_desenhar_mascote_vitorioso.bind(mascote))
	meio.add_child(mascote)

	# Placar "VOCÊ vs META" (adaptação do "VOCÊ vs CHEFE" — a meta é o
	# adversário do desafio).
	var linha_placar: HBoxContainer = HBoxContainer.new()
	linha_placar.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_child(linha_placar)
	var placar: PanelContainer = PanelContainer.new()
	var caixa_placar: StyleBoxFlat = StyleBoxFlat.new()
	caixa_placar.bg_color = T.COR_SUPERFICIE_HUD
	caixa_placar.set_corner_radius_all(T.RAIO_CARD + 2)
	caixa_placar.set_border_width_all(T.BORDA_FINA)
	caixa_placar.border_color = Color(T.CORES_COBRA_BASE[0], 0.35)
	caixa_placar.content_margin_left = float(T.ESP_LG)
	caixa_placar.content_margin_right = float(T.ESP_LG)
	caixa_placar.content_margin_top = float(T.ESP_MD)
	caixa_placar.content_margin_bottom = float(T.ESP_MD)
	placar.add_theme_stylebox_override("panel", caixa_placar)
	linha_placar.add_child(placar)
	var conteudo_placar: HBoxContainer = HBoxContainer.new()
	conteudo_placar.add_theme_constant_override("separation", T.ESP_MD)
	placar.add_child(conteudo_placar)
	var vs: Label = Label.new()
	vs.text = "vs"
	vs.theme_type_variation = &"TextoMuted"
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if regras != null and not dominou:
		conteudo_placar.add_child(_coluna_placar("VOCÊ",
			str(regras.progresso_atual(motor)), T.CORES_COBRA_BASE[0], 1.0))
		conteudo_placar.add_child(vs)
		conteudo_placar.add_child(_coluna_placar("META 🎯",
			str(regras.progresso_meta()), T.COR_ALERTA, 0.7))
	else:
		# Extermínio: seus abates contra a arena inteira ("devorei X de N") —
		# vale também para desafio vencido por domínio (placar VOCÊ 117 vs
		# META 180 parecia derrota).
		conteudo_placar.add_child(_coluna_placar("VOCÊ",
			str(motor.jogador().abates), T.CORES_COBRA_BASE[0], 1.0))
		conteudo_placar.add_child(vs)
		conteudo_placar.add_child(_coluna_placar("ARENA 👑",
			str(motor.arena.cobras.size() - 1), T.COR_ALERTA, 0.7))

	# Pill de moedas (economia liga no M3 — regra do design: recompensa por
	# desafio; zerada guarda o lugar).
	var linha_moedas: HBoxContainer = HBoxContainer.new()
	linha_moedas.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_child(linha_moedas)
	var pill_moedas: PanelContainer = PanelContainer.new()
	pill_moedas.add_theme_stylebox_override("panel", _caixa_pill(T.COR_MOEDA))
	var moedas: Label = Label.new()
	moedas.text = "+%d moedas" % Sessao.moedas_ganhas
	moedas.theme_type_variation = &"TextoCorpoSm"
	moedas.add_theme_color_override("font_color", T.COR_MOEDA)
	pill_moedas.add_child(moedas)
	pill_moedas.modulate.a = 0.7
	linha_moedas.add_child(pill_moedas)

	coluna.add_child(_botoes(regras))


func _caixa_pill(cor: Color) -> StyleBoxFlat:
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = Color(cor, 0.12)
	caixa.set_corner_radius_all(T.RAIO_PILULA)
	caixa.set_border_width_all(T.BORDA_FINA)
	caixa.border_color = Color(cor, 0.35)
	caixa.content_margin_left = float(T.ESP_MD)
	caixa.content_margin_right = float(T.ESP_MD)
	caixa.content_margin_top = float(T.ESP_XS)
	caixa.content_margin_bottom = float(T.ESP_XS)
	return caixa


func _coluna_placar(rotulo: String, valor: String, cor: Color, alfa: float) -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	pilha.modulate.a = alfa
	var etiqueta: Label = Label.new()
	etiqueta.text = rotulo
	etiqueta.theme_type_variation = &"TextoLegenda"
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(etiqueta)
	var numero: Label = Label.new()
	numero.text = valor
	numero.theme_type_variation = &"TituloLg"
	numero.add_theme_color_override("font_color", cor)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(numero)
	return pilha


## Mascote do blueprint com a carinha de vitória: olhos fechados felizes,
## sorrisão e sparkle dourado.
func _desenhar_mascote_vitorioso(alvo: Control) -> void:
	var cor: Color = T.CORES_COBRA_BASE[ProgressoLocal.skin_equipada()]
	var escala: Vector2 = alvo.size / Vector2(200.0, 150.0)
	var corpo: Array[Vector3] = [
		Vector3(52.0, 112.0, 16.0), Vector3(76.0, 98.0, 19.0),
		Vector3(104.0, 86.0, 23.0), Vector3(138.0, 76.0, 28.0),
	]
	var alfas: Array[float] = [0.5, 0.7, 0.85, 1.0]
	for i: int in corpo.size():
		alvo.draw_circle(Vector2(corpo[i].x, corpo[i].y) * escala,
			corpo[i].z * escala.x, Color(cor, alfas[i]))
	var cabeca: Vector2 = Vector2(138.0, 76.0) * escala
	var raio: float = 28.0 * escala.x
	# Brilho, olhos fechados FELIZES (arcos para cima) e sorrisão.
	alvo.draw_circle(cabeca + Vector2(-raio * 0.25, -raio * 0.3), raio * 0.55,
		Color(cor.lightened(0.35), 0.55))
	for lado: float in [-1.0, 1.0]:
		alvo.draw_arc(cabeca + Vector2(lado * raio * 0.36, -raio * 0.2),
			raio * 0.16, deg_to_rad(200.0), deg_to_rad(340.0), 8,
			T.COR_APP_FUNDO_INICIO, 3.4)
	alvo.draw_arc(cabeca + Vector2(0.0, raio * 0.28), raio * 0.32,
		deg_to_rad(30.0), deg_to_rad(150.0), 10, T.COR_APP_FUNDO_INICIO, 3.6)
	# Sparkle dourado (zigue-zague do blueprint).
	var sparkle: PackedVector2Array = PackedVector2Array([
		Vector2(118.0, 34.0), Vector2(126.0, 46.0), Vector2(136.0, 37.0),
		Vector2(143.0, 49.0), Vector2(155.0, 42.0)])
	for i: int in range(1, sparkle.size()):
		alvo.draw_line(sparkle[i - 1] * escala, sparkle[i] * escala,
			T.COR_MOEDA, 4.0)


func _botoes(regras: ChallengeRules) -> Control:
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS + 2)

	# CTA: o PRÓXIMO passo (blueprint: "▶ Jogar fase 4") — próximo desafio,
	# ou o Arcade (extermínio, ou o D4 fechou o ciclo).
	var tem_proximo: bool = regras != null \
		and PROXIMO_DESAFIO.has(regras.desafio)
	var cta: Button = Button.new()
	cta.theme_type_variation = &"BotaoHeroi"
	cta.flat = true
	cta.custom_minimum_size = Vector2(0.0, float(T.TOQUE_HEROI) - 2.0)
	cta.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(cta, cta.size, float(T.RAIO_CARD),
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM))
	cta.pressed.connect(func() -> void:
		if tem_proximo:
			Sessao.desafio_pendente = int(PROXIMO_DESAFIO[regras.desafio])
		else:
			Sessao.regras_desafio = null
		get_tree().change_scene_to_file(CENA_JOGO))
	var texto_cta: Label = Label.new()
	if tem_proximo:
		texto_cta.text = TITULOS_CTA[PROXIMO_DESAFIO[regras.desafio]]
	elif regras == null:
		texto_cta.text = "▶ Jogar de novo"
	else:
		texto_cta.text = "▶ Jogar Arcade"
	texto_cta.theme_type_variation = &"TituloMd"
	texto_cta.add_theme_color_override("font_color", T.COR_TEXTO_SOBRE_PRIMARIO)
	texto_cta.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto_cta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_cta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.add_child(texto_cta)
	pilha.add_child(cta)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_XS + 2)
	var resultado: Button = Button.new()
	resultado.text = "Ver resultado"
	resultado.theme_type_variation = &"BotaoSecundario"
	resultado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resultado.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_RESULTADO))
	linha.add_child(resultado)
	var menu: Button = Button.new()
	menu.text = "Menu"
	menu.theme_type_variation = &"BotaoSecundario"
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	linha.add_child(menu)
	pilha.add_child(linha)
	return pilha
