class_name TestStrategyAnalyzer
extends GdUnitTestSuite
## Análise pós-partida v1: cada heurística tem um cenário que a dispara.


func _motor_vazio() -> GameEngine:
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.fazendeiros = 0
	config.cacadores = 0
	config.oportunistas = 0
	config.qtd_comida = 0
	return GameEngine.new(config)


func _regras_resolvidas(
	desafio: ChallengeRules.Desafio,
	motor: GameEngine,
) -> ChallengeRules:
	var regras: ChallengeRules = ChallengeRules.new(desafio)
	regras.avaliar(motor)
	return regras


func test_meta_atingida_elogia() -> void:
	var motor: GameEngine = _motor_vazio()
	motor.jogador().pontos = 50
	var regras: ChallengeRules = _regras_resolvidas(ChallengeRules.Desafio.FARMING_PURO, motor)
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor, regras)
	assert_array(achados).contains([StrategyAnalyzer.Achado.BOM_DESEMPENHO])


func test_matar_no_farming_puro_aponta_a_restricao() -> void:
	var motor: GameEngine = _motor_vazio()
	motor.jogador().abates = 1
	var regras: ChallengeRules = _regras_resolvidas(ChallengeRules.Desafio.FARMING_PURO, motor)
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor, regras)
	assert_array(achados).contains([StrategyAnalyzer.Achado.DESAFIO_PROIBIA_MATAR])


func test_morte_de_tanque_vazio_ensina_energia() -> void:
	var motor: GameEngine = _motor_vazio()
	var jogador: SnakeModel = motor.jogador()
	jogador.viva = false
	jogador.energia = 0.0
	jogador.ticks_vividos = 90 * 60  # não foi morte precoce
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor)
	assert_array(achados).contains([StrategyAnalyzer.Achado.GERENCIE_ENERGIA])
	assert_array(achados).not_contains([StrategyAnalyzer.Achado.FUJA_DOS_MAIORES])


func test_morte_precoce_ensina_fuga() -> void:
	var motor: GameEngine = _motor_vazio()
	var jogador: SnakeModel = motor.jogador()
	jogador.viva = false
	jogador.energia = 80.0  # não foi por energia
	jogador.ticks_vividos = 10 * 60
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor)
	assert_array(achados).contains([StrategyAnalyzer.Achado.FUJA_DOS_MAIORES])
	assert_array(achados).not_contains([StrategyAnalyzer.Achado.GERENCIE_ENERGIA])


func test_morrer_pequeno_cacando_ensina_a_crescer() -> void:
	var motor: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA))
	var jogador: SnakeModel = motor.jogador()
	jogador.viva = false
	jogador.energia = 80.0
	jogador.tamanho = 2
	jogador.ticks_vividos = 60 * 60
	var regras: ChallengeRules = _regras_resolvidas(ChallengeRules.Desafio.AGRESSAO_CONTROLADA, motor)
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor, regras)
	assert_array(achados).contains([StrategyAnalyzer.Achado.CRESCA_ANTES_DE_CACAR])


func test_tempo_esgotado_sugere_por_desafio() -> void:
	for caso: Array in [
		[ChallengeRules.Desafio.FARMING_PURO, StrategyAnalyzer.Achado.COLETE_MAIS_RAPIDO],
		[ChallengeRules.Desafio.AGRESSAO_CONTROLADA, StrategyAnalyzer.Achado.CACE_PRESAS_CANSADAS],
	]:
		var motor: GameEngine = GameEngine.new(ChallengeRules.config_do_desafio(caso[0]))
		motor.tick_atual = motor.config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO - 1
		motor.avancar(Vector2.ZERO)
		var regras: ChallengeRules = _regras_resolvidas(caso[0], motor)
		assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.TEMPO_ESGOTADO)
		var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor, regras)
		assert_array(achados).contains([caso[1]])


func test_arcade_no_top_3_elogia() -> void:
	var motor: GameEngine = _motor_vazio()
	motor.jogador().pontos = 100  # único na arena vazia → 1º
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor)
	assert_array(achados).contains([StrategyAnalyzer.Achado.BOM_DESEMPENHO])


func test_limite_de_dois_achados() -> void:
	# Morte precoce + tanque vazio + pequeno caçando = 3 gatilhos → só 2 saem.
	var motor: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA))
	var jogador: SnakeModel = motor.jogador()
	jogador.viva = false
	jogador.energia = 0.0
	jogador.tamanho = 2
	jogador.ticks_vividos = 5 * 60
	var regras: ChallengeRules = _regras_resolvidas(ChallengeRules.Desafio.AGRESSAO_CONTROLADA, motor)
	var achados: Array[StrategyAnalyzer.Achado] = StrategyAnalyzer.analisar(motor, regras)
	assert_int(achados.size()).is_equal(StrategyAnalyzer.MAX_ACHADOS)
	# E a prioridade segue a ordem do enum: energia vem antes de fuga.
	assert_that(achados[0]).is_equal(StrategyAnalyzer.Achado.GERENCIE_ENERGIA)
