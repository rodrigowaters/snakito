class_name TestArenaModel
extends GdUnitTestSuite
## Estado do mapa: comida, cobras e a consulta honesta por alcance.


func _arena() -> ArenaModel:
	return ArenaModel.new(Vector2(1000.0, 1000.0))


func test_repor_comida_atinge_o_alvo_dentro_dos_limites() -> void:
	var arena: ArenaModel = _arena()
	var rng: RngService = RngService.new(5)
	arena.repor_comida(30, rng)
	assert_int(arena.comidas.size()).is_equal(30)
	var area_valida: Rect2 = arena.limites().grow(-ArenaModel.MARGEM_SPAWN_COMIDA)
	for posicao: Vector2 in arena.comidas:
		assert_bool(area_valida.has_point(posicao)).is_true()


func test_comer_comida_remove_o_item() -> void:
	var arena: ArenaModel = _arena()
	arena.repor_comida(3, RngService.new(5))
	arena.comer_comida(1)
	assert_int(arena.comidas.size()).is_equal(2)


func test_comida_mais_proxima_escolhe_a_mais_perto() -> void:
	var arena: ArenaModel = _arena()
	arena.comidas.append(Vector2(500.0, 500.0))
	arena.comidas.append(Vector2(450.0, 500.0))  # a 50 da origem da busca
	arena.comidas.append(Vector2(300.0, 300.0))
	assert_int(arena.comida_mais_proxima(Vector2(400.0, 500.0), 1000.0)).is_equal(1)


func test_comida_fora_do_alcance_nao_e_vista() -> void:
	# É esta consulta que garante bots honestos: alcance = raio de visão.
	var arena: ArenaModel = _arena()
	arena.comidas.append(Vector2(900.0, 900.0))
	assert_int(arena.comida_mais_proxima(Vector2(100.0, 100.0), 200.0)).is_equal(-1)


func test_cobra_por_id_e_vivas() -> void:
	var arena: ArenaModel = _arena()
	var a: SnakeModel = SnakeModel.new(0, SnakeModel.Personalidade.JOGADOR, Vector2.ZERO)
	var b: SnakeModel = SnakeModel.new(1, SnakeModel.Personalidade.CACADOR, Vector2.ZERO)
	arena.adicionar_cobra(a)
	arena.adicionar_cobra(b)
	b.viva = false
	assert_object(arena.cobra_por_id(1)).is_same(b)
	assert_object(arena.cobra_por_id(99)).is_null()
	assert_int(arena.cobras_vivas().size()).is_equal(1)
	assert_object(arena.cobras_vivas()[0]).is_same(a)
