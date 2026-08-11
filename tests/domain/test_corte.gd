class_name TestCorte
extends GdUnitTestSuite
## Corte de corpo (docs §2.7) e velocidade por tamanho (§2.2, emenda ago/2026).


## Motor vazio (sem bots, sem comida) para coreografar cortes na mão.
func _motor(arena_lado: float = 2000.0) -> GameEngine:
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.semente = 7
	config.tamanho_arena = Vector2(arena_lado, arena_lado)
	config.qtd_comida = 0
	config.fazendeiros = 0
	config.cacadores = 0
	config.oportunistas = 0
	config.aplicar_buffs = false
	return GameEngine.new(config)


## Anda `ticks` com a vítima reta para a direita — constrói corpo real.
func _construir_corpo(motor: GameEngine, cobra: SnakeModel, ticks: int) -> void:
	cobra.direcao = Vector2.RIGHT
	for t: int in ticks:
		motor.avancar(Vector2.RIGHT)


func test_velocidade_cresce_com_tamanho_com_teto() -> void:
	var cobra: SnakeModel = SnakeModel.new(1, SnakeModel.Personalidade.JOGADOR, Vector2.ZERO)
	assert_float(cobra.multiplicador_tamanho()).is_equal_approx(1.0, 0.0001)
	cobra.tamanho = 25
	assert_float(cobra.multiplicador_tamanho()).is_equal_approx(1.12, 0.0001)
	cobra.tamanho = 10000  # absurdo de propósito: o teto segura
	assert_float(cobra.multiplicador_tamanho()) \
		.is_equal_approx(SnakeModel.VEL_TETO_TAMANHO, 0.0001)


func test_corpo_e_aparado_no_comprimento_do_tamanho() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	_construir_corpo(motor, jogador, 300)  # anda muito além do comprimento
	var total: float = 0.0
	for i: int in range(1, jogador.corpo.size()):
		total += jogador.corpo[i - 1].distance_to(jogador.corpo[i])
	# O rabo é aparado logo após cruzar o alvo (tolerância = 2 passos de tick).
	assert_float(total).is_greater(jogador.comprimento_corpo() * 0.9)
	assert_float(total).is_less(jogador.comprimento_corpo() + 12.0)


func test_so_quem_pode_devorar_corta() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 10
	_construir_corpo(motor, jogador, 60)
	# Igual (10 vs 10) NÃO corta — mesma regra 11/10 do abate.
	var igual: SnakeModel = SnakeModel.new(50, SnakeModel.Personalidade.CACADOR,
		jogador.corpo[jogador.corpo.size() - 1], 10)
	motor.arena.adicionar_cobra(igual)
	igual.direcao = Vector2.ZERO
	motor.avancar(Vector2.RIGHT)
	assert_int(jogador.cortes_sofridos).is_equal(0)
	# 11 vs 10 corta (limiar exato em inteiros).
	igual.tamanho = 11
	motor.avancar(Vector2.RIGHT)
	assert_int(jogador.cortes_sofridos).is_equal(1)


func test_corte_encolhe_derruba_comida_e_nao_pontua() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 20
	_construir_corpo(motor, jogador, 200)
	var predadora: SnakeModel = SnakeModel.new(
		50, SnakeModel.Personalidade.CACADOR, Vector2.ZERO, 30)
	motor.arena.adicionar_cobra(predadora)
	# Cabeça da predadora no MEIO do corpo do jogador.
	var meio: int = jogador.corpo.size() / 2
	predadora.posicao = jogador.corpo[meio]
	predadora.direcao = Vector2.ZERO
	var pontos_antes: int = predadora.pontos
	var comidas_antes: int = motor.arena.comidas.size()
	var tamanho_antes: int = jogador.tamanho

	motor.avancar(Vector2.RIGHT)

	assert_int(jogador.cortes_sofridos).is_equal(1)
	assert_bool(jogador.viva).is_true()  # corte não mata — morte é pela cabeça
	assert_int(jogador.tamanho).is_less(tamanho_antes)
	var perda: int = tamanho_antes - jogador.tamanho
	# Comida derrubada = tamanho perdido (§2.7: valor equivalente). A reposição
	# da arena não interfere: alvo é 0 nesta config.
	assert_int(motor.arena.comidas.size() - comidas_antes).is_equal(perda)
	# Sem pontos nem crescimento para quem cortou.
	assert_int(predadora.pontos).is_equal(pontos_antes)
	assert_int(predadora.abates).is_equal(0)
	assert_int(predadora.cortes_feitos).is_equal(1)


func test_protecao_impede_retalhamento_em_serie() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 20
	_construir_corpo(motor, jogador, 200)
	var predadora: SnakeModel = SnakeModel.new(
		50, SnakeModel.Personalidade.CACADOR, jogador.corpo[jogador.corpo.size() / 2], 30)
	predadora.direcao = Vector2.ZERO
	motor.arena.adicionar_cobra(predadora)
	# Meio segundo com a cabeça ENCOSTADA no corpo: só 1 corte pode acontecer.
	for t: int in 30:
		predadora.posicao = jogador.corpo[jogador.corpo.size() / 2] \
			if jogador.corpo.size() > 4 else predadora.posicao
		motor.avancar(Vector2.RIGHT)
	assert_int(jogador.cortes_sofridos).is_equal(1)


func test_zona_do_pescoco_nao_corta() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 20
	_construir_corpo(motor, jogador, 200)
	var predadora: SnakeModel = SnakeModel.new(
		50, SnakeModel.Personalidade.CACADOR, Vector2.ZERO, 22)
	# Encostada no pescoço (1 raio atrás da cabeça): NÃO é corte — e não é
	# devorável cabeça-cabeça aqui porque afastamos o suficiente do raio somado?
	# Não: 1 raio atrás ainda encosta na cabeça → seria devorar. O teste real:
	# um ponto do corpo dentro da zona (2 raios) mas fora do alcance da cabeça.
	predadora.posicao = jogador.posicao + Vector2.LEFT * (jogador.raio() * 1.9)
	predadora.posicao += Vector2.UP * (jogador.raio() + predadora.raio()) * 1.05
	motor.arena.adicionar_cobra(predadora)
	predadora.direcao = Vector2.ZERO
	motor.avancar(Vector2.RIGHT)
	assert_int(jogador.cortes_sofridos).is_equal(0)


func test_determinismo_com_cortes_ativos() -> void:
	# Mesma seed, arena cheia de bots que se cortam: estado final idêntico.
	var config_a: GameEngine.ConfigPartida = GameEngine.ConfigPartida.padrao(4242)
	var config_b: GameEngine.ConfigPartida = GameEngine.ConfigPartida.padrao(4242)
	var a: GameEngine = GameEngine.new(config_a)
	var b: GameEngine = GameEngine.new(config_b)
	for t: int in 600:  # 10s de partida
		a.avancar(Vector2.RIGHT.rotated(float(t) * 0.01))
		b.avancar(Vector2.RIGHT.rotated(float(t) * 0.01))
	for i: int in a.arena.cobras.size():
		var ca: SnakeModel = a.arena.cobras[i]
		var cb: SnakeModel = b.arena.cobras[i]
		assert_int(ca.tamanho).is_equal(cb.tamanho)
		assert_int(ca.cortes_sofridos).is_equal(cb.cortes_sofridos)
		assert_vector(ca.posicao).is_equal_approx(cb.posicao, Vector2(0.001, 0.001))
