class_name TestSnakeModel
extends GdUnitTestSuite
## Propriedades derivadas da cobra: raio, visão e o limiar de devorar.


func _cobra(tamanho: int) -> SnakeModel:
	return SnakeModel.new(1, SnakeModel.Personalidade.FAZENDEIRO, Vector2.ZERO, tamanho)


func test_raio_cresce_com_o_tamanho() -> void:
	assert_float(_cobra(9).raio()).is_greater(_cobra(4).raio())
	assert_float(_cobra(4).raio()).is_greater(_cobra(1).raio())


func test_visao_cresce_com_o_tamanho_ate_o_teto() -> void:
	# Docs §2.2: quanto maior, maior o raio de visão.
	assert_float(_cobra(10).raio_visao()).is_greater(_cobra(1).raio_visao())
	# O teto mantém a névoa relevante para gigantes.
	assert_float(_cobra(1000).raio_visao()).is_equal(SnakeModel.VISAO_MAX)


func test_limiar_de_devorar_e_exatamente_10_por_cento() -> void:
	# Docs §2.3: "qualquer cobra 10% maior pode matá-lo em um toque".
	# O limiar EXATO conta (11 = 1.1 × 10) — daí a comparação em inteiros.
	assert_bool(_cobra(11).pode_devorar(_cobra(10))).is_true()
	assert_bool(_cobra(22).pode_devorar(_cobra(20))).is_true()
	# Abaixo do limiar, ninguém devora ninguém.
	assert_bool(_cobra(12).pode_devorar(_cobra(11))).is_false()
	assert_bool(_cobra(10).pode_devorar(_cobra(10))).is_false()
	assert_bool(_cobra(10).pode_devorar(_cobra(11))).is_false()


func test_crescer_acumula() -> void:
	var cobra: SnakeModel = _cobra(1)
	cobra.crescer(3)
	cobra.crescer(2)
	assert_int(cobra.tamanho).is_equal(6)


func test_identificacao_de_jogador() -> void:
	var jogador: SnakeModel = SnakeModel.new(0, SnakeModel.Personalidade.JOGADOR, Vector2.ZERO)
	assert_bool(jogador.eh_jogador()).is_true()
	assert_bool(_cobra(1).eh_jogador()).is_false()


func test_estado_inicial() -> void:
	var cobra: SnakeModel = _cobra(1)
	assert_bool(cobra.viva).is_true()
	assert_int(cobra.pontos).is_equal(0)
	assert_int(cobra.abates).is_equal(0)
	assert_int(cobra.comidas).is_equal(0)
