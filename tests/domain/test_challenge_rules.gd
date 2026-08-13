class_name TestChallengeRules
extends GdUnitTestSuite
## Desafios 1 e 2 (docs §2.5): configs reproduzíveis e sem buffs, metas,
## restrições, prioridades de motivo e a trava do estado resolvido.


func _motor_do_desafio(desafio: ChallengeRules.Desafio) -> GameEngine:
	return GameEngine.new(ChallengeRules.config_do_desafio(desafio))


# --------------------------------------------------------------------- configs


func test_config_do_desafio_1_seed_fixa_sem_buffs_sem_cacadores() -> void:
	var config: GameEngine.ConfigPartida = ChallengeRules.config_do_desafio(
		ChallengeRules.Desafio.FARMING_PURO)
	assert_int(config.semente).is_equal(ChallengeRules.SEED_DESAFIO_1)
	assert_int(config.duracao_seg).is_equal(60)
	assert_bool(config.aplicar_buffs).is_false()
	# Farming puro: a lição é colher, não fugir — zero caçadores.
	assert_int(config.cacadores).is_equal(0)


func test_config_do_desafio_2_seed_fixa_sem_buffs() -> void:
	var config: GameEngine.ConfigPartida = ChallengeRules.config_do_desafio(
		ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	assert_int(config.semente).is_equal(ChallengeRules.SEED_DESAFIO_2)
	assert_int(config.duracao_seg).is_equal(120)
	assert_bool(config.aplicar_buffs).is_false()
	# Precisa haver presa viável para quem cresce pouco.
	assert_int(config.tamanho_min_bot).is_equal(1)


func test_desafio_gera_exatamente_a_mesma_partida() -> void:
	# Docs §2.4/§1: mesma seed fixa → mesma partida, tick a tick.
	var a: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var b: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	for t: int in 120:
		var direcao: Vector2 = Vector2.RIGHT.rotated(float(t) * 0.03)
		a.avancar(direcao, t % 20 < 10)
		b.avancar(direcao, t % 20 < 10)
	for i: int in a.arena.cobras.size():
		assert_vector(a.arena.cobras[i].posicao).is_equal(b.arena.cobras[i].posicao)
	assert_str(str(a.arena.comidas)).is_equal(str(b.arena.comidas))


# ------------------------------------------------------------------- desafio 1


func test_desafio_1_conclui_ao_atingir_a_meta_de_pontos() -> void:
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	motor.jogador().pontos = ChallengeRules.META_PONTOS_DESAFIO_1 - 1
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.EM_ANDAMENTO)
	motor.jogador().pontos = ChallengeRules.META_PONTOS_DESAFIO_1
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.CONCLUIDO)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.META_ATINGIDA)


func test_desafio_1_falha_ao_matar_mesmo_com_pontos_de_sobra() -> void:
	# "Sem matar ninguém" é restrição: violar derrota o desafio mesmo que o
	# próprio abate tenha cruzado a meta de pontos.
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	motor.jogador().pontos = 200
	motor.jogador().abates = 1
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.MATOU_ALGUEM)


func test_desafio_1_falha_ao_morrer() -> void:
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	motor.jogador().viva = false
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.MORREU)


func test_desafio_1_falha_quando_o_tempo_esgota_sem_meta() -> void:
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	# Salta para o último tick e deixa o motor encerrar por tempo.
	motor.tick_atual = motor.config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO - 1
	motor.avancar(Vector2.ZERO)
	assert_that(motor.estado).is_equal(GameEngine.Estado.ENCERRADA)
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.TEMPO_ESGOTADO)


# ------------------------------------------------------------------- desafio 2


func test_desafio_2_conclui_no_terceiro_abate() -> void:
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	motor.jogador().abates = 2
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.EM_ANDAMENTO)
	motor.jogador().abates = 3
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.CONCLUIDO)


func test_desafio_2_meta_no_mesmo_tick_da_morte_vale() -> void:
	# O 3º abate e a morte podem cair no mesmo tick (dois contatos): o abate
	# aconteceu, a meta vale — prioridade documentada no avaliar().
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	motor.jogador().abates = 3
	motor.jogador().viva = false
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.CONCLUIDO)


