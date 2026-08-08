class_name TestTurboBuffs
extends GdUnitTestSuite
## Turbo & Buffs (docs §2.6): energia, histerese, velocidade, ímã, buffs por
## nível com teto, integridade dos desafios e turbo honesto dos bots.


func _config_vazia() -> GameEngine.ConfigPartida:
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.fazendeiros = 0
	config.cacadores = 0
	config.oportunistas = 0
	config.qtd_comida = 0
	return config


# ---------------------------------------------------------------------- turbo


func test_turbo_multiplica_a_velocidade() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	var x0: float = jogador.posicao.x
	motor.avancar(Vector2.RIGHT, false)
	assert_float(jogador.posicao.x - x0).is_equal_approx(
		GameEngine.VELOCIDADE * GameEngine.DELTA, 0.0001)  # 3.0
	x0 = jogador.posicao.x
	motor.avancar(Vector2.RIGHT, true)
	assert_float(jogador.posicao.x - x0).is_equal_approx(
		GameEngine.VELOCIDADE * SnakeModel.TURBO_BASE * GameEngine.DELTA, 0.0001)  # 4.5


func test_turbo_consome_e_regenera_energia() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	for t: int in 60:
		motor.avancar(Vector2.RIGHT, true)
	# 1s de turbo: 100 - 40 = 60.
	assert_float(jogador.energia).is_equal_approx(60.0, 0.01)
	for t: int in 60:
		motor.avancar(Vector2.RIGHT, false)
	# 1s solto: 60 + 16 = 76.
	assert_float(jogador.energia).is_equal_approx(76.0, 0.01)


func test_turbo_desliga_em_zero_e_exige_minimo_para_voltar() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	# 100 / (40/60) = 150 ticks até zerar.
	for t: int in 150:
		motor.avancar(Vector2.RIGHT, true)
	assert_float(jogador.energia).is_equal_approx(0.0, 0.01)
	assert_bool(jogador.turbo_ativo).is_false()
	# Segurando o botão com pouca energia: regenera, mas NÃO reativa (< 10).
	for t: int in 10:
		motor.avancar(Vector2.RIGHT, true)
	assert_bool(jogador.turbo_ativo).is_false()
	assert_float(jogador.energia).is_greater(0.0)
	# Continua segurando até cruzar o limiar de 10 → reativa (histerese).
	for t: int in 40:
		motor.avancar(Vector2.RIGHT, true)
	assert_bool(jogador.turbo_ativo).is_true()


func test_energia_nao_passa_do_maximo() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	for t: int in 120:
		motor.avancar(Vector2.RIGHT, false)
	assert_float(motor.jogador().energia).is_equal(SnakeModel.ENERGIA_MAX)


# ---------------------------------------------------------------------- buffs


func test_buff_de_velocidade_aplica_por_nivel_com_teto() -> void:
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.nivel_velocidade = 4
	assert_float(GameEngine.new(config).jogador().multiplicador_turbo) \
		.is_equal_approx(1.7, 0.0001)
	config.nivel_velocidade = 15  # acima do teto → clamp no Nv 10
	assert_float(GameEngine.new(config).jogador().multiplicador_turbo) \
		.is_equal_approx(2.0, 0.0001)


func test_buff_de_ima_aplica_por_nivel_com_teto() -> void:
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.nivel_ima = 1
	assert_float(GameEngine.new(config).jogador().raio_ima).is_equal(40.0)
	config.nivel_ima = 10
	assert_float(GameEngine.new(config).jogador().raio_ima).is_equal(175.0)
	config.nivel_ima = 0
	assert_float(GameEngine.new(config).jogador().raio_ima).is_equal(0.0)


func test_buff_de_pontos_iniciais() -> void:
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.nivel_pontos_iniciais = 10
	assert_int(GameEngine.new(config).jogador().pontos).is_equal(50)


func test_desafio_ignora_todos_os_buffs() -> void:
	# Docs §2.6.3: partida por seed tem que ser comparável.
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.nivel_velocidade = 10
	config.nivel_ima = 10
	config.nivel_pontos_iniciais = 10
	config.aplicar_buffs = false
	var jogador: SnakeModel = GameEngine.new(config).jogador()
	assert_float(jogador.multiplicador_turbo).is_equal(SnakeModel.TURBO_BASE)
	assert_float(jogador.raio_ima).is_equal(0.0)
	assert_int(jogador.pontos).is_equal(0)


# ------------------------------------------------------------------------ ímã


