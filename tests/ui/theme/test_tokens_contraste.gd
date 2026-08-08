class_name TestTokensContraste
extends GdUnitTestSuite
## Regressão de acessibilidade dos tokens (WCAG 2.1 AA).
##
## Espelha `docs/design/wcag-report.md`: cada teste trava um grupo de pares do
## relatório. Se um teste quebrar depois de mudar um token, o relatório
## versionado deixou de valer — regenere os dois juntos.
##
## Requer o addon gdUnit4 instalado em `addons/gdUnit4`.

## Alias curto para a classe de tokens.
const T := SnakitoTokens


## Fundos opacos onde texto pode aparecer. Superfícies translúcidas já vêm
## compostas sobre o fundo real — validar a cor com alpha "no vácuo" esconde
## exatamente o tipo de reprovação que este teste existe para pegar.
func _fundos_de_texto() -> Dictionary:
	return {
		"arena/bg": T.COR_ARENA_FUNDO,
		"arena/duelBg": T.COR_ARENA_DUELO_FUNDO,
		"app/bg início": T.COR_APP_FUNDO_INICIO,
		"app/bg fim": T.COR_APP_FUNDO_FIM,
		"surface/1": T.COR_SUPERFICIE_1,
		"surface/2": T.COR_SUPERFICIE_2,
		"vidro sobre app": T.compor_sobre(T.COR_SUPERFICIE_VIDRO, T.COR_APP_FUNDO_FIM),
		"vidro sobre surface/1": T.compor_sobre(T.COR_SUPERFICIE_VIDRO, T.COR_SUPERFICIE_1),
		"hud sobre arena": T.compor_sobre(T.COR_SUPERFICIE_HUD, T.COR_ARENA_FUNDO),
	}


func _assert_pares(textos: Dictionary, minimo: float) -> void:
	var fundos: Dictionary = _fundos_de_texto()
	for nome_texto: String in textos:
		for nome_fundo: String in fundos:
			var razao: float = T.razao_contraste(textos[nome_texto], fundos[nome_fundo])
			assert_float(razao).override_failure_message(
				"%s sobre %s: %.2f:1, abaixo do mínimo %.1f:1"
				% [nome_texto, nome_fundo, razao, minimo]
			).is_greater_equal(minimo)


func test_texto_normal_passa_aa_sobre_todos_os_fundos() -> void:
	_assert_pares({
		"text/primary": T.COR_TEXTO_PRIMARIO,
		"text/secondary": T.COR_TEXTO_SECUNDARIO,
		"semantic/success": T.COR_SUCESSO,
		"semantic/dangerText": T.COR_PERIGO_TEXTO,
		"semantic/warning": T.COR_ALERTA,
		"semantic/info": T.COR_INFO,
		"semantic/adOffer": T.COR_OFERTA_ANUNCIO,
		"rarity/comum": T.CORES_RARIDADE[T.Raridade.COMUM],
		"rarity/rara": T.CORES_RARIDADE[T.Raridade.RARA],
		"rarity/epica": T.CORES_RARIDADE[T.Raridade.EPICA],
		"rarity/lendaria": T.CORES_RARIDADE[T.Raridade.LENDARIA],
	}, T.CONTRASTE_MIN_TEXTO)


func test_texto_grande_e_elementos_graficos_passam_aa() -> void:
	_assert_pares({
		"text/muted (restrito a texto grande)": T.COR_TEXTO_MUTED,
		"semantic/dangerAction (borda/ícone)": T.COR_PERIGO_ACAO,
	}, T.CONTRASTE_MIN_GRAFICO)


func test_texto_sobre_ctas_passa_aa_em_toda_a_extensao_do_gradiente() -> void:
	var casos: Array = [
		["cta/primary", T.COR_TEXTO_SOBRE_PRIMARIO,
			[T.COR_CTA_PRIMARIO_INICIO, T.COR_CTA_PRIMARIO_MEDIO, T.COR_CTA_PRIMARIO_FIM]],
		["cta/ad", T.COR_TEXTO_SOBRE_OFERTA_ANUNCIO,
			[T.COR_CTA_ANUNCIO_INICIO, T.COR_CTA_ANUNCIO_MEDIO, T.COR_CTA_ANUNCIO_FIM]],
		["cta/vip", T.COR_TEXTO_SOBRE_ALERTA,
			[T.COR_CTA_VIP_INICIO, T.COR_CTA_VIP_MEDIO, T.COR_CTA_VIP_FIM]],
	]
	for caso: Array in casos:
		var nome: String = caso[0]
		var texto: Color = caso[1]
		for fundo: Color in caso[2]:
			assert_float(T.razao_contraste(texto, fundo)).override_failure_message(
				"texto de %s reprovado num dos pontos do gradiente" % nome
			).is_greater_equal(T.CONTRASTE_MIN_TEXTO)
		# O estado pressionado escurece o fundo — o texto escuro perde contraste
		# nesse instante, então o press também precisa passar.
		var press: Color = T.cor_press(caso[2][1])
		assert_float(T.razao_contraste(texto, press)).override_failure_message(
			"texto de %s reprovado no estado pressionado" % nome
		).is_greater_equal(T.CONTRASTE_MIN_TEXTO)


