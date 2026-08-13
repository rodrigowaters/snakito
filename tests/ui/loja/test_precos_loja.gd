extends GdUnitTestSuite
## Preços da Loja de buffs — trava a spec §2.6.2 (`200 × growth^N`).
## A âncora vem do próprio design: Velocidade Nv 2 = 298 moedas.


func before_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func after_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


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


func test_catalogo_completo_de_skins() -> void:
	# Catálogo do design (13/08): 4 comuns grátis + 2 raras sólidas + 9
	# épicas (6 avulsas + 3 do Pacote Neon) + 2 lendárias = 17.
	assert_int(CatalogoSkins.SKINS.size()).is_equal(17)
	var comuns: Array[Dictionary] = CatalogoSkins.da_raridade(SnakitoTokens.Raridade.COMUM)
	assert_int(comuns.size()).is_equal(4)
	for skin: Dictionary in comuns:
		assert_int(skin.preco).is_equal(0)  # skins do M1 são grátis
	# Raras são sólidas da paleta: equipáveis pelo render de HOJE.
	for skin: Dictionary in CatalogoSkins.da_raridade(SnakitoTokens.Raridade.RARA):
		assert_bool(skin.indice >= 0).is_true()
		assert_int(skin.preco).is_equal(400)
	assert_int(CatalogoSkins.da_raridade(SnakitoTokens.Raridade.EPICA).size()).is_equal(9)
	assert_int(CatalogoSkins.da_raridade(SnakitoTokens.Raridade.LENDARIA).size()).is_equal(2)


func test_compra_de_skin_rara_desbloqueia() -> void:
	var laranjinha: Dictionary = CatalogoSkins.da_raridade(SnakitoTokens.Raridade.RARA)[0]
	assert_bool(CatalogoSkins.desbloqueada(laranjinha)).is_false()
	ProgressoLocal.adicionar_moedas(400)
	assert_bool(ProgressoLocal.gastar_moedas(int(laranjinha.preco))).is_true()
	ProgressoLocal.marcar_skin_comprada(laranjinha.id)
	assert_bool(CatalogoSkins.desbloqueada(laranjinha)).is_true()
	assert_int(CatalogoSkins.total_desbloqueadas()).is_equal(5)  # 4 grátis + 1
