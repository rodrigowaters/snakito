extends RefCounted
## Constrói o `Theme` do Snakito a partir de `SnakitoTokens` e salva em disco.
##
## A lógica vive aqui (RefCounted, funções estáticas) e não no EditorScript
## porque `EditorScript` só instancia dentro do editor — assim a regeneração
## também roda headless (validação local e CI):
##   godot --headless -s tools/_script_que_chama_gerar_e_salvar.gd
## No editor, use `tools/gerar_tema.gd` (Arquivo > Executar).
##
## Regra dura #4 (CLAUDE.md): nenhum valor visual literal aqui — tudo vem de
## `tokens.gd`. Precisou de um valor novo? Crie o token primeiro.

const CAMINHO_SAIDA: String = "res://src/ui/theme/snakito_theme.tres"

## Alias curto para a classe de tokens (preload: referência direta à classe
## não é expressão constante em GDScript).
const T := preload("res://src/ui/theme/tokens.gd")


## Constrói o tema e grava em `CAMINHO_SAIDA`.
static func gerar_e_salvar() -> Error:
	var erro: Error = ResourceSaver.save(construir(), CAMINHO_SAIDA)
	if erro != OK:
		push_error("Falha ao salvar %s (erro %d)" % [CAMINHO_SAIDA, erro])
	return erro