func test_desafio_2_falha_morrendo_antes_da_meta() -> void:
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	motor.jogador().abates = 2
	motor.jogador().viva = false
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.MORREU)


# ----------------------------------------------------------- trava & progresso


func test_estado_resolvido_trava() -> void:
	var motor: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	motor.jogador().pontos = ChallengeRules.META_PONTOS_DESAFIO_1
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.CONCLUIDO)
	# Eventos posteriores não desfazem a conclusão.
	motor.jogador().abates = 5
	motor.jogador().viva = false
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.CONCLUIDO)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.META_ATINGIDA)


func test_progresso_reporta_e_limita_na_meta() -> void:
	var motor1: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.FARMING_PURO)
	var regras1: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	motor1.jogador().pontos = 30
	assert_int(regras1.progresso_atual(motor1)).is_equal(30)
	assert_int(regras1.progresso_meta()).is_equal(50)
	motor1.jogador().pontos = 80
	assert_int(regras1.progresso_atual(motor1)).is_equal(50)  # limitado na meta

	var motor2: GameEngine = _motor_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var regras2: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	motor2.jogador().abates = 1
	assert_int(regras2.progresso_atual(motor2)).is_equal(1)
	assert_int(regras2.progresso_meta()).is_equal(3)


func test_desafio_3_sobreviver_conclui_morrer_falha() -> void:
	# D3 Defesa: chegar vivo ao encerramento (tempo OU domínio) conclui.
	var config: GameEngine.ConfigPartida = \
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.DEFESA)
	assert_int(config.tamanho_inicial_cacador).is_equal(100)  # spec: 100+
	assert_int(config.cacadores).is_equal(2)
	var motor: GameEngine = GameEngine.new(config)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.DEFESA)
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.EM_ANDAMENTO)
	# Encerrou por tempo com o jogador vivo → concluído.
	motor.tick_atual = config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO
	motor.avancar(Vector2.RIGHT)
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.CONCLUIDO)
	# Morrer falha (instância nova).
	var motor2: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.DEFESA))
	var regras2: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.DEFESA)
	motor2.jogador().viva = false
	motor2.avancar(Vector2.RIGHT)
	assert_that(regras2.avaliar(motor2)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras2.motivo).is_equal(ChallengeRules.Motivo.MORREU)


func test_desafio_4_top3_no_encerramento() -> void:
	# D4: rank ≤3 NO ENCERRAMENTO conclui; morrer antes falha (senão morrer
	# cedo com a arena empatada viraria vitória de sorte).
	var config: GameEngine.ConfigPartida = \
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.INTEGRACAO_TOTAL)
	assert_int(config.fazendeiros + config.cacadores + config.oportunistas) \
		.is_equal(20)  # spec: arena com 20 bots
	# Morte antes do fim: falha mesmo que o rank estivesse bom.
	var motor: GameEngine = GameEngine.new(config)
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.INTEGRACAO_TOTAL)
	motor.jogador().pontos = 99999
	motor.jogador().viva = false
	motor.avancar(Vector2.RIGHT)
	assert_that(regras.avaliar(motor)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras.motivo).is_equal(ChallengeRules.Motivo.MORREU)
	# Tempo esgotado em 1º → concluído.
	var motor2: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.INTEGRACAO_TOTAL))
	var regras2: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.INTEGRACAO_TOTAL)
	motor2.jogador().pontos = 99999
	motor2.tick_atual = motor2.config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO
	motor2.avancar(Vector2.RIGHT)
	assert_that(regras2.avaliar(motor2)).is_equal(ChallengeRules.Estado.CONCLUIDO)
	# Tempo esgotado fora do Top 3 → falha por tempo.
	var motor3: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.INTEGRACAO_TOTAL))
	var regras3: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.INTEGRACAO_TOTAL)
	for cobra: SnakeModel in motor3.arena.cobras:
		if not cobra.eh_jogador():
			cobra.pontos = 1000
	motor3.tick_atual = motor3.config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO
	motor3.avancar(Vector2.RIGHT)
	assert_that(regras3.avaliar(motor3)).is_equal(ChallengeRules.Estado.FALHOU)
	assert_that(regras3.motivo).is_equal(ChallengeRules.Motivo.TEMPO_ESGOTADO)
