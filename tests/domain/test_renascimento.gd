class_name TestRenascimento
extends GdUnitTestSuite
## Renascer (docs §5 / tokens `revive`): segunda chance por anúncio ou
## ticket. Mantém os pontos (spec) e cobra no NÍVEL (interpretação nossa).


## Motor com um bot, para haver de quem se afastar no spawn.
func _motor() -> GameEngine:
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.semente = 7
	config.tamanho_arena = Vector2(3000.0, 3000.0)
	config.qtd_comida = 0
	config.fazendeiros = 1
	config.cacadores = 0
	config.oportunistas = 0
	config.aplicar_buffs = false
	config.vitoria_por_dominio = false  # matar o bot não deve encerrar
	return GameEngine.new(config)


func test_morte_da_direito_a_renascer() -> void:
	var motor: GameEngine = _motor()
	assert_bool(motor.pode_renascer()).is_false()  # vivo: nada a renascer
	motor.jogador().viva = false
	assert_bool(motor.pode_renascer()).is_true()


func test_renascer_mantem_pontos_e_cobra_o_nivel() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.pontos = 4200
	jogador.nivel = 40
	jogador.tamanho = 30
	jogador.viva = false
	motor.avancar(Vector2.ZERO)  # a morte encerra a partida
	assert_int(int(motor.estado)).is_equal(int(GameEngine.Estado.ENCERRADA))

	assert_bool(motor.renascer_jogador()).is_true()
	assert_int(jogador.pontos).is_equal(4200)      # pontos ficam (spec)
	assert_int(jogador.nivel).is_equal(20)         # metade do nível
	assert_int(jogador.tamanho).is_equal(15)
	assert_bool(jogador.viva).is_true()
	assert_int(jogador.corpo.size()).is_equal(0)   # corpo antigo virou comida
	assert_float(jogador.energia).is_equal_approx(SnakeModel.ENERGIA_MAX, 0.01)
	assert_int(int(motor.estado)).is_equal(int(GameEngine.Estado.EM_ANDAMENTO))


func test_uma_chance_por_partida() -> void:
	var motor: GameEngine = _motor()
	motor.jogador().viva = false
	assert_bool(motor.renascer_jogador()).is_true()
	motor.jogador().viva = false
	assert_bool(motor.pode_renascer()).is_false()
	assert_bool(motor.renascer_jogador()).is_false()


func test_nivel_minimo_e_um() -> void:
	var motor: GameEngine = _motor()
	motor.jogador().nivel = 1
	motor.jogador().tamanho = 1
	motor.jogador().viva = false
	assert_bool(motor.renascer_jogador()).is_true()
	assert_int(motor.jogador().nivel).is_equal(1)
	assert_int(motor.jogador().tamanho).is_equal(1)


func test_fim_por_tempo_nao_da_renascimento() -> void:
	# Tempo esgotado é fim legítimo — renascer só resgata de MORTE.
	var motor: GameEngine = _motor()
	motor.tick_atual = motor.config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO
	motor.jogador().viva = false
	assert_bool(motor.pode_renascer()).is_false()


func test_renasce_longe_das_outras_cobras() -> void:
	var motor: GameEngine = _motor()
	var bot: SnakeModel = motor.arena.cobras[1]
	motor.jogador().viva = false
	assert_bool(motor.renascer_jogador()).is_true()
	assert_float(motor.jogador().posicao.distance_to(bot.posicao)) \
		.is_greater_equal(GameEngine.DISTANCIA_SPAWN_MIN)


func test_renascer_e_deterministico() -> void:
	var a: GameEngine = _motor()
	var b: GameEngine = _motor()
	for motor: GameEngine in [a, b]:
		motor.jogador().viva = false
		motor.renascer_jogador()
	assert_vector(a.jogador().posicao).is_equal(b.jogador().posicao)


func test_protecao_ao_renascer() -> void:
	var motor: GameEngine = _motor()
	motor.jogador().viva = false
	motor.renascer_jogador()
	assert_int(motor.jogador().protegida_de_corte_ate) \
		.is_equal(motor.tick_atual + GameEngine.PROTECAO_RENASCER_TICKS)