## Monta o Theme completo em memória.
static func construir() -> Theme:
	var tema: Theme = Theme.new()

	# ------------------------------------------------------------------ fontes
	var fredoka_semibold: FontVariation = _fonte(T.CAMINHO_FONTE_DISPLAY, T.PESO_SEMIBOLD)
	var fredoka_bold: FontVariation = _fonte(T.CAMINHO_FONTE_DISPLAY, T.PESO_BOLD)
	var nunito_bold: FontVariation = _fonte(T.CAMINHO_FONTE_CORPO, T.PESO_BOLD)
	var nunito_extrabold: FontVariation = _fonte(T.CAMINHO_FONTE_CORPO, T.PESO_EXTRABOLD)
	var nunito_legenda: FontVariation = _fonte(
		T.CAMINHO_FONTE_CORPO, T.PESO_LEGENDA, T.tracking_em_pixels(T.TAM_LEGENDA)
	)
	# Padrão do tema = corpo; tipos display sobrescrevem com Fredoka.
	tema.default_font = nunito_bold
	tema.default_font_size = T.TAM_CORPO

	# -------------------------------------------- margens que completam o toque
	# O StyleBox reserva o que falta entre a linha de texto e o alvo de toque,
	# então botão/chip/campo nascem tocáveis sem custom_minimum_size na cena.
	var mv_botao: int = _margem_toque(T.TOQUE_PADRAO, T.ALTURA_LINHA_BOTAO)
	var mv_heroi: int = _margem_toque(T.TOQUE_HEROI, T.ALTURA_LINHA_BOTAO)
	var mv_chip: int = _margem_toque(T.TOQUE_MIN, T.ALTURA_LINHA_CORPO)
	var mv_campo: int = _margem_toque(T.TOQUE_PADRAO, T.ALTURA_LINHA_CORPO)

	# -------------------------------------------------------------- styleboxes
	var vidro: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_BOTAO, T.ESP_LG, mv_botao, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var vidro_press: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO_PRESS, T.RAIO_BOTAO, T.ESP_LG, mv_botao, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var desabilitado: StyleBoxFlat = _caixa(T.COR_FUNDO_DESABILITADO, T.RAIO_BOTAO, T.ESP_LG, mv_botao)
	var foco: StyleBoxFlat = _caixa(Color.TRANSPARENT, T.RAIO_BOTAO, T.ESP_LG, mv_botao, T.COR_FOCO, T.BORDA_DESTAQUE)
	var primario: StyleBoxFlat = _caixa(T.COR_CTA_PRIMARIO_MEDIO, T.RAIO_BOTAO, T.ESP_LG, mv_botao)
	var primario_press: StyleBoxFlat = _caixa(T.cor_press(T.COR_CTA_PRIMARIO_MEDIO), T.RAIO_BOTAO, T.ESP_LG, mv_botao)
	var heroi: StyleBoxFlat = _caixa(T.COR_CTA_PRIMARIO_MEDIO, T.RAIO_BOTAO, T.ESP_LG, mv_heroi)
	var heroi_press: StyleBoxFlat = _caixa(T.cor_press(T.COR_CTA_PRIMARIO_MEDIO), T.RAIO_BOTAO, T.ESP_LG, mv_heroi)
	var destrutivo: StyleBoxFlat = _caixa(T.COR_PERIGO_FUNDO, T.RAIO_BOTAO, T.ESP_LG, mv_botao, T.COR_PERIGO_BORDA, T.BORDA_FINA)
	var destrutivo_press: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO_PRESS, T.RAIO_BOTAO, T.ESP_LG, mv_botao, T.COR_PERIGO_BORDA, T.BORDA_FINA)
	var anuncio: StyleBoxFlat = _caixa(T.COR_CTA_ANUNCIO_MEDIO, T.RAIO_BOTAO, T.ESP_LG, mv_botao)
	var anuncio_press: StyleBoxFlat = _caixa(T.cor_press(T.COR_CTA_ANUNCIO_MEDIO), T.RAIO_BOTAO, T.ESP_LG, mv_botao)
	var chip: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_PILULA, T.ESP_MD, mv_chip, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var chip_press: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO_PRESS, T.RAIO_PILULA, T.ESP_MD, mv_chip, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var chip_ativo: StyleBoxFlat = _caixa(T.COR_CTA_PRIMARIO_MEDIO, T.RAIO_PILULA, T.ESP_MD, mv_chip)
	var chip_ativo_press: StyleBoxFlat = _caixa(T.cor_press(T.COR_CTA_PRIMARIO_MEDIO), T.RAIO_PILULA, T.ESP_MD, mv_chip)
	var foco_pilula: StyleBoxFlat = _caixa(Color.TRANSPARENT, T.RAIO_PILULA, T.ESP_MD, mv_chip, T.COR_FOCO, T.BORDA_DESTAQUE)
	var painel: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_1, T.RAIO_CARD, T.ESP_MD, T.ESP_MD, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var card: StyleBoxFlat = _caixa(T.COR_CARD_FUNDO, T.RAIO_CARD, T.ESP_MD, T.ESP_MD, T.COR_CARD_BORDA, T.BORDA_FINA)
	var modal: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_MODAL, T.RAIO_MODAL, T.ESP_LG, T.ESP_LG, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var hud: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_HUD, T.RAIO_BOTAO, T.ESP_MD, T.ESP_SM)
	# Badge de contador do blueprint (Home 01): VIDRO com borda, raio de
	# pílula (era superfície sólida raio 12 — infiel ao desenho, M2).
	var pilula_contador: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_PILULA, T.ESP_SM, T.ESP_XS, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var barra_fundo: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_2, T.RAIO_PILULA, 0, 0)
	var barra_cheia: StyleBoxFlat = _caixa(T.COR_CTA_PRIMARIO_MEDIO, T.RAIO_PILULA, 0, 0)
	var campo: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_BOTAO, T.ESP_MD, mv_campo, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_DESTAQUE)
	var campo_foco: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_BOTAO, T.ESP_MD, mv_campo, T.COR_FOCO, T.BORDA_DESTAQUE)
	var campo_erro: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_BOTAO, T.ESP_MD, mv_campo, T.COR_PERIGO_ACAO, T.BORDA_DESTAQUE)
	var campo_ro: StyleBoxFlat = _caixa(T.COR_FUNDO_DESABILITADO, T.RAIO_BOTAO, T.ESP_MD, mv_campo)

	# -------------------------------------------- Button (base = secundário)
	for item: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		tema.set_color(item, &"Button", T.COR_TEXTO_PRIMARIO)
	tema.set_color(&"font_disabled_color", &"Button", T.COR_TEXTO_MUTED)
	tema.set_color(&"font_outline_color", &"Button", Color.TRANSPARENT)
	tema.set_color(&"icon_normal_color", &"Button", T.COR_TEXTO_PRIMARIO)
	tema.set_constant(&"h_separation", &"Button", T.ESP_XS)
	tema.set_constant(&"outline_size", &"Button", 0)
	tema.set_font(&"font", &"Button", fredoka_semibold)
	tema.set_font_size(&"font_size", &"Button", T.TAM_BOTAO)
	tema.set_stylebox(&"normal", &"Button", vidro)
	tema.set_stylebox(&"hover", &"Button", vidro)  # alvo é Android: hover = normal
	tema.set_stylebox(&"pressed", &"Button", vidro_press)
	tema.set_stylebox(&"disabled", &"Button", desabilitado)
	tema.set_stylebox(&"focus", &"Button", foco)

	# ------------------------------------------------- Label (base = corpo)
	tema.set_color(&"font_color", &"Label", T.COR_TEXTO_PRIMARIO)
	tema.set_color(&"font_outline_color", &"Label", Color.TRANSPARENT)
	tema.set_color(&"font_shadow_color", &"Label", Color.TRANSPARENT)
	tema.set_constant(&"line_spacing", &"Label", T.espacamento_linha(T.TAM_CORPO, T.ALTURA_LINHA_CORPO))
	tema.set_constant(&"outline_size", &"Label", 0)
	tema.set_constant(&"shadow_offset_x", &"Label", 0)
	tema.set_constant(&"shadow_offset_y", &"Label", 0)
	tema.set_font_size(&"font_size", &"Label", T.TAM_CORPO)
	tema.set_stylebox(&"normal", &"Label", StyleBoxEmpty.new())

	# ----------------------------------------------- Panel / PanelContainer
	tema.set_stylebox(&"panel", &"Panel", painel)
	tema.set_stylebox(&"panel", &"PanelContainer", painel)

	# --------------------------------------------------------------- LineEdit
	tema.set_color(&"font_color", &"LineEdit", T.COR_TEXTO_PRIMARIO)
	tema.set_color(&"font_placeholder_color", &"LineEdit", T.COR_TEXTO_MUTED)
	tema.set_color(&"font_selected_color", &"LineEdit", T.COR_TEXTO_SOBRE_PRIMARIO)
	tema.set_color(&"font_uneditable_color", &"LineEdit", T.COR_TEXTO_MUTED)
	tema.set_color(&"caret_color", &"LineEdit", T.COR_FOCO)
	tema.set_color(&"selection_color", &"LineEdit", T.COR_SELECAO_TEXTO)
	tema.set_font_size(&"font_size", &"LineEdit", T.TAM_CORPO)
	tema.set_stylebox(&"normal", &"LineEdit", campo)
	tema.set_stylebox(&"focus", &"LineEdit", campo_foco)
	tema.set_stylebox(&"read_only", &"LineEdit", campo_ro)

	# ------------------------------------------------------------ ProgressBar
	tema.set_color(&"font_color", &"ProgressBar", T.COR_TEXTO_PRIMARIO)
	tema.set_font_size(&"font_size", &"ProgressBar", T.TAM_CORPO_SM)
	tema.set_stylebox(&"background", &"ProgressBar", barra_fundo)
	tema.set_stylebox(&"fill", &"ProgressBar", barra_cheia)

	# ---------------------------------------------------- variações de botão
	_variacao_botao(tema, &"BotaoPrimario", primario, primario_press, desabilitado, foco, T.COR_TEXTO_SOBRE_PRIMARIO, T.TAM_BOTAO)
	_variacao_botao(tema, &"BotaoHeroi", heroi, heroi_press, desabilitado, foco, T.COR_TEXTO_SOBRE_PRIMARIO, T.TAM_BOTAO)
	_variacao_botao(tema, &"BotaoSecundario", vidro, vidro_press, desabilitado, foco, T.COR_TEXTO_PRIMARIO, T.TAM_BOTAO)
	_variacao_botao(tema, &"BotaoDestrutivo", destrutivo, destrutivo_press, desabilitado, foco, T.COR_PERIGO_TEXTO, T.TAM_BOTAO)
	_variacao_botao(tema, &"BotaoAnuncio", anuncio, anuncio_press, desabilitado, foco, T.COR_TEXTO_SOBRE_OFERTA_ANUNCIO, T.TAM_BOTAO)
	_variacao_botao(tema, &"Chip", chip, chip_press, desabilitado, foco_pilula, T.COR_TEXTO_SECUNDARIO, T.TAM_CORPO, nunito_extrabold)
	_variacao_botao(tema, &"ChipAtivo", chip_ativo, chip_ativo_press, desabilitado, foco_pilula, T.COR_TEXTO_SOBRE_PRIMARIO, T.TAM_CORPO, nunito_extrabold)

	# Blueprint da Home (M2): chip QUADRADO de vidro (avatar/⚙, raio de botão,
	# margens mínimas — o tamanho vem da cena: 48×48) e cartão da grade de
	# navegação (vidro, raio de card, conteúdo empilhado pela cena).
	var chip_quadrado: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_BOTAO, T.ESP_MICRO, T.ESP_MICRO, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var chip_quadrado_press: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO_PRESS, T.RAIO_BOTAO, T.ESP_MICRO, T.ESP_MICRO, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var foco_quadrado: StyleBoxFlat = _caixa(Color.TRANSPARENT, T.RAIO_BOTAO, T.ESP_MICRO, T.ESP_MICRO, T.COR_FOCO, T.BORDA_DESTAQUE)
	_variacao_botao(tema, &"ChipQuadrado", chip_quadrado, chip_quadrado_press, desabilitado, foco_quadrado, T.COR_TEXTO_PRIMARIO, T.TAM_TITULO_MD)
	var cartao_nav: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO, T.RAIO_CARD, T.ESP_XS, T.ESP_XS, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var cartao_nav_press: StyleBoxFlat = _caixa(T.COR_SUPERFICIE_VIDRO_PRESS, T.RAIO_CARD, T.ESP_XS, T.ESP_XS, T.COR_SUPERFICIE_VIDRO_BORDA, T.BORDA_FINA)
	var foco_cartao: StyleBoxFlat = _caixa(Color.TRANSPARENT, T.RAIO_CARD, T.ESP_XS, T.ESP_XS, T.COR_FOCO, T.BORDA_DESTAQUE)
	_variacao_botao(tema, &"CartaoNav", cartao_nav, cartao_nav_press, desabilitado, foco_cartao, T.COR_TEXTO_PRIMARIO, T.TAM_CORPO_SM)

	# --------------------------------------------------- variações de painel
	_variacao_painel(tema, &"CardPainel", card)
	_variacao_painel(tema, &"ModalPainel", modal)
	_variacao_painel(tema, &"HudPainel", hud)
	_variacao_painel(tema, &"PilulaContador", pilula_contador)

	# ------------------- CampoErro (LineEdit não tem estado "erro" nativo)
	tema.set_type_variation(&"CampoErro", &"LineEdit")
	tema.set_color(&"font_color", &"CampoErro", T.COR_TEXTO_PRIMARIO)
	tema.set_color(&"font_placeholder_color", &"CampoErro", T.COR_TEXTO_MUTED)
	tema.set_color(&"caret_color", &"CampoErro", T.COR_PERIGO_ACAO)
	tema.set_font_size(&"font_size", &"CampoErro", T.TAM_CORPO)
	tema.set_stylebox(&"normal", &"CampoErro", campo_erro)
	tema.set_stylebox(&"focus", &"CampoErro", campo_erro)
	tema.set_stylebox(&"read_only", &"CampoErro", campo_ro)

	# ----------------------------------------------------- variações de texto
	_variacao_texto(tema, &"TituloHero", T.TAM_HERO, T.ALTURA_LINHA_HERO, T.COR_TEXTO_PRIMARIO, fredoka_bold)
	_variacao_texto(tema, &"TituloScore", T.TAM_SCORE, T.ALTURA_LINHA_SCORE, T.COR_TEXTO_PRIMARIO, fredoka_bold)
	_variacao_texto(tema, &"TituloLg", T.TAM_TITULO_LG, T.ALTURA_LINHA_TITULO_LG, T.COR_TEXTO_PRIMARIO, fredoka_semibold)
	_variacao_texto(tema, &"TituloMd", T.TAM_TITULO_MD, T.ALTURA_LINHA_TITULO_MD, T.COR_TEXTO_PRIMARIO, fredoka_semibold)
	_variacao_texto(tema, &"TextoCorpo", T.TAM_CORPO, T.ALTURA_LINHA_CORPO, T.COR_TEXTO_PRIMARIO)
	_variacao_texto(tema, &"TextoCorpoSm", T.TAM_CORPO_SM, T.ALTURA_LINHA_CORPO_SM, T.COR_TEXTO_SECUNDARIO)
	# Rótulo das células de navegação (blueprint 1d: Fredoka 13 branco).
	_variacao_texto(tema, &"RotuloNav", T.TAM_CORPO_SM, T.ALTURA_LINHA_CORPO_SM, T.COR_TEXTO_PRIMARIO, fredoka_semibold)
	# Rótulo do CTA-herói (blueprint 01: Fredoka 600 22px sobre o gradiente).
	_variacao_texto(tema, &"RotuloCtaHeroi", T.TAM_CTA_HEROI, T.ALTURA_LINHA_CTA_HEROI, T.COR_TEXTO_SOBRE_PRIMARIO, fredoka_semibold)
	_variacao_texto(tema, &"TextoSecundario", T.TAM_CORPO, T.ALTURA_LINHA_CORPO, T.COR_TEXTO_SECUNDARIO)
	# TextoMuted usa o MENOR tamanho permitido para #7E88A8 (negrito ≥ 19px);
	# altura de linha herdada da escala title/md, o degrau mais próximo.
	_variacao_texto(tema, &"TextoMuted", T.TAM_MIN_TEXTO_MUTED_BOLD, T.ALTURA_LINHA_TITULO_MD, T.COR_TEXTO_MUTED)
	_variacao_texto(tema, &"TextoLegenda", T.TAM_LEGENDA, T.ALTURA_LINHA_LEGENDA, T.COR_TEXTO_SECUNDARIO, nunito_legenda)
	_variacao_texto(tema, &"TextoSucesso", T.TAM_CORPO, T.ALTURA_LINHA_CORPO, T.COR_SUCESSO)
	_variacao_texto(tema, &"TextoPerigo", T.TAM_CORPO_SM, T.ALTURA_LINHA_CORPO_SM, T.COR_PERIGO_TEXTO)
	_variacao_texto(tema, &"TextoAlerta", T.TAM_CORPO, T.ALTURA_LINHA_CORPO, T.COR_ALERTA)
	_variacao_texto(tema, &"TextoInfo", T.TAM_CORPO, T.ALTURA_LINHA_CORPO, T.COR_INFO)

	return tema


