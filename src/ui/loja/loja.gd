class_name Loja
extends Control
## Loja — composição fiel aos blueprints 09 (Skins, tabs por raridade),
## 09b (Buffs) e 09c (Pacotes). Adaptações registradas:
## - Skins: catálogo COMPLETO do design (17) — comuns grátis do M1,
##   raras sólidas compráveis com moedas DESDE JÁ, épicas/lendárias com
##   padrão guardam lugar (render de padrão em jogo + Billing são M3);
##   grid rola na vertical; o preview 09a entra com as premium.
## - Buffs: compra com moedas FUNCIONAL desde já (spec §2.6.2: 200×growth^N,
##   teto Nv 10 do motor) — a economia nasce zerada, ganhar moedas liga no
##   17/08 o "▶ ANÚNCIO" (recompensado real) e o "🎟️ Pular" (ticket,
##   offline) sobem 1 nível sem moedas.
## - Pacotes: tudo guarda lugar até o Billing (M3) — preços de exemplo,
##   CTAs desabilitados. É a tela que valida o SCROLL no aparelho
##   (decisão de 13/08 na tela de Configurações).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_HOME: String = "res://src/ui/home/home.tscn"

enum Aba { SKINS, BUFFS, PACOTES }

## Aba a abrir na próxima instância (rota: Configurações → "Remover
## anúncios" cai direto em Pacotes). Consumida no _ready.
static var proxima_aba: Aba = Aba.SKINS

## Modulação de "guarda lugar, ainda não funciona" (mesma das Configurações).
const ALFA_GUARDA_LUGAR: float = 0.55

## Pacotes de exemplo (Billing M3 — docs §5 Fase 3). Valores ilustrativos
## até os produtos existirem no Play Console.
## Cards da aba Pacotes. **Sem preço**: ele vem do Play em
## `Compras.preco(produto)` — na moeda do país do jogador (preço fixo em
## reais seria mentira em qualquer outro país e mudaria sem o app saber).
## `vendavel = false` = o produto existe mas ainda não pode ser entregue
## (pacote de skin espera o render de padrão em jogo); o card mostra
## "em breve" em vez de um CTA que cobraria por nada.
const PACOTES_SKINS: Array[Dictionary] = [
	{"produto": "pacote_neon", "vendavel": false,
		"icone": "🌈", "nome": "Pacote Neon", "tipo": "3 SKINS ÉPICAS",
		"raridade": SnakitoTokens.Raridade.EPICA, "tag": "MAIS POPULAR",
		"itens": ["3 skins neon exclusivas",
			"Rastro brilhante na arena", "Nunca dão vantagem — só estilo"]},
	{"produto": "pacote_cosmico", "vendavel": false,
		"icone": "👑", "nome": "Pacote Cósmico", "tipo": "2 SKINS LENDÁRIAS",
		"raridade": SnakitoTokens.Raridade.LENDARIA, "tag": "👑 LENDÁRIO",
		"itens": ["Fênix e Nebulosa",
			"Brilho especial na cabeça", "Nunca dão vantagem — só estilo"]},
]
const PACOTES_ANUNCIOS: Array[Dictionary] = [
	{"produto": "combo_turbinado", "vendavel": true,
		"icone": "🚀", "nome": "Começo turbinado", "bonus": "500 moedas"},
	{"produto": "combo_sem_interrupcao", "vendavel": true,
		"icone": "🎟️", "nome": "Sem interrupção", "bonus": "10 pulos"},
]
const PACOTES_TICKETS: Array[Dictionary] = [
	{"produto": "tickets_5", "vendavel": true, "qtd": 5},
	{"produto": "tickets_15", "vendavel": true, "qtd": 15},
	{"produto": "tickets_40", "vendavel": true, "qtd": 40},
]
const PACOTES_MOEDAS: Array[Dictionary] = [
	{"produto": "moedas_500", "vendavel": true, "qtd": "500"},
	{"produto": "moedas_1200", "vendavel": true, "qtd": "1.200"},
	{"produto": "moedas_3000", "vendavel": true, "qtd": "3.000"},
]

var _aba: Aba = Aba.SKINS
var _raridade: SnakitoTokens.Raridade = SnakitoTokens.Raridade.COMUM
var _coluna: VBoxContainer
var _corpo: PanelContainer


func _ready() -> void:
	_aba = proxima_aba
	proxima_aba = Aba.SKINS
	# Preço vem do Play em milissegundos-a-segundos depois do boot, e uma
	# compra concedida muda saldo/entitlement: os dois remontam a tela.
	Compras.precos_prontos.connect(_remontar_tudo)
	Compras.compra_concedida.connect(func(_id: String) -> void: _remontar_tudo())
	_montar_fundo()
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_MD + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL + T.ESP_MICRO)
	margem.add_theme_constant_override("margin_bottom", T.ESP_LG + T.ESP_MICRO)
	add_child(margem)
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", T.ESP_SM + 2)
	margem.add_child(_coluna)

	_coluna.add_child(_cabecalho())
	_coluna.add_child(_seletor_abas())
	# Corpo: painel transparente que cada troca de aba repovoa.
	_corpo = PanelContainer.new()
	_corpo.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_coluna.add_child(_corpo)
	_remontar_corpo()


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


# --------------------------------------------------------------- cabeçalho

