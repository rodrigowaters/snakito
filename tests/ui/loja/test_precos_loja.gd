extends GdUnitTestSuite
## Preços da Loja de buffs — trava a spec §2.6.2 (`200 × growth^N`).
## A âncora vem do próprio design: Velocidade Nv 2 = 298 moedas.


func test_preco_ancora_do_design() -> void:
	assert_int(PrecosLoja.preco_buff(1.22, 2)).is_equal(298)


func test_precos_nivel_1() -> void:
	assert_int(PrecosLoja.preco_buff(1.22, 1)).is_equal(244)  # velocidade
	assert_int(PrecosLoja.preco_buff(1.42, 1)).is_equal(284)  # ímã
	assert_int(PrecosLoja.preco_buff(1.13, 1)).is_equal(226)  # pontos


func test_chaves_dos_buffs_casam_com_a_config_do_motor() -> void:
	# A Sessao lê nivel_<chave> da ConfigPartida — renomear quebra a ponte.
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.padrao(1)
	var esperadas: Array[String] = ["velocidade", "ima", "pontos"]
	var chaves: Array[String] = []
	for buff: Dictionary in PrecosLoja.BUFFS:
		chaves.append(buff.chave)
	assert_array(chaves).is_equal(esperadas)
	assert_bool("nivel_velocidade" in config).is_true()
	assert_bool("nivel_ima" in config).is_true()


func test_catalogo_de_skins_do_m1() -> void:
	var comuns: Array[Dictionary] = CatalogoSkins.da_raridade(SnakitoTokens.Raridade.COMUM)
	assert_int(comuns.size()).is_equal(4)
	for skin: Dictionary in comuns:
		assert_int(skin.preco).is_equal(0)  # skins do M1 são grátis
	assert_int(CatalogoSkins.da_raridade(SnakitoTokens.Raridade.LENDARIA).size()).is_equal(0)
