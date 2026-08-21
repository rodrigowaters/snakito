extends SceneTree
## Gráfico de destaque da ficha da Play Store (1024×500 obrigatório).
##   godot --quit-after 90 -s tools/gerar_destaque.gd
## Precisa de JANELA (headless não renderiza) — a janela abre e fecha.
##
## Saída: assets/loja/destaque_1024x500.png
##
## Composto com os MESMOS tokens do jogo (regra dura #4): quem vê a ficha
## e quem abre o app veem a mesma marca. Título em Fredoka, como no app.

const T := preload("res://src/ui/theme/tokens.gd")

const LADO: Vector2i = Vector2i(1024, 500)


func _initialize() -> void:
	DisplayServer.window_set_size(LADO)
	root.content_scale_size = LADO
	root.size = LADO
	_montar()
	_capturar.call_deferred()


func _montar() -> void:
	var tela: Control = Control.new()
	tela.size = Vector2(LADO)
	root.add_child(tela)

	# Fundo: gradiente da marca, na diagonal do design.
	var gradiente: Gradient = Gradient.new()
	gradiente.colors = PackedColorArray([T.COR_APP_FUNDO_INICIO, T.COR_APP_FUNDO_FIM])
	var textura: GradientTexture2D = GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2.ZERO
	textura.fill_to = Vector2(1.0, 0.6)
	var fundo: TextureRect = TextureRect.new()
	fundo.texture = textura
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.size = Vector2(LADO)
	tela.add_child(fundo)

	# Cobras de fundo, bem apagadas: dá movimento sem competir com o texto.
	var enfeite: Control = Control.new()
	enfeite.size = Vector2(LADO)
	enfeite.draw.connect(func() -> void:
		_desenhar_cobra(enfeite, Vector2(980.0, 430.0), 1.2, T.CORES_COBRA_BASE[1], 0.18)
		_desenhar_cobra(enfeite, Vector2(700.0, 470.0), 0.9, T.CORES_COBRA_BASE[3], 0.13))
	tela.add_child(enfeite)

	# Herói: a cobra verde grande à direita.
	var heroi: Control = Control.new()
	heroi.size = Vector2(LADO)
	heroi.draw.connect(func() -> void:
		_desenhar_cobra(heroi, Vector2(830.0, 190.0), 2.0, T.CORES_COBRA_BASE[0], 1.0))
	tela.add_child(heroi)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.position = Vector2(72.0, 150.0)
	coluna.custom_minimum_size = Vector2(520.0, 0.0)
	coluna.add_theme_constant_override("separation", T.ESP_SM)
	tela.add_child(coluna)

	var titulo: Label = Label.new()
	titulo.text = "Snakito"
	titulo.theme_type_variation = &"TituloHero"
	titulo.add_theme_font_size_override("font_size", 92)
	titulo.add_theme_color_override("font_color", T.CORES_COBRA_BASE[0])
	coluna.add_child(titulo)

	var linha: Label = Label.new()
	linha.text = "Cresça, escape, domine a arena"
	linha.theme_type_variation = &"TituloMd"
	linha.add_theme_font_size_override("font_size", 30)
	coluna.add_child(linha)

	var sub: Label = Label.new()
	sub.text = "Estratégia em tempo real · 7+ · joga offline"
	sub.theme_type_variation = &"TextoSecundario"
	sub.add_theme_font_size_override("font_size", 21)
	coluna.add_child(sub)


## Cobrinha do design: segmentos crescendo + cabeça com olhos.
func _desenhar_cobra(alvo: CanvasItem, cabeca: Vector2, escala: float,
		cor: Color, alfa: float) -> void:
	var raios: Array[float] = [10.0, 13.0, 16.0, 19.0, 22.0, 26.0]
	var passo: Vector2 = Vector2(-46.0, 26.0) * escala
	var ponto: Vector2 = cabeca
	for i: int in raios.size():
		var indice: int = raios.size() - 1 - i
		var raio: float = raios[indice] * escala
		var fracao: float = 1.0 - float(i) / float(raios.size())
		alvo.draw_circle(ponto, raio, Color(cor, alfa * lerpf(0.45, 1.0, fracao)))
		ponto += passo * (0.62 + 0.05 * float(i))
	# Olhos na cabeça (o primeiro círculo desenhado é a cauda; a cabeça é
	# `cabeca`, desenhada por último acima).
	var raio_cabeca: float = raios[raios.size() - 1] * escala
	if alfa > 0.5:
		for lado: float in [-1.0, 1.0]:
			var centro: Vector2 = cabeca + Vector2(lado * raio_cabeca * 0.34, -raio_cabeca * 0.22)
			alvo.draw_circle(centro, raio_cabeca * 0.26, Color.WHITE)
			alvo.draw_circle(centro + Vector2(0.0, raio_cabeca * 0.05),
				raio_cabeca * 0.12, T.COR_APP_FUNDO_INICIO)


func _capturar() -> void:
	for i: int in 30:
		await process_frame
	var imagem: Image = root.get_texture().get_image()
	if imagem.get_width() != LADO.x or imagem.get_height() != LADO.y:
		imagem.resize(LADO.x, LADO.y, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute("res://assets/loja")
	var destino: String = "res://assets/loja/destaque_1024x500.png"
	var erro: Error = imagem.save_png(destino)
	print("destaque: %s (%dx%d, erro=%d)" % [destino, imagem.get_width(), imagem.get_height(), erro])
	quit(0 if erro == OK else 1)