func _cabecalho() -> Control:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	var voltar: Button = Button.new()
	voltar.theme_type_variation = &"ChipQuadrado"
	voltar.custom_minimum_size = Vector2(float(T.TOQUE_MIN) - 4.0, float(T.TOQUE_MIN) - 4.0)
	voltar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(CENA_HOME))
	# Seta desenhada (glifo ← tem métrica torta — armadilha conhecida).
	voltar.draw.connect(func() -> void:
		var centro: Vector2 = voltar.size * 0.5
		var braco: float = voltar.size.x * 0.18
		var cor: Color = T.COR_TEXTO_PRIMARIO
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(braco, 0.0), cor, 2.0)
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(-braco * 0.15, -braco * 0.85), cor, 2.0)
		voltar.draw_line(centro + Vector2(-braco, 0.0), centro + Vector2(-braco * 0.15, braco * 0.85), cor, 2.0))
	linha.add_child(voltar)
	var titulo: Label = Label.new()
	titulo.text = "Loja"
	titulo.theme_type_variation = &"TituloLg"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(titulo)
	linha.add_child(_contador("🎟️", ProgressoLocal.tickets()))
	linha.add_child(_contador_moedas())
	return linha


## Pílula de contador do header (mesma da Home).
func _contador(emoji: String, valor: int) -> PanelContainer:
	var pilula: PanelContainer = PanelContainer.new()
	pilula.theme_type_variation = &"CardPainel"
	pilula.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = T.COR_SUPERFICIE_VIDRO
	estilo.border_color = T.COR_SUPERFICIE_VIDRO_BORDA
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(T.RAIO_PILULA)
	estilo.content_margin_left = float(T.ESP_SM)
	estilo.content_margin_right = float(T.ESP_SM)
	estilo.content_margin_top = float(T.ESP_XS) - 1.0
	estilo.content_margin_bottom = float(T.ESP_XS) - 1.0
	pilula.add_theme_stylebox_override("panel", estilo)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_MICRO + 1)
	pilula.add_child(linha)
	if emoji != "":
		var icone: Label = Label.new()
		icone.text = emoji
		icone.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
		linha.add_child(icone)
	var numero: Label = Label.new()
	numero.text = str(valor)
	numero.theme_type_variation = &"TextoCorpo"
	numero.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	linha.add_child(numero)
	return pilula


func _contador_moedas() -> Control:
	var pilula: PanelContainer = _contador("", ProgressoLocal.moedas())
	var moeda: Control = Control.new()
	moeda.custom_minimum_size = Vector2(float(T.ESP_MD), 0.0)
	moeda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moeda.draw.connect(func() -> void:
		DesenhoUi.moedinha(moeda, moeda.size * 0.5, 8.0))
	var linha: HBoxContainer = pilula.get_child(0)
	linha.add_child(moeda)
	linha.move_child(moeda, 0)
	return pilula


# ----------------------------------------------------------- seletor de abas

func _seletor_abas() -> Control:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_XS)
	for aba: Aba in [Aba.SKINS, Aba.BUFFS, Aba.PACOTES]:
		linha.add_child(_pilula_aba(aba))
	return linha


func _pilula_aba(aba: Aba) -> Control:
	var nomes: Dictionary = {Aba.SKINS: "Skins", Aba.BUFFS: "Buffs", Aba.PACOTES: "Pacotes"}
	var ativa: bool = aba == _aba
	var pilula: PanelContainer = PanelContainer.new()
	pilula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilula.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN) - 4.0)
	if ativa:
		pilula.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		pilula.draw.connect(func() -> void:
			DesenhoUi.gradiente_arredondado(pilula, pilula.size, pilula.size.y * 0.5,
				T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM))
	else:
		var estilo: StyleBoxFlat = StyleBoxFlat.new()
		estilo.bg_color = T.COR_SUPERFICIE_VIDRO
		estilo.border_color = T.COR_SUPERFICIE_VIDRO_BORDA
		estilo.set_border_width_all(1)
		estilo.set_corner_radius_all(T.RAIO_PILULA)
		pilula.add_theme_stylebox_override("panel", estilo)
	var rotulo: Label = Label.new()
	rotulo.text = nomes[aba]
	rotulo.theme_type_variation = &"TextoCorpo"
	rotulo.add_theme_font_size_override("font_size", T.TAM_CORPO_SM + 1)
	rotulo.add_theme_color_override("font_color",
		T.COR_TEXTO_SOBRE_PRIMARIO if ativa else T.COR_TEXTO_SECUNDARIO)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pilula.add_child(rotulo)
	if not ativa:
		var toque: Button = Button.new()
		toque.flat = true
		toque.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		toque.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		toque.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		toque.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		toque.pressed.connect(func() -> void:
			_aba = aba
			_remontar_tudo())
		pilula.add_child(toque)
	return pilula


## Recria header + abas + corpo (troca de aba ou compra mexeu nos contadores).
func _remontar_tudo() -> void:
	for filho: Node in _coluna.get_children():
		filho.queue_free()
	_coluna.add_child(_cabecalho())
	_coluna.add_child(_seletor_abas())
	_corpo = PanelContainer.new()
	_corpo.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_coluna.add_child(_corpo)
	_remontar_corpo()


func _remontar_corpo() -> void:
	for filho: Node in _corpo.get_children():
		filho.queue_free()
	match _aba:
		Aba.SKINS:
			_corpo.add_child(_aba_skins())
		Aba.BUFFS:
			_corpo.add_child(_aba_buffs())
		Aba.PACOTES:
			_corpo.add_child(_aba_pacotes())


# -------------------------------------------------------------- aba SKINS

