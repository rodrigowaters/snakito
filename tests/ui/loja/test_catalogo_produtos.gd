extends GdUnitTestSuite
## Catálogo de produtos do Play. O teste que importa é a SINCRONIA com o
## CATALOGO da Edge Function `validate_purchase`: id, tipo e o que concede
## precisam bater nos dois lados — o servidor recusa id desconhecido, e
## divergência de valor daria compra paga sem entrega.

const FUNCAO: String = "res://supabase/functions/validate_purchase/index.ts"


func before_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func after_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func test_ids_sao_validos_para_o_play() -> void:
	# O Play só aceita minúsculas, números e underscore.
	var regex: RegEx = RegEx.new()
	regex.compile("^[a-z0-9_]+$")
	for id: String in CatalogoProdutos.ids():
		assert_object(regex.search(id)).is_not_null()


func test_todo_produto_concede_alguma_coisa() -> void:
	for produto: Dictionary in CatalogoProdutos.PRODUTOS:
		var entrega: int = produto.entitlements.size() \
			+ int(produto.moedas) + int(produto.tickets)
		assert_int(entrega).is_greater(0)


func test_consumivel_nunca_da_entitlement() -> void:
	# Consumível é creditado no aparelho e consumido no Play; direito
	# perpétuo tem que ser NÃO consumível ou o jogador perderia a compra.
	for produto: Dictionary in CatalogoProdutos.PRODUTOS:
		if produto.tipo == CatalogoProdutos.Tipo.CONSUMIVEL:
			assert_int(produto.entitlements.size()).is_equal(0)


func test_catalogo_bate_com_a_edge_function() -> void:
	var arquivo: FileAccess = FileAccess.open(FUNCAO, FileAccess.READ)
	assert_object(arquivo).is_not_null()
	var fonte: String = arquivo.get_as_text()
	for produto: Dictionary in CatalogoProdutos.PRODUTOS:
		# O id existe no servidor…
		assert_str(fonte).contains("%s: {" % produto.id)
		# …e os valores concedidos também (o que o cliente credita).
		if int(produto.moedas) > 0:
			assert_str(fonte).contains("moedas: %d" % int(produto.moedas))
		if int(produto.tickets) > 0:
			assert_str(fonte).contains("tickets: %d" % int(produto.tickets))
		for chave: String in produto.entitlements:
			assert_str(fonte).contains('"%s"' % chave)


func test_pacotes_de_skin_nao_estao_vendaveis_ainda() -> void:
	# Trava honesta: sem render de padrão em jogo, vender pacote de skin
	# seria cobrar por algo que não veste. Cai quando o render existir.
	for pacote: Dictionary in Loja.PACOTES_SKINS:
		assert_bool(pacote.vendavel).is_false()
