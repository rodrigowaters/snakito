extends SceneTree
## Validação headless da fundação visual — smoke test rápido para local/CI:
##   godot --headless --quit-after 30 -s tools/validar_fundacao.gd
## Sai com código = número de falhas. Além dos checks de tokens e tema,
## faz o round-trip que o gdUnit4 não cobre: regenera o .tres via
## tema_builder.gd e revalida o resultado.

var falhas: int = 0


func _initialize() -> void:
	print("== 1 · tokens.gd ==")
	_ok(absf(SnakitoTokens.razao_contraste(Color.BLACK, Color.WHITE) - 21.0) < 0.01,
		"razao_contraste(preto, branco) = 21")
	_ok(SnakitoTokens.compor_sobre(Color(1, 0, 0, 0), Color(0, 1, 0)).g == 1.0,
		"compor_sobre com alpha 0 devolve o fundo")
	_ok(SnakitoTokens.cor_cobra(SnakitoTokens.CorCobra.LIMA) == Color("#BEF264"),
		"cor_cobra(LIMA)")
	_ok(SnakitoTokens.tracking_em_pixels(12) == 1, "tracking_em_pixels(12) = 1 (piso)")
	for i: int in SnakitoTokens.TOTAL_CORES_COBRA:
		var caminho: String = SnakitoTokens.caminho_simbolo(SnakitoTokens.SIMBOLOS_COBRA[i])
		_ok(FileAccess.file_exists(caminho), "asset existe: " + caminho)

	print("\n== 2 · tema versionado (escrito à mão) ==")
	var tema: Theme = load("res://src/ui/theme/snakito_theme.tres") as Theme
	_checar_tema(tema)

	print("\n== 3 · regeneração via tools/tema_builder.gd ==")
	var erro: Error = preload("res://tools/tema_builder.gd").gerar_e_salvar()
	_ok(erro == OK, "gerar_e_salvar() retorna OK")
	var regen: Theme = ResourceLoader.load(
		"res://src/ui/theme/snakito_theme.tres", "Theme", ResourceLoader.CACHE_MODE_IGNORE
	) as Theme
	_checar_tema(regen)

	print("\n%s: %d falha(s)" % ["RESULTADO", falhas])
	quit(falhas)


func _checar_tema(tema: Theme) -> void:
	if tema == null:
		_ok(false, "tema carrega")
		return
	_ok(true, "tema carrega")
	_ok(tema.default_font is FontVariation, "default_font é FontVariation")
	if tema.default_font is FontVariation:
		var fv: FontVariation = tema.default_font as FontVariation
		_ok(int(fv.variation_opentype.get("wght", 0)) == 700, "default_font wght=700 (Nunito)")
		_ok(fv.base_font != null, "default_font tem base_font carregada")
	_ok(tema.default_font_size == SnakitoTokens.TAM_CORPO, "default_font_size = 15")
	_ok(tema.get_type_variation_base(&"BotaoPrimario") == &"Button", "BotaoPrimario ← Button")
	_ok(tema.get_type_variation_base(&"CampoErro") == &"LineEdit", "CampoErro ← LineEdit")
	_ok(tema.get_type_variation_base(&"TituloHero") == &"Label", "TituloHero ← Label")
	_ok(tema.get_type_variation_base(&"CardPainel") == &"PanelContainer", "CardPainel ← PanelContainer")
	var fonte_botao: Font = tema.get_font(&"font", &"Button")
	_ok(fonte_botao is FontVariation
		and int((fonte_botao as FontVariation).variation_opentype.get("wght", 0)) == 600,
		"Button usa Fredoka wght=600")
	var heroi: StyleBoxFlat = tema.get_stylebox(&"normal", &"BotaoHeroi") as StyleBoxFlat
	_ok(heroi != null and int(heroi.content_margin_top) == 20, "BotaoHeroi margem vertical 20 (alvo 64dp)")
	_ok(heroi != null and heroi.bg_color.is_equal_approx(SnakitoTokens.COR_CTA_PRIMARIO_MEDIO),
		"BotaoHeroi fundo = COR_CTA_PRIMARIO_MEDIO")
	var press: StyleBoxFlat = tema.get_stylebox(&"pressed", &"BotaoHeroi") as StyleBoxFlat
	_ok(press != null and press.bg_color.is_equal_approx(
		SnakitoTokens.cor_press(SnakitoTokens.COR_CTA_PRIMARIO_MEDIO)),
		"BotaoHeroi press = darkened(6%)")
	_ok(tema.get_color(&"font_color", &"TextoPerigo").is_equal_approx(SnakitoTokens.COR_PERIGO_TEXTO),
		"TextoPerigo cor = COR_PERIGO_TEXTO")
	var legenda: Font = tema.get_font(&"font", &"TextoLegenda")
	_ok(legenda is FontVariation and (legenda as FontVariation).spacing_glyph == 1,
		"TextoLegenda com tracking 1px")


func _ok(condicao: bool, rotulo: String) -> void:
	if condicao:
		print("  OK    ", rotulo)
	else:
		falhas += 1
		printerr("  FALHA ", rotulo)