func _aba_skins() -> Control:
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_SM + 2)
	coluna.add_child(_barra_raridades())

	var skins: Array[Dictionary] = CatalogoSkins.da_raridade(_raridade)
	if skins.is_empty():
		var vazio: VBoxContainer = VBoxContainer.new()
		vazio.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vazio.alignment = BoxContainer.ALIGNMENT_CENTER
		var brilho: Label = Label.new()
		brilho.text = "✨"
		brilho.add_theme_font_size_override("font_size", T.TAM_TITULO_LG)
		brilho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.add_child(brilho)
		var aviso: Label = Label.new()
		aviso.text = "Novas skins chegam em breve"
		aviso.theme_type_variation = &"TextoSecundario"
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.add_child(aviso)
		coluna.add_child(vazio)
		return coluna

	# Grid rola na vertical (o catálogo completo passa da tela — épicas têm
	# 9 cards); folga de topo dentro do scroll para a etiqueta flutuante.
	var rolagem: ScrollContainer = ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ocultar_barras(rolagem)
	var envelope: MarginContainer = MarginContainer.new()
	envelope.add_theme_constant_override("margin_top", T.ESP_SM)
	envelope.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(envelope)
	var grade: GridContainer = GridContainer.new()
	grade.columns = 2
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", T.ESP_SM)
	grade.add_theme_constant_override("v_separation", T.ESP_SM + 4)
	for skin: Dictionary in skins:
		grade.add_child(_card_skin(skin))
	envelope.add_child(grade)
	coluna.add_child(rolagem)
	_liberar_arrasto(envelope)
	return coluna


## Tabs de raridade com trilho inferior (blueprint 09).
func _barra_raridades() -> Control:
	var nomes: Array[String] = ["Comuns", "Raras", "Épicas", "👑 Lendárias"]
	var barra: PanelContainer = PanelContainer.new()
	var trilho: StyleBoxFlat = StyleBoxFlat.new()
	trilho.bg_color = Color.TRANSPARENT
	trilho.border_color = T.COR_CARD_BORDA
	trilho.border_width_bottom = 2
	barra.add_theme_stylebox_override("panel", trilho)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_MD + 4)
	barra.add_child(linha)
	for raridade: SnakitoTokens.Raridade in SnakitoTokens.Raridade.values():
		var ativa: bool = raridade == _raridade
		var cor: Color = T.CORES_RARIDADE[raridade] if ativa else T.COR_TEXTO_SECUNDARIO
		var tab: Button = Button.new()
		tab.flat = true
		for estado: StringName in [&"normal", &"pressed", &"hover", &"focus"]:
			tab.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
		tab.text = nomes[raridade]
		tab.custom_minimum_size = Vector2(0.0, float(T.TOQUE_MIN) - 4.0)
		tab.add_theme_font_size_override("font_size", T.TAM_CORPO_SM + 1)
		for papel: StringName in [&"font_color", &"font_pressed_color", &"font_hover_color", &"font_focus_color"]:
			tab.add_theme_color_override(papel, cor)
		if ativa:
			tab.draw.connect(func() -> void:
				tab.draw_rect(Rect2(0.0, tab.size.y - 2.5, tab.size.x, 2.5), cor))
		tab.pressed.connect(func() -> void:
			_raridade = raridade
			_remontar_corpo())
		linha.add_child(tab)
	return barra


func _card_skin(skin: Dictionary) -> Control:
	var desbloqueada: bool = CatalogoSkins.desbloqueada(skin)
	var equipada: bool = desbloqueada and skin.indice >= 0 \
		and ProgressoLocal.skin_equipada() == skin.indice
	var cor_raridade: Color = T.CORES_RARIDADE[skin.raridade]
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = T.COR_CARD_FUNDO
	estilo.border_color = T.COR_SUCESSO if equipada else (
		cor_raridade if skin.raridade != SnakitoTokens.Raridade.COMUM
		else T.COR_SUPERFICIE_VIDRO_BORDA)
	estilo.set_border_width_all(2 if equipada else 1)
	estilo.set_corner_radius_all(T.RAIO_CARD - 2)
	estilo.set_content_margin_all(float(T.ESP_SM) + 2.0)
	card.add_theme_stylebox_override("panel", estilo)

	# Etiqueta flutuante ("NOVA", "PACOTE") sobre a borda, como no design.
	if skin.tag != "":
		var fonte: Font = get_theme_default_font()
		card.draw.connect(func() -> void:
			var texto: String = skin.tag
			var largura: float = fonte.get_string_size(
				texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var caixa: Rect2 = Rect2(
				(card.size.x - largura - 20.0) * 0.5, -9.0, largura + 20.0, 17.0)
			card.draw_colored_polygon(
				DesenhoUi.poligono_arredondado(caixa, 8.5), cor_raridade)
			card.draw_string(fonte, Vector2(caixa.position.x + 10.0, 3.5), texto,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, T.COR_APP_FUNDO_INICIO))

	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS + 1)
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(pilha)

	# Cobrinha do card: 3 segmentos crescendo + cabeça com olhos (blueprint);
	# skins premium desenham o padrão (metades/listras) nas bolinhas.
	var cobra: Control = Control.new()
	cobra.custom_minimum_size = Vector2(0.0, 30.0)
	cobra.draw.connect(func() -> void:
		var centro_x: float = cobra.size.x * 0.5
		var y: float = cobra.size.y * 0.5
		var raios: Array[float] = [6.0, 7.0, 8.0, 10.5]
		var alfas: Array[float] = [0.65, 0.8, 0.9, 1.0]
		var x: float = centro_x - 34.0
		for i: int in raios.size():
			x += raios[i]
			_desenhar_bolinha_skin(cobra, Vector2(x, y), raios[i], skin, alfas[i])
			if i == raios.size() - 1:
				cobra.draw_circle(Vector2(x - 3.5, y - 2.5), 2.5, Color.WHITE)
				cobra.draw_circle(Vector2(x + 3.5, y - 2.5), 2.5, Color.WHITE)
			x += raios[i] + 1.0)
	pilha.add_child(cobra)

	var nome: Label = Label.new()
	nome.text = skin.nome
	nome.theme_type_variation = &"TextoCorpo"
	nome.add_theme_font_size_override("font_size", T.TAM_CORPO_SM + 1)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(nome)

	var centro: HBoxContainer = HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(_cta_da_skin(skin, desbloqueada, equipada))
	pilha.add_child(centro)
	return card


