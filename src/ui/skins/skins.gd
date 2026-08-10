class_name Skins
extends Control
## Skins do MVP+M1: 4 cores da paleta do design, todas grátis. Skins NUNCA
## dão vantagem (regra dura #7) — é só a cor da sua cobra. Loja com skins
## premium é M2.

const T := preload("res://src/ui/theme/tokens.gd")

## Índices na paleta `CORES_COBRA_BASE`: verde (padrão) + 3 do M1.
## Turquesa ficou de fora de propósito: no tamanho de jogo ela é vizinha
## demais do verde — as 4 escolhidas são inconfundíveis entre si.
const SKINS: Array[Dictionary] = [
	{"indice": 0, "nome": "Verdinha"},
	{"indice": 1, "nome": "Azulzinha"},
	{"indice": 2, "nome": "Rosinha"},
	{"indice": 3, "nome": "Amarelinha"},
]

var _coluna: VBoxContainer


func _ready() -> void:
	_montar_fundo()
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL)
	margem.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(margem)
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", T.ESP_SM)
	margem.add_child(_coluna)
	_remontar()


func _remontar() -> void:
	for filho: Node in _coluna.get_children():
		filho.queue_free()

	var titulo: Label = Label.new()
	titulo.text = "Skins"
	titulo.theme_type_variation = &"TituloHero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(titulo)

	var subtitulo: Label = Label.new()
	subtitulo.text = "Só estilo — nenhuma dá vantagem"
	subtitulo.theme_type_variation = &"TextoSecundario"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(subtitulo)

	for skin: Dictionary in SKINS:
		_coluna.add_child(_card(skin))

	var voltar: Button = Button.new()
	voltar.text = "Voltar"
	voltar.theme_type_variation = &"BotaoSecundario"
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/home/home.tscn"))
	_coluna.add_child(voltar)


func _card(skin: Dictionary) -> PanelContainer:
	var indice: int = skin["indice"]
	var equipada: bool = ProgressoLocal.skin_equipada() == indice

	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPainel"
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override("separation", T.ESP_MD)
	card.add_child(linha)

	linha.add_child(_preview(indice))

	var nome: Label = Label.new()
	nome.text = skin["nome"]
	nome.theme_type_variation = &"TituloMd"
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(nome)

	if equipada:
		var selo: Label = Label.new()
		selo.text = "✓ Equipada"
		selo.theme_type_variation = &"TextoSucesso"
		selo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		linha.add_child(selo)
	else:
		var equipar: Button = Button.new()
		equipar.text = "Equipar"
		equipar.theme_type_variation = &"BotaoPrimario"
		equipar.pressed.connect(func() -> void:
			ProgressoLocal.equipar_skin(indice)
			_remontar())
		linha.add_child(equipar)

	return card


## Mini-cobra de preview: 3 segmentos + cabeça com olhos, como no design.
func _preview(indice: int) -> Control:
	var desenho: Control = Control.new()
	desenho.custom_minimum_size = Vector2(float(T.TOQUE_PADRAO), float(T.TOQUE_MIN))
	desenho.draw.connect(func() -> void:
		var cor: Color = T.CORES_COBRA_BASE[indice]
		var centro_y: float = desenho.size.y * 0.5
		desenho.draw_circle(Vector2(10.0, centro_y), 7.0, Color(cor, 0.6))
		desenho.draw_circle(Vector2(21.0, centro_y), 8.5, Color(cor, 0.8))
		desenho.draw_circle(Vector2(35.0, centro_y), 11.0, cor)
		desenho.draw_circle(Vector2(38.5, centro_y - 3.5), 2.8, T.COR_SIMBOLO_DALTONISMO)
		desenho.draw_circle(Vector2(38.5, centro_y + 3.5), 2.8, T.COR_SIMBOLO_DALTONISMO))
	return desenho


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