## Cria uma FontVariation da fonte variável em `caminho`, no peso dado
## (eixo `wght`) e com tracking opcional em pixels.
static func _fonte(caminho: String, peso: int, tracking: int = 0) -> FontVariation:
	var fonte: FontVariation = FontVariation.new()
	fonte.base_font = load(caminho) as Font
	# ARMADILHA: chave String ("wght") NÃO aplica o eixo da fonte variável —
	# falha silenciosa que deixou o app inteiro no peso 400 desde a fundação
	# (descoberta na fidelidade do CTA, M2). O tag numérico aplica.
	fonte.variation_opentype = {
		TextServerManager.get_primary_interface().name_to_tag("weight"): peso,
	}
	if tracking > 0:
		fonte.spacing_glyph = tracking
	return fonte


## StyleBoxFlat com margens de conteúdo, raio e borda opcional.
static func _caixa(
	fundo: Color,
	raio: int,
	margem_h: int,
	margem_v: int,
	cor_borda: Color = Color.TRANSPARENT,
	borda: int = 0,
) -> StyleBoxFlat:
	var caixa: StyleBoxFlat = StyleBoxFlat.new()
	caixa.bg_color = fundo
	caixa.set_corner_radius_all(raio)
	caixa.content_margin_left = float(margem_h)
	caixa.content_margin_right = float(margem_h)
	caixa.content_margin_top = float(margem_v)
	caixa.content_margin_bottom = float(margem_v)
	if borda > 0:
		caixa.set_border_width_all(borda)
		caixa.border_color = cor_borda
	return caixa