## CTA do card conforme o estado: equipada / equipar / comprar com moedas
## (raras sólidas — FUNCIONAL) / premium guardando lugar (padrão em jogo e
## Billing são M3).
func _cta_da_skin(skin: Dictionary, desbloqueada: bool, equipada: bool) -> Control:
	if equipada:
		return _chip_vidro("✓ Equipada", T.COR_SUCESSO)
	if desbloqueada and skin.indice >= 0:
		return _chip_gradiente("Equipar",
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM, T.COR_TEXTO_SOBRE_PRIMARIO,
			func() -> void:
				ProgressoLocal.equipar_skin(skin.indice)
				_remontar_corpo())
	if skin.preco < 0:
		var chip: Control = _chip_vidro("no pacote", T.COR_TEXTO_SECUNDARIO)
		chip.modulate.a = ALFA_GUARDA_LUGAR
		return chip
	var pode_comprar: bool = skin.indice >= 0 \
		and ProgressoLocal.moedas() >= int(skin.preco)
	if pode_comprar:
		return _chip_gradiente(str(skin.preco),
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM, T.COR_TEXTO_SOBRE_PRIMARIO,
			func() -> void:
				if ProgressoLocal.gastar_moedas(int(skin.preco)):
					ProgressoLocal.marcar_skin_comprada(skin.id)
					ProgressoLocal.equipar_skin(skin.indice)
				_remontar_tudo(),
			true)
	# Sem saldo (raras) ou padrão premium (épicas/lendárias): preço visível,
	# esmaecido — compra liga com a economia/Billing.
	var preco: Control = _chip_gradiente(str(skin.preco),
		T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM, T.COR_TEXTO_SOBRE_PRIMARIO,
		Callable(), true)
	return preco


## Bolinha de segmento com o visual da skin: sólida, metades (horizontal)
## ou listras (verticais recortadas no círculo).
func _desenhar_bolinha_skin(alvo: CanvasItem, centro: Vector2, raio: float,
		skin: Dictionary, alfa: float) -> void:
	var visual: Dictionary = skin.visual
	var cores: Array = visual.cores
	match visual.tipo:
		"metades":
			for metade: int in 2:
				var pontos: PackedVector2Array = PackedVector2Array()
				var base_angulo: float = PI if metade == 0 else 0.0
				for i: int in 17:
					var angulo: float = base_angulo + PI * float(i) / 16.0
					pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * raio)
				alvo.draw_colored_polygon(pontos, Color(cores[metade], alfa))
		"listras":
			var faixas: int = 4
			for f: int in faixas:
				var x0: float = -raio + 2.0 * raio * float(f) / float(faixas)
				var x1: float = -raio + 2.0 * raio * float(f + 1) / float(faixas)
				var pontos: PackedVector2Array = PackedVector2Array()
				for i: int in 7:  # arco de cima, x0 → x1
					var x: float = lerpf(x0, x1, float(i) / 6.0)
					pontos.append(centro + Vector2(x, -sqrt(maxf(0.0, raio * raio - x * x))))
				for i: int in 7:  # arco de baixo, x1 → x0
					var x: float = lerpf(x1, x0, float(i) / 6.0)
					pontos.append(centro + Vector2(x, sqrt(maxf(0.0, raio * raio - x * x))))
				alvo.draw_colored_polygon(pontos, Color(cores[f % cores.size()], alfa))
		_:
			var cor: Color = T.CORES_COBRA_BASE[skin.indice] if skin.indice >= 0 \
				else cores[0]
			alvo.draw_circle(centro, raio, Color(cor, alfa))


# -------------------------------------------------------------- aba BUFFS

func _aba_buffs() -> Control:
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_SM)
	var legenda: Label = Label.new()
	legenda.text = "Permanentes — cada compra sobe 1 nível. Sem saldo? Assista um anúncio."
	legenda.theme_type_variation = &"TextoLegenda"
	legenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(legenda)
	for buff: Dictionary in PrecosLoja.BUFFS:
		coluna.add_child(_card_buff(buff))
	return coluna


