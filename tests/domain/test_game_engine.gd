class_name TestGameEngine
extends GdUnitTestSuite
## Motor da partida: determinismo, crescimento, morte, pontuação, knockback,
## bordas e fim de jogo — a cobertura exigida pela regra dura #8.


## Config vazia (sem bots, sem comida) para cenários montados à mão.
func _config_vazia(semente: int = 1) -> GameEngine.ConfigPartida:
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.semente = semente
	config.fazendeiros = 0
	config.cacadores = 0
	config.oportunistas = 0
	config.qtd_comida = 0
	return config


func _instantanea(engine: GameEngine) -> String:
	var partes: PackedStringArray = PackedStringArray()
	for cobra: SnakeModel in engine.arena.cobras:
		partes.append("%d|%.5f|%.5f|%d|%d|%s" % [
			cobra.id, cobra.posicao.x, cobra.posicao.y,
			cobra.tamanho, cobra.pontos, cobra.viva,
		])
	partes.append(str(engine.arena.comidas))
	return "\n".join(partes)


# ---------------------------------------------------------------- determinismo


func test_mesma_seed_e_inputs_produzem_partidas_identicas() -> void:
	# Arena completa do spike (30 bots, 80 comidas), 300 ticks = 5s de jogo.
	var motores: Array[GameEngine] = [
		GameEngine.new(GameEngine.ConfigPartida.padrao(123)),
		GameEngine.new(GameEngine.ConfigPartida.padrao(123)),
	]
	for motor: GameEngine in motores:
		for t: int in 300:
			# Input do jogador como função determinística do tick.
			motor.avancar(Vector2.RIGHT.rotated(float(t) * 0.02))
	assert_str(_instantanea(motores[0])).is_equal(_instantanea(motores[1]))


func test_seeds_diferentes_geram_arenas_diferentes() -> void:
	var a: GameEngine = GameEngine.new(GameEngine.ConfigPartida.padrao(1))
	var b: GameEngine = GameEngine.new(GameEngine.ConfigPartida.padrao(2))
	assert_str(_instantanea(a)).is_not_equal(_instantanea(b))


func test_composicao_da_arena_segue_a_config() -> void:
	var motor: GameEngine = GameEngine.new(GameEngine.ConfigPartida.padrao(9))
	var contagem: Dictionary[SnakeModel.Personalidade, int] = {}
	for cobra: SnakeModel in motor.arena.cobras:
		contagem[cobra.personalidade] = contagem.get(cobra.personalidade, 0) + 1
	assert_int(contagem[SnakeModel.Personalidade.JOGADOR]).is_equal(1)
	assert_int(contagem[SnakeModel.Personalidade.FAZENDEIRO]).is_equal(12)
	assert_int(contagem[SnakeModel.Personalidade.CACADOR]).is_equal(6)
	assert_int(contagem[SnakeModel.Personalidade.OPORTUNISTA]).is_equal(12)
	assert_int(motor.arena.comidas.size()).is_equal(110)
	for cobra: SnakeModel in motor.arena.cobras:
		assert_bool(motor.arena.limites().has_point(cobra.posicao)).is_true()
		if not cobra.eh_jogador():
			assert_int(cobra.tamanho).is_between(1, 5)
			# Ninguém nasce colado no jogador (spawn seguro).
			assert_float(cobra.posicao.distance_to(motor.jogador().posicao)) \
				.is_greater_equal(GameEngine.DISTANCIA_SPAWN_MIN)


# ------------------------------------------------------- crescimento & comida


func test_comer_da_tamanho_e_pontos() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	motor.arena.comidas.append(jogador.posicao + Vector2(10.0, 0.0))
	motor.avancar(Vector2.ZERO)
	assert_int(jogador.tamanho).is_equal(1 + GameEngine.CRESCIMENTO_COMIDA)
	assert_int(jogador.pontos).is_equal(GameEngine.PONTOS_COMIDA)
	assert_int(jogador.comidas).is_equal(1)
	assert_int(motor.arena.comidas.size()).is_equal(0)  # alvo da config é 0


func test_comida_comida_e_reposta_ate_o_alvo() -> void:
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.qtd_comida = 5
	var motor: GameEngine = GameEngine.new(config)
	assert_int(motor.arena.comidas.size()).is_equal(5)
	motor.arena.comer_comida(0)
	motor.avancar(Vector2.ZERO)
	assert_int(motor.arena.comidas.size()).is_equal(5)


# ------------------------------------------------------------- morte & abate


