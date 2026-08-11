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
	cobra.nivel = 25
	assert_float(cobra.multiplicador_tamanho()).is_equal_approx(1.12, 0.0001)
	cobra.tamanho = 10000  # absurdo de propósito: o teto segura
	cobra.nivel = 10000
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


func test_corte_livre_qualquer_uma_corta() -> void:
	# EM TESTE (§2.7, ago/2026): sem regra de tamanho — até a MENOR corta o
	# corpo da maior (contra-golpe do pequeno contra o líder gigante).
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 30
	jogador.nivel = 30
	_construir_corpo(motor, jogador, 200)
	var pequena: SnakeModel = SnakeModel.new(50, SnakeModel.Personalidade.CACADOR,
		jogador.corpo[jogador.corpo.size() - 10], 1)
	motor.arena.adicionar_cobra(pequena)
	pequena.direcao = Vector2.ZERO
	motor.avancar(Vector2.RIGHT)
	assert_int(jogador.cortes_sofridos).is_equal(1)
	assert_int(pequena.cortes_feitos).is_equal(1)
	assert_bool(jogador.viva).is_true()


func test_corte_encolhe_derruba_comida_e_nao_pontua() -> void:
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 20
	jogador.nivel = 20
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
	jogador.nivel = 20
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
	jogador.nivel = 20
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


func test_corte_leva_massa_mas_nao_rebaixa_nivel() -> void:
	# Decisão do Rodrigo (§2.7): visão + velocidade + direito de devorar são
	# do NÍVEL, que nunca desce — o corte leva só a MASSA (corpo).
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 20
	jogador.nivel = 20
	_construir_corpo(motor, jogador, 200)
	var visao_antes: float = jogador.raio_visao()
	var velocidade_antes: float = jogador.multiplicador_tamanho()
	var raio_antes: float = jogador.raio()
	var predadora: SnakeModel = SnakeModel.new(
		50, SnakeModel.Personalidade.CACADOR, jogador.corpo[jogador.corpo.size() / 2], 30)
	predadora.direcao = Vector2.ZERO
	motor.arena.adicionar_cobra(predadora)
	motor.avancar(Vector2.RIGHT)

	assert_int(jogador.cortes_sofridos).is_equal(1)
	assert_int(jogador.tamanho).is_less(20)          # massa caiu
	assert_int(jogador.nivel).is_equal(20)           # nível intacto
	assert_float(jogador.raio_visao()).is_equal(visao_antes)
	assert_float(jogador.multiplicador_tamanho()).is_equal(velocidade_antes)
	assert_float(jogador.raio()).is_equal(raio_antes)
	# Direito de devorar preservado: uma cobra nível 15 continuava no cardápio.
	var quinze: SnakeModel = SnakeModel.new(
		60, SnakeModel.Personalidade.FAZENDEIRO, Vector2(100.0, 100.0), 15)
	assert_bool(jogador.pode_devorar(quinze)).is_true()
	# E a recuperação: comer devolve massa (e segue subindo o nível).
	var massa_pos_corte: int = jogador.tamanho
	motor.arena.comidas.append(jogador.posicao + jogador.direcao * 4.0)
	motor.avancar(jogador.direcao)
	assert_int(jogador.tamanho).is_equal(massa_pos_corte + 1)
	assert_int(jogador.nivel).is_equal(21)


func test_abate_pontua_pelo_nivel_e_cresce_pela_massa() -> void:
	# Vítima raspada: prestígio (pontos) pelo nível 16, carne (crescimento)
	# pela massa 4 que sobrou.
	var motor: GameEngine = _motor()
	var jogador: SnakeModel = motor.jogador()
	jogador.tamanho = 30
	jogador.nivel = 30
	var vitima: SnakeModel = SnakeModel.new(
		50, SnakeModel.Personalidade.FAZENDEIRO, jogador.posicao, 16)
	vitima.tamanho = 4  # foi cortada: massa 4, nível 16
	motor.arena.adicionar_cobra(vitima)
	motor.avancar(Vector2.RIGHT)
	assert_bool(vitima.viva).is_false()
	assert_int(jogador.pontos).is_equal(GameEngine.pontos_por_abate(16))
	assert_int(jogador.tamanho).is_equal(32)  # 30 + 4/2
	assert_int(jogador.nivel).is_equal(32)


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