func _card_buff(buff: Dictionary) -> Control:
	var nivel: int = ProgressoLocal.nivel_buff(buff.chave)
	var maximo: bool = nivel >= GameEngine.NIVEL_MAX_BUFF
	var preco: int = PrecosLoja.preco_buff(buff.growth, nivel + 1)
	var tem_saldo: bool = ProgressoLocal.moedas() >= preco

	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM + 2)
	card.add_child(linha)

	# Ícone num quadrado de vidro. "Pontos iniciais" usa a moedinha
	# DESENHADA (🪙 é aposta de emoji; a moedinha já é a nossa linguagem).
	var quadro: PanelContainer = PanelContainer.new()
	quadro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var estilo_quadro: StyleBoxFlat = StyleBoxFlat.new()
	estilo_quadro.bg_color = T.COR_SUPERFICIE_VIDRO
	estilo_quadro.set_corner_radius_all(T.RAIO_CHIP + 6)
	quadro.add_theme_stylebox_override("panel", estilo_quadro)
	quadro.custom_minimum_size = Vector2(56.0, 56.0)
	if buff.icone == "":
		var moeda: Control = Control.new()
		moeda.draw.connect(func() -> void:
			DesenhoUi.moedinha(moeda, moeda.size * 0.5, 14.0))
		quadro.add_child(moeda)
	else:
		var icone: Label = Label.new()
		icone.text = buff.icone
		icone.add_theme_font_size_override("font_size", T.TAM_TITULO_LG)
		icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		quadro.add_child(icone)
	linha.add_child(quadro)

	var meio: VBoxContainer = VBoxContainer.new()
	meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meio.add_theme_constant_override("separation", 2)
	var nome: Label = Label.new()
	nome.text = buff.nome
	nome.theme_type_variation = &"TituloMd"
	nome.add_theme_font_size_override("font_size", T.TAM_TITULO_MD - 3)
	meio.add_child(nome)
	var efeito: Label = Label.new()
	efeito.text = buff.efeito
	efeito.theme_type_variation = &"TextoLegenda"
	# Quebra de linha: sem ela a largura MÍNIMA do rótulo empurra o card
	# além da tela (o VBox estica todo mundo junto).
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	efeito.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meio.add_child(efeito)
	meio.add_child(_pips_nivel(nivel))
	linha.add_child(meio)

	var direita: VBoxContainer = VBoxContainer.new()
	direita.alignment = BoxContainer.ALIGNMENT_CENTER
	direita.add_theme_constant_override("separation", T.ESP_MICRO)
	var desc: Label = Label.new()
	desc.theme_type_variation = &"TextoLegenda"
	desc.add_theme_font_size_override("font_size", T.TAM_LEGENDA - 1)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	desc.size_flags_horizontal = Control.SIZE_SHRINK_END
	if maximo:
		desc.text = "nível máximo"
		direita.add_child(desc)
		var chip_max: Control = _chip_vidro("MÁX", T.COR_ALERTA)
		chip_max.size_flags_horizontal = Control.SIZE_SHRINK_END
		direita.add_child(chip_max)
	elif tem_saldo:
		desc.text = "Nv %d → %d" % [nivel, nivel + 1]
		direita.add_child(desc)
		var comprar: Control = _chip_gradiente(str(preco),
			T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM, T.COR_TEXTO_SOBRE_PRIMARIO,
			func() -> void:
				if ProgressoLocal.gastar_moedas(preco):
					ProgressoLocal.subir_buff(buff.chave)
				_remontar_tudo(),
			true)
		comprar.size_flags_horizontal = Control.SIZE_SHRINK_END
		direita.add_child(comprar)
	else:
		# Sem saldo: o caminho do blueprint é o anúncio recompensado, que
		# SOBE O NÍVEL (09b: "Sem saldo? Assista um anúncio"); o ticket
		# entrega a mesma recompensa sem vídeo (regra dos tokens) e por
		# isso funciona offline. O preço em moedas fica visível na legenda.
		desc.text = "Nv %d → %d\n%d moedas" % [nivel, nivel + 1, preco]
		direita.add_child(desc)
		var subir: Callable = func() -> void:
			ProgressoLocal.subir_buff(buff.chave)
			_remontar_tudo()
		# Regra dura #6: entitlement ANTES de renderizar componente de
		# anúncio. Quem comprou "sem anúncios" não vê o botão — e continua
		# com os caminhos de moeda e ticket ("Remover anúncios" remove
		# anúncios, não custos).
		if Anuncios.recompensado_disponivel() and not Anuncios.sem_anuncios():
			var anuncio: Control = _chip_gradiente("▶ ANÚNCIO",
				T.COR_CTA_ANUNCIO_INICIO, T.COR_CTA_ANUNCIO_FIM,
				T.COR_TEXTO_SOBRE_OFERTA_ANUNCIO,
				func() -> void: Anuncios.mostrar_recompensado(subir))
			anuncio.size_flags_horizontal = Control.SIZE_SHRINK_END
			direita.add_child(anuncio)
		var tickets: int = ProgressoLocal.tickets()
		if tickets > 0:
			var pular: Control = _chip_vidro("🎟️ Pular (%d)" % tickets,
				T.COR_TEXTO_SECUNDARIO)
			_ligar_toque(pular, func() -> void:
				ProgressoLocal.adicionar_tickets(-1)
				subir.call())
			pular.size_flags_horizontal = Control.SIZE_SHRINK_END
			direita.add_child(pular)
	linha.add_child(direita)
	return card


## Fileira de pips de nível — 10 do motor (o desenho ilustra 5; a régua
## real é NIVEL_MAX_BUFF e mentir nível é pior que adaptar).
func _pips_nivel(nivel: int) -> Control:
	var pips: Control = Control.new()
	pips.custom_minimum_size = Vector2(GameEngine.NIVEL_MAX_BUFF * 12.0, 11.0)
	pips.draw.connect(func() -> void:
		for i: int in GameEngine.NIVEL_MAX_BUFF:
			var cor: Color = T.COR_CTA_PRIMARIO_INICIO if i < nivel else T.COR_SUPERFICIE_VIDRO_BORDA
			pips.draw_colored_polygon(DesenhoUi.poligono_arredondado(
				Rect2(i * 12.0, 2.0, 9.0, 7.0), 3.5), cor))
	return pips


# ------------------------------------------------------------ aba PACOTES

func _aba_pacotes() -> Control:
	# A tela 09c rola na vertical — validação do scroll no aparelho é parte
	# da entrega (decisão de 13/08). Barra invisível: o indicador visual do
	# blueprint são os cards cortados + dots do carrossel.
	var rolagem: ScrollContainer = ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ocultar_barras(rolagem)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", T.ESP_MD + 2)
	rolagem.add_child(coluna)

	coluna.add_child(_secao_carrossel("PACOTES DE SKINS", PACOTES_SKINS, 252.0, _card_pacote_skin))
	coluna.add_child(_secao_carrossel("PACOTES DE ANÚNCIOS", PACOTES_ANUNCIOS, 210.0, _card_pacote_anuncio))
	coluna.add_child(_banner_remover_anuncios())
	coluna.add_child(_secao_grade("TICKETS DE PULO DE ANÚNCIO", PACOTES_TICKETS, _card_ticket))
	coluna.add_child(_secao_grade("MOEDAS", PACOTES_MOEDAS, _card_moedas))

	if Compras.preco("remover_anuncios") == "":
		var aviso: Label = Label.new()
		aviso.text = "A loja do Google não respondeu — tente de novo mais tarde"
		aviso.theme_type_variation = &"TextoLegenda"
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		coluna.add_child(aviso)
	_liberar_arrasto(coluna)
	return rolagem


