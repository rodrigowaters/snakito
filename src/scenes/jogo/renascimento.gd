class_name Renascimento
extends CanvasLayer
## Interlúdio de morte suave — blueprint "04b Renascimento" (M2). A morte no
## Arcade cai AQUI antes da pós-partida: fantasminha, contagem regressiva e
## as saídas. Renascer com anúncio (AdMob) e por ticket são M3 — os botões
## guardam o lugar desabilitados; "Não, ver resultado" e o timeout seguem
## para o resultado. Desafio NÃO passa por aqui (morte resolve o desafio;
## renascer quebraria a comparabilidade da seed).

const T := preload("res://src/ui/theme/tokens.gd")

## Segundos até seguir sozinho para o resultado (10 a pedido do Rodrigo,
## 11/08 — folga para a criança ler as opções).
const CONTAGEM_SEG: float = 10.0

signal resolvido

var _restante: float = CONTAGEM_SEG
var _anel: Control
var _rotulo_contagem: Label


func _ready() -> void:
	layer = 10
	_montar()


func _process(delta: float) -> void:
	_restante -= delta
	if _restante <= 0.0:
		set_process(false)
		resolvido.emit()
		return
	_rotulo_contagem.text = str(ceili(_restante))
	_anel.queue_redraw()


func _montar() -> void:
	# Véu sobre a arena congelada.
	var veu: ColorRect = ColorRect.new()
	veu.color = T.COR_SUPERFICIE_HUD
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veu)

	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	add_child(margem)
	var centro: VBoxContainer = VBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	margem.add_child(centro)

	var painel: PanelContainer = PanelContainer.new()
	painel.theme_type_variation = &"ModalPainel"
	centro.add_child(painel)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", T.ESP_MD)
	painel.add_child(coluna)

	# Fantasminha + anel de contagem, lado a lado como no desenho.
	var topo: HBoxContainer = HBoxContainer.new()
	topo.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.add_theme_constant_override("separation", T.ESP_SM)
	coluna.add_child(topo)
	var fantasma: Control = Control.new()
	fantasma.custom_minimum_size = Vector2(170.0, 104.0)
	fantasma.draw.connect(_desenhar_fantasma.bind(fantasma))
	topo.add_child(fantasma)
	_anel = Control.new()
	_anel.custom_minimum_size = Vector2(float(T.TOQUE_HEROI), float(T.TOQUE_HEROI))
	_anel.draw.connect(_desenhar_anel.bind(_anel))
	topo.add_child(_anel)
	_rotulo_contagem = Label.new()
	_rotulo_contagem.theme_type_variation = &"TituloMd"
	_rotulo_contagem.add_theme_color_override("font_color", T.COR_INFO)
	_rotulo_contagem.set_anchors_preset(Control.PRESET_CENTER)
	_rotulo_contagem.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_rotulo_contagem.grow_vertical = Control.GROW_DIRECTION_BOTH
	_rotulo_contagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_contagem.text = str(int(CONTAGEM_SEG))
	_anel.add_child(_rotulo_contagem)

	var titulo: Label = Label.new()
	titulo.text = "Ops! Você foi devorada"
	titulo.theme_type_variation = &"TituloLg"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)

	var sub: Label = Label.new()
	sub.text = "Renasça e continue de onde parou\ncom seus %s pts" \
		% Hud.formatar_milhar(Sessao.ultimo_motor.jogador().pontos
			if Sessao.ultimo_motor != null else 0)
	sub.theme_type_variation = &"TextoSecundario"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(sub)

	# ▶ Renascer com anúncio — AdMob é M3; guarda o lugar (gradiente laranja).
	var anuncio: Button = Button.new()
	anuncio.flat = true
	anuncio.disabled = true
	anuncio.custom_minimum_size = Vector2(0.0, float(T.TOQUE_PADRAO) + 2.0)
	anuncio.draw.connect(func() -> void:
		DesenhoUi.gradiente_arredondado(anuncio, anuncio.size,
			float(T.RAIO_CARD) - 2.0, T.COR_CTA_ANUNCIO_INICIO, T.COR_CTA_ANUNCIO_FIM))
	var rotulo_anuncio: Label = Label.new()
	rotulo_anuncio.text = "▶ Renascer com anúncio"
	rotulo_anuncio.theme_type_variation = &"TituloMd"
	rotulo_anuncio.add_theme_color_override("font_color", T.COR_TEXTO_SOBRE_OFERTA_ANUNCIO)
	rotulo_anuncio.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo_anuncio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_anuncio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo_anuncio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anuncio.add_child(rotulo_anuncio)
	anuncio.modulate.a = 0.55  # apagado até o AdMob (M3)
	coluna.add_child(anuncio)

	# 🎟️ Pular anúncio com ticket — economia é M3; saldo atual no rótulo.
	var ticket: Button = Button.new()
	ticket.text = "🎟️ Pular anúncio · usar 1 de %d" % ProgressoLocal.tickets()
	ticket.theme_type_variation = &"BotaoSecundario"
	ticket.disabled = true
	ticket.add_theme_stylebox_override("disabled",
		ThemeDB.get_project_theme().get_stylebox(&"normal", &"BotaoSecundario"))
	ticket.add_theme_color_override("font_disabled_color", T.COR_TEXTO_SECUNDARIO)
	coluna.add_child(ticket)

	var ver_resultado: Button = Button.new()
	ver_resultado.text = "Não, ver resultado"
	ver_resultado.flat = true
	ver_resultado.pressed.connect(func() -> void:
		set_process(false)
		resolvido.emit())
	coluna.add_child(ver_resultado)

	# Pill do VIP (assinatura é futuro) — informativa, apagada.
	var linha_vip: HBoxContainer = HBoxContainer.new()
	linha_vip.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_child(linha_vip)
	var vip: PanelContainer = PanelContainer.new()
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = Color(T.COR_MOEDA, 0.08)
	caixa.set_corner_radius_all(T.RAIO_PILULA)
	caixa.set_border_width_all(T.BORDA_FINA)
	caixa.border_color = Color(T.COR_MOEDA, 0.3)
	caixa.content_margin_left = float(T.ESP_SM)
	caixa.content_margin_right = float(T.ESP_SM)
	caixa.content_margin_top = float(T.ESP_MICRO + 3)
	caixa.content_margin_bottom = float(T.ESP_MICRO + 3)
	vip.add_theme_stylebox_override("panel", caixa)
	var rotulo_vip: Label = Label.new()
	rotulo_vip.text = "👑 VIP renasce grátis · 1/semana"
	rotulo_vip.theme_type_variation = &"TextoLegenda"
	rotulo_vip.add_theme_color_override("font_color", T.COR_MOEDA)
	vip.add_child(rotulo_vip)
	vip.modulate.a = 0.55
	linha_vip.add_child(vip)


## Fantasminha do desenho (04b).
func _desenhar_fantasma(alvo: Control) -> void:
	DesenhoUi.fantasma(alvo, alvo.size)


## Anel de contagem: trilha de vidro + arco azul proporcional ao restante.
func _desenhar_anel(alvo: Control) -> void:
	var centro: Vector2 = alvo.size * 0.5
	var raio: float = minf(centro.x, centro.y) - 4.0
	alvo.draw_arc(centro, raio, 0.0, TAU, 40, T.COR_SUPERFICIE_VIDRO_BORDA, 6.0)
	var fracao: float = clampf(_restante / CONTAGEM_SEG, 0.0, 1.0)
	if fracao > 0.0:
		alvo.draw_arc(centro, raio, -PI * 0.5, -PI * 0.5 + TAU * fracao, 40,
			T.CORES_COBRA_BASE[1], 6.0)