func test_ima_atrai_comida_dentro_do_raio() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	jogador.raio_ima = 100.0
	var origem: Vector2 = jogador.posicao + Vector2(90.0, 0.0)
	motor.arena.comidas.append(origem)
	motor.avancar(Vector2.UP)  # jogador sobe; comida deve derivar até ele
	var apos: Vector2 = motor.arena.comidas[0]
	assert_float(apos.distance_to(jogador.posicao)) \
		.is_less(origem.distance_to(jogador.posicao))
	# Deriva à taxa do ímã: 120/60 = 2 unidades por tick.
	assert_float(origem.distance_to(apos)) \
		.is_equal_approx(GameEngine.IMA_VELOCIDADE * GameEngine.DELTA, 0.0001)


func test_ima_nao_atrai_comida_fora_do_raio() -> void:
	var motor: GameEngine = GameEngine.new(_config_vazia())
	var jogador: SnakeModel = motor.jogador()
	jogador.raio_ima = 100.0
	var origem: Vector2 = jogador.posicao + Vector2(150.0, 0.0)
	motor.arena.comidas.append(origem)
	motor.avancar(Vector2.UP)
	assert_vector(motor.arena.comidas[0]).is_equal(origem)


# ------------------------------------------------------------ bots honestos


func test_bots_ligam_turbo_para_fugir_e_cacar_mas_nao_para_farmar() -> void:
	var motor_bots: BotEngine = BotEngine.new()
	var arena: ArenaModel = ArenaModel.new(Vector2(2400.0, 2400.0))
	var centro: Vector2 = Vector2(1200.0, 1200.0)

	# Fazendeiro ameaçado → foge COM turbo.
	var fazendeiro: SnakeModel = SnakeModel.new(1, SnakeModel.Personalidade.FAZENDEIRO, centro, 3)
	var ameaca: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.CACADOR, centro + Vector2(100.0, 0.0), 10)
	arena.adicionar_cobra(fazendeiro)
	arena.adicionar_cobra(ameaca)
	motor_bots.decidir(fazendeiro, arena, RngService.new(1))
	assert_bool(fazendeiro.quer_turbo).is_true()

	# Caçador com presa → persegue COM turbo.
	var arena2: ArenaModel = ArenaModel.new(Vector2(2400.0, 2400.0))
	var cacador: SnakeModel = SnakeModel.new(1, SnakeModel.Personalidade.CACADOR, centro, 22)
	var presa: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, centro + Vector2(150.0, 0.0), 10)
	arena2.adicionar_cobra(cacador)
	arena2.adicionar_cobra(presa)
	motor_bots.decidir(cacador, arena2, RngService.new(1))
	assert_bool(cacador.quer_turbo).is_true()

	# Fazendeiro só farmando → SEM turbo (não desperdiça energia).
	var arena3: ArenaModel = ArenaModel.new(Vector2(2400.0, 2400.0))
	var pacato: SnakeModel = SnakeModel.new(1, SnakeModel.Personalidade.FAZENDEIRO, centro, 3)
	arena3.adicionar_cobra(pacato)
	arena3.comidas.append(centro + Vector2(100.0, 0.0))
	motor_bots.decidir(pacato, arena3, RngService.new(1))
	assert_bool(pacato.quer_turbo).is_false()


func test_turbo_da_vantagem_de_caca_sobre_presa_sem_energia() -> void:
	# A razão de existir do turbo: sem ele, perseguição em linha reta nunca
	# alcança (velocidades iguais). Presa sem energia + caçador com turbo
	# fecha a distância; sem turbo, a distância congela e a presa vive.
	for com_turbo: bool in [true, false]:
		var motor: GameEngine = GameEngine.new(_config_vazia())
		var jogador: SnakeModel = motor.jogador()
		jogador.tamanho = 12
		var presa: SnakeModel = SnakeModel.new(
			5, SnakeModel.Personalidade.FAZENDEIRO,
			jogador.posicao + Vector2(60.0, 0.0), 1)
		presa.energia = 0.0  # esgotada — não consegue reagir com turbo
		motor.arena.adicionar_cobra(presa)
		for t: int in 30:
			motor.avancar(Vector2.RIGHT, com_turbo)
		if com_turbo:
			assert_bool(presa.viva).override_failure_message(
				"caçador COM turbo deveria alcançar presa esgotada").is_false()
		else:
			assert_bool(presa.viva).override_failure_message(
				"sem turbo a distância congela — presa deveria escapar").is_true()