## Some com o visual das barras SEM desligar a rolagem (a armadilha do
## SHOW_NEVER: no aparelho ele parou de rolar).
func _ocultar_barras(rolagem: ScrollContainer) -> void:
	for barra: ScrollBar in [rolagem.get_v_scroll_bar(), rolagem.get_h_scroll_bar()]:
		barra.self_modulate = Color.TRANSPARENT


func _titulo_secao(texto: String) -> Label:
	var titulo: Label = Label.new()
	titulo.text = texto
	titulo.theme_type_variation = &"TextoLegenda"
	titulo.add_theme_font_size_override("font_size", T.TAM_LEGENDA - 1)
	return titulo


## Seção com carrossel horizontal + dots (blueprint 09c).
func _secao_carrossel(titulo: String, itens: Array[Dictionary], largura_card: float,
		fabrica: Callable) -> Control:
	var secao: VBoxContainer = VBoxContainer.new()
	secao.add_theme_constant_override("separation", T.ESP_XS)
	secao.add_child(_titulo_secao(titulo))

	var rolagem: ScrollContainer = ScrollContainer.new()
	rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ocultar_barras(rolagem)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	# Margem de topo dentro do carrossel: a etiqueta flutuante do card
	# desenha ACIMA do próprio card e o ScrollContainer recorta.
	var envelope: MarginContainer = MarginContainer.new()
	envelope.add_theme_constant_override("margin_top", T.ESP_SM)
	envelope.add_child(linha)
	rolagem.add_child(envelope)
	for item: Dictionary in itens:
		var card: Control = fabrica.call(item)
		card.custom_minimum_size.x = largura_card
		linha.add_child(card)
	secao.add_child(rolagem)

	# Dots: página ativa vira travessão verde (blueprint).
	var dots: Control = Control.new()
	dots.custom_minimum_size = Vector2(0.0, 8.0)
	var passo: float = largura_card + float(T.ESP_SM)
	dots.draw.connect(func() -> void:
		var pagina: int = clampi(roundi(rolagem.scroll_horizontal / passo), 0, itens.size() - 1)
		var total_l: float = (itens.size() - 1) * 11.0 + 18.0
		var x: float = (dots.size.x - total_l) * 0.5
		for i: int in itens.size():
			if i == pagina:
				dots.draw_colored_polygon(DesenhoUi.poligono_arredondado(
					Rect2(x, 1.0, 18.0, 6.0), 3.0), T.COR_CTA_PRIMARIO_INICIO)
				x += 18.0 + 5.0
			else:
				dots.draw_circle(Vector2(x + 3.0, 4.0), 3.0, Color(1.0, 1.0, 1.0, 0.2))
				x += 6.0 + 5.0)
	rolagem.get_h_scroll_bar().value_changed.connect(func(_v: float) -> void:
		dots.queue_redraw())
	secao.add_child(dots)
	return secao


func _secao_grade(titulo: String, itens: Array[Dictionary], fabrica: Callable) -> Control:
	var secao: VBoxContainer = VBoxContainer.new()
	secao.add_theme_constant_override("separation", T.ESP_XS)
	secao.add_child(_titulo_secao(titulo))
	var grade: GridContainer = GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", T.ESP_XS + 2)
	for item: Dictionary in itens:
		grade.add_child(fabrica.call(item))
	secao.add_child(grade)
	return secao


func _card_pacote_skin(pacote: Dictionary) -> Control:
	var cor_raridade: Color = T.CORES_RARIDADE[pacote.raridade]
	var card: PanelContainer = _card_vidro(cor_raridade, 1.5)
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS)
	card.add_child(pilha)

	# Etiqueta flutuante sobre a borda superior (desenhada — sair do rect
	# do card não é problema para _draw, e o carrossel dá a folga de topo).
	var fonte: Font = get_theme_default_font()
	card.draw.connect(func() -> void:
		var texto: String = pacote.tag
		var largura: float = fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var caixa: Rect2 = Rect2(14.0, -9.0, largura + 20.0, 17.0)
		card.draw_colored_polygon(DesenhoUi.poligono_arredondado(caixa, 8.5), cor_raridade)
		card.draw_string(fonte, Vector2(24.0, 3.5), texto,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, T.COR_APP_FUNDO_INICIO))

	var topo: HBoxContainer = HBoxContainer.new()
	topo.add_theme_constant_override("separation", T.ESP_XS + 2)
	var icone: Label = Label.new()
	icone.text = pacote.icone
	icone.add_theme_font_size_override("font_size", T.TAM_TITULO_LG)
	topo.add_child(icone)
	var nomes: VBoxContainer = VBoxContainer.new()
	nomes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nome: Label = Label.new()
	nome.text = pacote.nome
	nome.theme_type_variation = &"TituloMd"
	nome.add_theme_font_size_override("font_size", T.TAM_TITULO_MD - 3)
	nomes.add_child(nome)
	var tipo: Label = Label.new()
	tipo.text = pacote.tipo
	tipo.theme_type_variation = &"TextoLegenda"
	tipo.add_theme_font_size_override("font_size", T.TAM_LEGENDA - 1)
	nomes.add_child(tipo)
	topo.add_child(nomes)
	pilha.add_child(topo)

	var texto_preco: String = Compras.preco(str(pacote.get("produto", "")))
	var preco: Label = Label.new()
	preco.text = texto_preco if texto_preco != "" else "—"
	preco.theme_type_variation = &"TituloLg"
	preco.add_theme_color_override("font_color", cor_raridade)
	pilha.add_child(preco)

	for item: String in pacote.itens:
		var linha: HBoxContainer = HBoxContainer.new()
		linha.add_theme_constant_override("separation", T.ESP_MICRO + 3)
		var ok: Label = Label.new()
		ok.text = "✓"
		ok.theme_type_variation = &"TextoLegenda"
		ok.add_theme_color_override("font_color", T.COR_SUCESSO)
		linha.add_child(ok)
		var texto: Label = Label.new()
		texto.text = item
		texto.theme_type_variation = &"TextoLegenda"
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(texto)
		pilha.add_child(linha)

	pilha.add_child(_cta_pacote(pacote))
	return card


