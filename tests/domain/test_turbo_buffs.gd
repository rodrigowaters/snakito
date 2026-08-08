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


func test_composicao_limita_turbo_e_crescimento_dos_bots() -> void:
	# Eixos de composição do playtest de 08/08: turbo dos bots (nunca acima
	# do base do jogador) e teto de crescimento (contém a bola de neve).
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.fazendeiros = 1
	config.tamanho_min_bot = 4
	config.tamanho_max_bot = 4
	config.turbo_bots = 1.2
	config.tamanho_teto_bot = 5
	var motor: GameEngine = GameEngine.new(config)
	var bot: SnakeModel = motor.arena.cobra_por_id(1)
	assert_float(bot.multiplicador_turbo).is_equal_approx(1.2, 0.0001)
	# Bot no teto não cresce mais comendo (mas ainda pontua)...
	bot.tamanho = 5
	motor.arena.comidas.append(bot.posicao)
	motor.avancar(Vector2.ZERO)
	assert_int(bot.tamanho).is_equal(5)
	assert_int(bot.pontos).is_greater_equal(GameEngine.PONTOS_COMIDA)
	# ...e o JOGADOR nunca tem teto — a progressão dele é o jogo.
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 5
	motor.arena.comidas.append(jogador.posicao)
	motor.avancar(Vector2.ZERO)
	assert_int(jogador.tamanho).is_equal(6)


func test_turbo_dos_bots_nunca_passa_do_base_do_jogador() -> void:
	var config: GameEngine.ConfigPartida = _config_vazia()
	config.fazendeiros = 1
	config.turbo_bots = 9.9  # config maliciosa/errada → clamp no base
	var motor: GameEngine = GameEngine.new(config)
	assert_float(motor.arena.cobra_por_id(1).multiplicador_turbo) \
		.is_equal(SnakeModel.TURBO_BASE)


func test_desafio_2_recalibrado_contem_gigantes_e_sprint() -> void:
	# v3 do playtest: presas alcançáveis (turbo 1.3), sem gigantes (teto 12),
	# e ameaça VIVA (2 caçadores — a v2 com 1 deu fuga 0% no simulador).
	var config: GameEngine.ConfigPartida = ChallengeRules.config_do_desafio(
		ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	assert_float(config.turbo_bots).is_equal_approx(1.3, 0.0001)
	assert_int(config.tamanho_teto_bot).is_equal(12)
	assert_int(config.cacadores).is_equal(2)


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