func test_cobras_contrastam_com_a_arena() -> void:
	for i: int in T.TOTAL_CORES_COBRA:
		var base: Color = T.CORES_COBRA_BASE[i]
		var escura: Color = T.CORES_COBRA_ESCURA[i]
		assert_float(T.razao_contraste(base, T.COR_ARENA_FUNDO)).override_failure_message(
			"cobra %d ilegível na arena normal" % i).is_greater_equal(T.CONTRASTE_MIN_GRAFICO)
		assert_float(T.razao_contraste(base, T.COR_ARENA_DUELO_FUNDO)).override_failure_message(
			"cobra %d ilegível na arena de duelo" % i).is_greater_equal(T.CONTRASTE_MIN_GRAFICO)
		assert_float(T.razao_contraste(escura, T.COR_ARENA_FUNDO)).override_failure_message(
			"tom escuro da cobra %d some na arena" % i).is_greater_equal(T.CONTRASTE_MIN_GRAFICO)


func test_comida_contrasta_com_a_arena() -> void:
	for comida: Color in [T.COR_COMIDA_COMUM, T.COR_COMIDA_COMUM_REALCE, T.COR_COMIDA_PREMIUM]:
		assert_float(T.razao_contraste(comida, T.COR_ARENA_FUNDO)) \
			.is_greater_equal(T.CONTRASTE_MIN_GRAFICO)


func test_simbolos_de_daltonismo_sao_unicos_e_completos() -> void:
	# As cobras se distinguem por matiz, não por luminância (rosa×roxa ≈ 1.03:1);
	# o símbolo é o canal redundante obrigatório — um por cor, sem repetição.
	assert_int(T.CORES_COBRA_BASE.size()).is_equal(T.TOTAL_CORES_COBRA)
	assert_int(T.CORES_COBRA_ESCURA.size()).is_equal(T.TOTAL_CORES_COBRA)
	assert_int(T.SIMBOLOS_COBRA.size()).is_equal(T.TOTAL_CORES_COBRA)
	assert_int(T.ARQUIVOS_SIMBOLO.size()).is_equal(T.TOTAL_CORES_COBRA)
	var vistos: Dictionary = {}
	for simbolo: int in T.SIMBOLOS_COBRA:
		vistos[simbolo] = true
	assert_int(vistos.size()).override_failure_message(
		"há símbolo repetido entre cobras").is_equal(T.TOTAL_CORES_COBRA)


func test_assets_de_simbolo_existem() -> void:
	for i: int in T.TOTAL_CORES_COBRA:
		var caminho: String = T.caminho_simbolo(T.SIMBOLOS_COBRA[i])
		assert_bool(FileAccess.file_exists(caminho)).override_failure_message(
			"asset de símbolo ausente: " + caminho).is_true()


func test_razao_contraste_bate_com_a_referencia_wcag() -> void:
	# Preto sobre branco é o máximo teórico da fórmula: 21:1.
	assert_float(T.razao_contraste(Color.BLACK, Color.WHITE)).is_equal_approx(21.0, 0.01)
	assert_float(T.razao_contraste(Color.WHITE, Color.WHITE)).is_equal_approx(1.0, 0.001)


func test_compor_sobre_casos_limite() -> void:
	var fundo: Color = T.COR_SUPERFICIE_1
	# Alpha 1 devolve a própria cor da frente; alpha 0 devolve o fundo.
	assert_float(T.compor_sobre(Color(1, 0, 0, 1), fundo).r).is_equal_approx(1.0, 0.0001)
	assert_float(T.compor_sobre(Color(1, 0, 0, 0), fundo).r).is_equal_approx(fundo.r, 0.0001)