func _card_pacote_anuncio(pacote: Dictionary) -> Control:
	var card: PanelContainer = _card_vidro(T.COR_SUPERFICIE_VIDRO_BORDA, 1.0)
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS)
	card.add_child(pilha)
	var topo: HBoxContainer = HBoxContainer.new()
	topo.add_theme_constant_override("separation", T.ESP_XS)
	var icone: Label = Label.new()
	icone.text = pacote.icone
	icone.add_theme_font_size_override("font_size", T.TAM_TITULO_MD)
	topo.add_child(icone)
	var nome: Label = Label.new()
	nome.text = pacote.nome
	nome.theme_type_variation = &"TituloMd"
	nome.add_theme_font_size_override("font_size", T.TAM_CORPO + 1)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(nome)
	pilha.add_child(topo)
	var bonus: Label = Label.new()
	bonus.text = "🚫 Sem anúncios + %s" % pacote.bonus
	bonus.theme_type_variation = &"TextoLegenda"
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pilha.add_child(bonus)
	var texto_preco: String = Compras.preco(str(pacote.get("produto", "")))
	var preco: Label = Label.new()
	preco.text = texto_preco if texto_preco != "" else "—"
	preco.theme_type_variation = &"TituloMd"
	pilha.add_child(preco)
	pilha.add_child(_cta_pacote(pacote))
	return card


func _banner_remover_anuncios() -> Control:
	var card: PanelContainer = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(T.COR_ALERTA, 0.08)
	estilo.border_color = Color(T.COR_ALERTA, 0.3)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(T.RAIO_CARD - 2)
	estilo.set_content_margin_all(float(T.ESP_SM) + 2.0)
	card.add_theme_stylebox_override("panel", estilo)
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_SM)
	card.add_child(linha)
	var icone: Label = Label.new()
	icone.text = "🚫"
	icone.add_theme_font_size_override("font_size", T.TAM_TITULO_MD)
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	var textos: VBoxContainer = VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nome: Label = Label.new()
	nome.text = "Remover anúncios"
	nome.theme_type_variation = &"TituloMd"
	nome.add_theme_font_size_override("font_size", T.TAM_CORPO + 1)
	textos.add_child(nome)
	var sub: Label = Label.new()
	sub.text = "para sempre, em todos os aparelhos"
	sub.theme_type_variation = &"TextoLegenda"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(sub)
	linha.add_child(textos)
	var preco_remover: String = Compras.preco("remover_anuncios")
	var cta: Control
	if ProgressoLocal.entitlement_ativo("ads_removed"):
		cta = _chip_vidro("✓ Ativo", T.COR_SUCESSO)
	elif preco_remover == "":
		cta = _chip_vidro("em breve", T.COR_TEXTO_SECUNDARIO)
		cta.modulate.a = ALFA_GUARDA_LUGAR
	else:
		cta = _chip_gradiente(preco_remover,
			T.COR_CTA_VIP_INICIO, T.COR_CTA_VIP_INICIO, T.COR_TEXTO_SOBRE_ALERTA,
			func() -> void: Compras.comprar("remover_anuncios"))
	cta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(cta)
	return card


func _card_ticket(pacote: Dictionary) -> Control:
	return _card_miudo("🎟️", Callable(), "%d pulos" % pacote.qtd, pacote)


func _card_moedas(pacote: Dictionary) -> Control:
	return _card_miudo("", func(alvo: Control) -> void:
		DesenhoUi.moedinha(alvo, alvo.size * 0.5, 12.0), str(pacote.qtd), pacote)