func test_devorar_no_limiar_exato_de_10_por_cento() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 11
	jogador.nivel = 11
	var vitima: SnakeModel = SnakeModel.new(
		5, SnakeModel.Personalidade.FAZENDEIRO, jogador.posicao + Vector2(5.0, 0.0), 10)
	motor.arena.adicionar_cobra(vitima)
	motor.avancar(Vector2.ZERO)
	assert_bool(vitima.viva).is_false()
	assert_bool(jogador.viva).is_true()
	assert_int(jogador.abates).is_equal(1)
	assert_int(jogador.pontos).is_equal(GameEngine.pontos_por_abate(10))
	# Crescimento proporcional: metade do tamanho da vítima.
	assert_int(jogador.tamanho).is_equal(11 + 5)
	assert_that(motor.estado).is_equal(GameEngine.Estado.EM_ANDAMENTO)


func test_diferenca_menor_que_10_por_cento_vira_knockback() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 12
	jogador.nivel = 12
	var outra: SnakeModel = SnakeModel.new(
		5, SnakeModel.Personalidade.FAZENDEIRO, jogador.posicao + Vector2(5.0, 0.0), 11)
	motor.arena.adicionar_cobra(outra)
	motor.avancar(Vector2.ZERO)
	assert_bool(jogador.viva).is_true()
	assert_bool(outra.viva).is_true()
	# Empurradas para fora da sobreposição: distância ≈ soma dos raios.
	var dist: float = jogador.posicao.distance_to(outra.posicao)
	assert_float(dist).is_greater_equal(jogador.raio() + outra.raio() - 0.01)


func test_morte_do_jogador_encerra_a_partida() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	var predadora: SnakeModel = SnakeModel.new(
		5, SnakeModel.Personalidade.CACADOR, jogador.posicao + Vector2(5.0, 0.0), 20)
	motor.arena.adicionar_cobra(predadora)
	motor.avancar(Vector2.ZERO)
	assert_bool(jogador.viva).is_false()
	assert_that(motor.estado).is_equal(GameEngine.Estado.ENCERRADA)
	# A vítima mantém os pontos que fez (docs §2.3) — aqui, zero.
	assert_int(predadora.abates).is_equal(1)


func test_curva_de_pontos_por_abate() -> void:
	# 100·√tamanho, clamp 100–500 (docs §2.2: 100–500, não-linear).
	assert_int(GameEngine.pontos_por_abate(1)).is_equal(100)
	assert_int(GameEngine.pontos_por_abate(4)).is_equal(200)
	assert_int(GameEngine.pontos_por_abate(9)).is_equal(300)
	assert_int(GameEngine.pontos_por_abate(25)).is_equal(500)
	assert_int(GameEngine.pontos_por_abate(100)).is_equal(500)  # teto


# ------------------------------------------------- tempo, borda e ranking


func test_sobrevivencia_pontua_por_segundo() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	for t: int in 119:
		motor.avancar(Vector2.ZERO)
	assert_int(motor.jogador().pontos).is_equal(1)  # só 1 segundo completo
	motor.avancar(Vector2.ZERO)
	assert_int(motor.jogador().pontos).is_equal(2)
	assert_int(motor.jogador().ticks_vividos).is_equal(120)


func test_partida_termina_no_tempo_limite() -> void:
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.duracao_seg = 1
	var motor: GameEngine = GameEngine.new(config)
	for t: int in 60:
		motor.avancar(Vector2.ZERO)
	assert_that(motor.estado).is_equal(GameEngine.Estado.ENCERRADA)
	# Depois de encerrada, avancar() é inerte.
	motor.avancar(Vector2.RIGHT)
	assert_int(motor.tick_atual).is_equal(60)


func test_borda_desliza_sem_matar() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	jogador.posicao = Vector2(20.0, motor.arena.tamanho.y * 0.5)
	for t: int in 30:
		motor.avancar(Vector2.LEFT)
	assert_bool(jogador.viva).is_true()
	assert_float(jogador.posicao.x).is_equal_approx(jogador.raio(), 0.001)


func test_ranking_por_pontos_com_desempate_estavel() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	jogador.pontos = 10
	var lider: SnakeModel = SnakeModel.new(5, SnakeModel.Personalidade.CACADOR, Vector2(100.0, 100.0), 3)
	lider.pontos = 50
	var empatada: SnakeModel = SnakeModel.new(7, SnakeModel.Personalidade.FAZENDEIRO, Vector2(200.0, 200.0), 3)
	empatada.pontos = 10
	motor.arena.adicionar_cobra(lider)
	motor.arena.adicionar_cobra(empatada)
	assert_int(motor.posicao_no_ranking(lider)).is_equal(1)
	assert_int(motor.posicao_no_ranking(jogador)).is_equal(2)  # empate: id menor
	assert_int(motor.posicao_no_ranking(empatada)).is_equal(3)


func test_seed_fica_visivel_para_repetir_a_arena() -> void:
	var motor: GameEngine = GameEngine.new(GameEngine.ConfigPartida.padrao(4242))
	assert_int(motor.rng.semente).is_equal(4242)