## Margem vertical que completa o alvo de toque a partir da altura da linha.
static func _margem_toque(alvo: int, altura_linha: int) -> int:
	return maxi(0, roundi(float(alvo - altura_linha) / 2.0))


## Registra uma variação de botão com estados normal/pressionado.
static func _variacao_botao(
	tema: Theme,
	nome: StringName,
	normal: StyleBox,
	press: StyleBox,
	desabilitado: StyleBox,
	foco: StyleBox,
	cor_texto: Color,
	tamanho: int,
	fonte: FontVariation = null,
) -> void:
	tema.set_type_variation(nome, &"Button")
	for item: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		tema.set_color(item, nome, cor_texto)
	tema.set_color(&"font_disabled_color", nome, T.COR_TEXTO_MUTED)
	tema.set_color(&"icon_normal_color", nome, cor_texto)
	tema.set_constant(&"h_separation", nome, T.ESP_XS)
	tema.set_font_size(&"font_size", nome, tamanho)
	tema.set_stylebox(&"normal", nome, normal)
	tema.set_stylebox(&"hover", nome, normal)
	tema.set_stylebox(&"pressed", nome, press)
	tema.set_stylebox(&"disabled", nome, desabilitado)
	tema.set_stylebox(&"focus", nome, foco)
	if fonte != null:
		tema.set_font(&"font", nome, fonte)


## Registra uma variação de painel.
static func _variacao_painel(tema: Theme, nome: StringName, estilo: StyleBox) -> void:
	tema.set_type_variation(nome, &"PanelContainer")
	tema.set_stylebox(&"panel", nome, estilo)


## Registra uma variação de Label com tamanho/altura de linha/cor.
static func _variacao_texto(
	tema: Theme,
	nome: StringName,
	tamanho: int,
	altura_linha: int,
	cor: Color,
	fonte: FontVariation = null,
) -> void:
	tema.set_type_variation(nome, &"Label")
	tema.set_color(&"font_color", nome, cor)
	tema.set_constant(&"line_spacing", nome, T.espacamento_linha(tamanho, altura_linha))
	tema.set_font_size(&"font_size", nome, tamanho)
	if fonte != null:
		tema.set_font(&"font", nome, fonte)