## Card compacto das grades de 3 colunas (tickets/moedas).
func _card_miudo(emoji: String, desenho: Callable, titulo: String,
		pacote: Dictionary) -> Control:
	var card: PanelContainer = _card_vidro(T.COR_SUPERFICIE_VIDRO_BORDA, 1.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pilha: VBoxContainer = VBoxContainer.new()
	pilha.add_theme_constant_override("separation", T.ESP_XS - 1)
	pilha.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(pilha)
	if desenho.is_valid():
		var icone_desenhado: Control = Control.new()
		icone_desenhado.custom_minimum_size = Vector2(0.0, 26.0)
		icone_desenhado.draw.connect(func() -> void:
			desenho.call(icone_desenhado))
		pilha.add_child(icone_desenhado)
	else:
		var icone: Label = Label.new()
		icone.text = emoji
		icone.add_theme_font_size_override("font_size", T.TAM_TITULO_MD)
		icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pilha.add_child(icone)
	var nome: Label = Label.new()
	nome.text = titulo
	nome.theme_type_variation = &"TituloMd"
	nome.add_theme_font_size_override("font_size", T.TAM_CORPO)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilha.add_child(nome)
	var centro: HBoxContainer = HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(_cta_pacote(pacote, 38.0))
	pilha.add_child(centro)
	return card


## CTA de um produto do Play. Mostra o PREÇO REAL do Play e compra de
## verdade; sem preço (loja indisponível, produto não publicado) ou não
## vendável ainda, vira "em breve" apagado — nunca um botão que cobra
## sem entregar.
func _cta_pacote(pacote: Dictionary, altura: float = 46.0) -> Control:
	var produto: String = str(pacote.get("produto", ""))
	var preco: String = Compras.preco(produto)
	if not bool(pacote.get("vendavel", false)) or preco == "":
		var espera: Control = _chip_vidro("em breve", T.COR_TEXTO_SECUNDARIO)
		espera.modulate.a = ALFA_GUARDA_LUGAR
		return espera
	if ProgressoLocal.entitlement_ativo("ads_removed") \
			and produto.begins_with("combo_"):
		# Combo inclui remoção de anúncios que a conta já tem.
		return _chip_vidro("✓ já é seu", T.COR_SUCESSO)
	return _chip_gradiente(preco,
		T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_FIM, T.COR_TEXTO_SOBRE_PRIMARIO,
		func() -> void: Compras.comprar(produto), false, altura)


## Varre a subárvore trocando STOP → PASS: nenhum card/painel pode engolir
## o arrasto do ScrollContainer (o toque dos chips usa PASS + _ligar_toque).
## O próprio ScrollContainer mantém o STOP (é ele quem consome o arrasto),
## mas a varredura ATRAVESSA os carrosséis — os cards de dentro cobrem o
## carrossel inteiro e também precisam passar o toque (playtest 13/08:
## "scroll dos carrossel não funcionou").
func _liberar_arrasto(no: Control) -> void:
	if not (no is ScrollContainer) and no.mouse_filter == Control.MOUSE_FILTER_STOP:
		no.mouse_filter = Control.MOUSE_FILTER_PASS
	for filho: Node in no.get_children():
		if filho is Control:
			_liberar_arrasto(filho)


# ------------------------------------------------------------- componentes

func _card_vidro(cor_borda: Color, largura_borda: float) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = T.COR_CARD_FUNDO
	estilo.border_color = cor_borda
	estilo.set_border_width_all(roundi(largura_borda))
	estilo.set_corner_radius_all(T.RAIO_CARD)
	estilo.set_content_margin_all(float(T.ESP_MD))
	card.add_theme_stylebox_override("panel", estilo)
	return card


## Chip-pílula com gradiente. `acao` inválida = guarda lugar (esmaecido).
## `com_moeda` desenha a moedinha antes do texto (preço de buff).
func _chip_gradiente(texto: String, cor_inicio: Color, cor_fim: Color, cor_texto: Color,
		acao: Callable, com_moeda: bool = false, altura: float = 44.0) -> Control:
	var chip: PanelContainer = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	chip.custom_minimum_size = Vector2(0.0, altura)
	chip.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(chip, chip.size, chip.size.y * 0.5,
			cor_inicio, cor_fim))
	var linha: HBoxContainer = HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", T.ESP_MICRO + 2)
	chip.add_child(linha)
	var folga_esq: Control = Control.new()
	folga_esq.custom_minimum_size = Vector2(float(T.ESP_XS) + 2.0, 0.0)
	linha.add_child(folga_esq)
	if com_moeda:
		var moeda: Control = Control.new()
		moeda.custom_minimum_size = Vector2(float(T.ESP_MD) - 2.0, 0.0)
		moeda.draw.connect(func() -> void:
			DesenhoUi.moedinha(moeda, moeda.size * 0.5, 7.0))
		linha.add_child(moeda)
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = &"TextoCorpo"
	rotulo.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	rotulo.add_theme_color_override("font_color", cor_texto)
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(rotulo)
	var folga_dir: Control = Control.new()
	folga_dir.custom_minimum_size = Vector2(float(T.ESP_XS) + 2.0, 0.0)
	linha.add_child(folga_dir)
	if acao.is_valid():
		_ligar_toque(chip, acao)
	else:
		chip.modulate.a = ALFA_GUARDA_LUGAR
	return chip


## Toque que CONVIVE com o scroll: mouse_filter PASS deixa o arrasto chegar
## ao ScrollContainer; a ação só dispara se o dedo soltou perto de onde
## tocou (rolou = a posição local muda porque o conteúdo andou por baixo).
## Eventos de MOUSE de propósito: no aparelho a rota é touch→mouse (a
## armadilha do joystick — ScreenTouch pode nunca chegar ao _gui_input).
const TOLERANCIA_TOQUE: float = 14.0

func _ligar_toque(alvo: Control, acao: Callable) -> void:
	alvo.mouse_filter = Control.MOUSE_FILTER_PASS
	var origem: Array[Vector2] = [Vector2.INF]
	alvo.gui_input.connect(func(evento: InputEvent) -> void:
		if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
			if evento.pressed:
				origem[0] = evento.position
			elif origem[0] != Vector2.INF:
				var perto: bool = evento.position.distance_to(origem[0]) < TOLERANCIA_TOQUE
				origem[0] = Vector2.INF
				if perto:
					acao.call())


## Chip-pílula de vidro com texto colorido (estado "✓ Equipada", "MÁX").
func _chip_vidro(texto: String, cor_texto: Color) -> Control:
	var chip: PanelContainer = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = T.COR_SUPERFICIE_VIDRO
	estilo.border_color = T.COR_SUPERFICIE_VIDRO_BORDA
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(T.RAIO_PILULA)
	estilo.content_margin_left = float(T.ESP_SM) + 2.0
	estilo.content_margin_right = float(T.ESP_SM) + 2.0
	estilo.content_margin_top = float(T.ESP_XS)
	estilo.content_margin_bottom = float(T.ESP_XS)
	chip.add_theme_stylebox_override("panel", estilo)
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = &"TextoCorpo"
	rotulo.add_theme_font_size_override("font_size", T.TAM_CORPO_SM)
	rotulo.add_theme_color_override("font_color", cor_texto)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(rotulo)
	return chip
