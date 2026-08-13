class_name TestProgressoLocal
extends GdUnitTestSuite
## Progresso local: skin equipada, economia e dificuldade — persistência
## em disco E comportamento do cache (o render lê a skin a cada frame).


func before_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func after_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func test_padroes_de_fabrica() -> void:
	assert_int(ProgressoLocal.skin_equipada()).is_equal(0)  # verde
	assert_int(int(ProgressoLocal.dificuldade())) \
		.is_equal(int(ProgressoLocal.Dificuldade.CHEIA))
	assert_bool(ProgressoLocal.desafio_concluido(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)) \
		.is_false()


func test_skin_persiste_no_disco() -> void:
	ProgressoLocal.equipar_skin(6)
	# Derruba o cache: simula um novo boot — o valor tem que vir do arquivo.
	ProgressoLocal._resetar_cache_para_testes()
	assert_int(ProgressoLocal.skin_equipada()).is_equal(6)


func test_dificuldade_persiste() -> void:
	ProgressoLocal.definir_dificuldade(ProgressoLocal.Dificuldade.TRANQUILA)
	ProgressoLocal._resetar_cache_para_testes()
	assert_int(int(ProgressoLocal.dificuldade())) \
		.is_equal(int(ProgressoLocal.Dificuldade.TRANQUILA))


func test_desafio_concluido_persiste() -> void:
	ProgressoLocal.marcar_desafio_concluido(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	ProgressoLocal._resetar_cache_para_testes()
	assert_bool(ProgressoLocal.desafio_concluido(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)) \
		.is_true()


func test_vibracao_e_lado_do_turbo_persistem() -> void:
	assert_bool(ProgressoLocal.vibracao()).is_true()          # padrão ligada
	assert_bool(ProgressoLocal.turbo_a_esquerda()).is_false() # padrão direita
	ProgressoLocal.definir_vibracao(false)
	ProgressoLocal.definir_turbo_esquerda(true)
	ProgressoLocal._resetar_cache_para_testes()
	assert_bool(ProgressoLocal.vibracao()).is_false()
	assert_bool(ProgressoLocal.turbo_a_esquerda()).is_true()


func test_melhor_posicao_so_melhora() -> void:
	# Blueprint 05: "sua melhor posição até hoje!" — 0 = nunca terminou.
	assert_int(ProgressoLocal.melhor_posicao()).is_equal(0)
	assert_bool(ProgressoLocal.registrar_posicao(9)).is_true()   # 1ª partida
	assert_bool(ProgressoLocal.registrar_posicao(12)).is_false() # piorou
	assert_bool(ProgressoLocal.registrar_posicao(3)).is_true()   # recorde
	ProgressoLocal._resetar_cache_para_testes()
	assert_int(ProgressoLocal.melhor_posicao()).is_equal(3)


func test_economia_zerada_persiste_e_nunca_negativa() -> void:
	# Economia liga no M3 — os contadores já existem, zerados (11/08).
	assert_int(ProgressoLocal.moedas()).is_equal(0)
	assert_int(ProgressoLocal.tickets()).is_equal(0)
	ProgressoLocal.adicionar_moedas(120)
	ProgressoLocal.adicionar_tickets(2)
	ProgressoLocal._resetar_cache_para_testes()
	assert_int(ProgressoLocal.moedas()).is_equal(120)
	assert_int(ProgressoLocal.tickets()).is_equal(2)
	ProgressoLocal.adicionar_moedas(-999)  # gastar além do saldo não negativa
	assert_int(ProgressoLocal.moedas()).is_equal(0)


func test_config_arcade_respeita_dificuldade_tranquila() -> void:
	# A dificuldade muda a COMPOSIÇÃO do Arcade (nunca trapaça).
	ProgressoLocal.definir_dificuldade(ProgressoLocal.Dificuldade.TRANQUILA)
	Sessao.desafio_pendente = -1
	Sessao.proxima_semente = 42
	var tranquila: GameEngine.ConfigPartida = Sessao.config_para_jogar()
	assert_int(tranquila.cacadores).is_equal(3)
	assert_float(tranquila.agressividade).is_equal_approx(0.35, 0.001)

	ProgressoLocal.definir_dificuldade(ProgressoLocal.Dificuldade.CHEIA)
	Sessao.proxima_semente = 42
	var cheia: GameEngine.ConfigPartida = Sessao.config_para_jogar()
	assert_int(cheia.cacadores).is_equal(6)


func test_dificuldade_nunca_mexe_em_desafio() -> void:
	# Desafio é comparável por seed: a dificuldade do Arcade não o toca.
	ProgressoLocal.definir_dificuldade(ProgressoLocal.Dificuldade.TRANQUILA)
	Sessao.desafio_pendente = int(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var config: GameEngine.ConfigPartida = Sessao.config_para_jogar()
	var referencia: GameEngine.ConfigPartida = \
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	assert_int(config.cacadores).is_equal(referencia.cacadores)
	assert_float(config.agressividade).is_equal_approx(referencia.agressividade, 0.001)
	Sessao.regras_desafio = null


func test_gastar_moedas_exige_saldo() -> void:
	assert_bool(ProgressoLocal.gastar_moedas(10)).is_false()
	assert_int(ProgressoLocal.moedas()).is_equal(0)
	ProgressoLocal.adicionar_moedas(300)
	assert_bool(ProgressoLocal.gastar_moedas(244)).is_true()
	assert_int(ProgressoLocal.moedas()).is_equal(56)


func test_nivel_buff_sobe_ate_o_teto_do_motor() -> void:
	assert_int(ProgressoLocal.nivel_buff("velocidade")).is_equal(0)
	for _i: int in GameEngine.NIVEL_MAX_BUFF + 3:
		ProgressoLocal.subir_buff("velocidade")
	assert_int(ProgressoLocal.nivel_buff("velocidade")) \
		.is_equal(GameEngine.NIVEL_MAX_BUFF)


func test_config_arcade_carrega_buffs_comprados() -> void:
	ProgressoLocal.subir_buff("ima")
	ProgressoLocal.subir_buff("pontos")
	Sessao.desafio_pendente = -1
	Sessao.proxima_semente = 42
	var config: GameEngine.ConfigPartida = Sessao.config_para_jogar()
	assert_int(config.nivel_ima).is_equal(1)
	assert_int(config.nivel_pontos_iniciais).is_equal(1)
	assert_bool(config.aplicar_buffs).is_true()


func test_desafio_continua_sem_buffs() -> void:
	# Comparabilidade educacional (docs §2.6.3): desafio ignora buffs.
	ProgressoLocal.subir_buff("velocidade")
	Sessao.desafio_pendente = int(ChallengeRules.Desafio.FARMING_PURO)
	var config: GameEngine.ConfigPartida = Sessao.config_para_jogar()
	assert_bool(config.aplicar_buffs).is_false()
	Sessao.regras_desafio = null
