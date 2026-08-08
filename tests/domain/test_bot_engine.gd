class_name TestBotEngine
extends GdUnitTestSuite
## Comportamento de cada personalidade + as duas garantias de honestidade:
## visão limitada e reação a 100ms. Cenários montados no centro de uma arena
## grande para o desvio de borda não interferir.

const CENTRO: Vector2 = Vector2(1200.0, 1200.0)


func _arena() -> ArenaModel:
	return ArenaModel.new(Vector2(2400.0, 2400.0))


func _bot(personalidade: SnakeModel.Personalidade, tamanho: int, posicao: Vector2 = CENTRO) -> SnakeModel:
	var cobra: SnakeModel = SnakeModel.new(1, personalidade, posicao, tamanho)
	cobra.agressividade = 0.5
	return cobra


# ------------------------------------------------------------------ Fazendeiro


func test_fazendeiro_vai_para_a_comida_visivel() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.FAZENDEIRO, 3)
	arena.adicionar_cobra(bot)
	arena.comidas.append(CENTRO + Vector2(150.0, 0.0))
	var direcao: Vector2 = BotEngine.new().decidir(bot, arena, RngService.new(1))
	assert_float(direcao.dot(Vector2.RIGHT)).is_greater(0.99)


func test_fugir_de_ameaca_tem_prioridade_sobre_comida() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.FAZENDEIRO, 3)
	var ameaca: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.CACADOR, CENTRO + Vector2(100.0, 0.0), 10)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(ameaca)
	arena.comidas.append(CENTRO + Vector2(150.0, 0.0))  # comida NO MESMO lado da ameaça
	var direcao: Vector2 = BotEngine.new().decidir(bot, arena, RngService.new(1))
	# Foge para o lado oposto, ignorando a comida.
	assert_float(direcao.dot(Vector2.RIGHT)).is_less(-0.9)


# --------------------------------------------------------------------- Caçador


func test_cacador_persegue_presa_devoravel() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.CACADOR, 22)
	var presa: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, CENTRO + Vector2(150.0, 0.0), 10)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(presa)
	var direcao: Vector2 = BotEngine.new().decidir(bot, arena, RngService.new(1))
	assert_float(direcao.dot(Vector2.RIGHT)).is_greater(0.99)


func test_cacador_sem_presa_a_vista_farma() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.CACADOR, 22)
	arena.adicionar_cobra(bot)
	arena.comidas.append(CENTRO + Vector2(0.0, -120.0))
	var direcao: Vector2 = BotEngine.new().decidir(bot, arena, RngService.new(1))
	assert_float(direcao.dot(Vector2.UP)).is_greater(0.99)


func test_cacador_nao_persegue_quem_nao_pode_devorar() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.CACADOR, 10)
	# Alvo do mesmo tamanho: não é presa (10 < 1.1×10) nem ameaça.
	var alvo: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, CENTRO + Vector2(150.0, 0.0), 10)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(alvo)
	assert_object(BotEngine.new().presa_mais_proxima(bot, arena, bot.raio_visao())).is_null()


# ----------------------------------------------------------------- Oportunista


func test_oportunista_ataca_presa_que_cruza_o_caminho() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.OPORTUNISTA, 22)
	# visão(22) = 352; alcance de oportunidade (ag 0.5) = 0.55 × 352 ≈ 193.
	var presa: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, CENTRO + Vector2(100.0, 0.0), 10)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(presa)
	var direcao: Vector2 = BotEngine.new().decidir(bot, arena, RngService.new(1))
	assert_float(direcao.dot(Vector2.RIGHT)).is_greater(0.99)


func test_oportunista_prefere_farmar_quando_a_presa_esta_longe() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.OPORTUNISTA, 22)
	# Presa DENTRO da visão (352) mas FORA do alcance de oportunidade (~193):
	var presa: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, CENTRO + Vector2(250.0, 0.0), 10)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(presa)
	arena.comidas.append(CENTRO + Vector2(0.0, -80.0))
	var direcao: Vector2 = BotEngine.new().decidir(bot, arena, RngService.new(1))
	assert_float(direcao.dot(Vector2.UP)).is_greater(0.99)


func test_mesmo_cenario_cacador_ataca_oportunista_farma() -> void:
	# A MESMA cena produz decisões diferentes por personalidade — é isso que
	# torna o padrão de comportamento legível para o jogador (docs §1).
	var motor: BotEngine = BotEngine.new()
	for caso: Array in [
		[SnakeModel.Personalidade.CACADOR, Vector2.RIGHT],  # ataca a presa
		[SnakeModel.Personalidade.OPORTUNISTA, Vector2.UP],  # vai à comida
	]:
		var arena: ArenaModel = _arena()
		var bot: SnakeModel = _bot(caso[0], 22)
		var presa: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, CENTRO + Vector2(250.0, 0.0), 10)
		arena.adicionar_cobra(bot)
		arena.adicionar_cobra(presa)
		arena.comidas.append(CENTRO + Vector2(0.0, -80.0))
		var direcao: Vector2 = motor.decidir(bot, arena, RngService.new(1))
		assert_float(direcao.dot(caso[1])).is_greater(0.99)


# ------------------------------------------------------------------ Honestidade


func test_honestidade_nao_ve_presa_fora_da_visao() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.CACADOR, 22)
	var presa: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.FAZENDEIRO, CENTRO + Vector2(900.0, 0.0), 10)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(presa)
	assert_object(BotEngine.new().presa_mais_proxima(bot, arena, bot.raio_visao())).is_null()


func test_honestidade_nao_ve_ameaca_fora_da_visao() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.FAZENDEIRO, 3)
	var ameaca: SnakeModel = SnakeModel.new(2, SnakeModel.Personalidade.CACADOR, CENTRO + Vector2(900.0, 0.0), 50)
	arena.adicionar_cobra(bot)
	arena.adicionar_cobra(ameaca)
	assert_object(BotEngine.new().ameaca_mais_proxima(bot, arena)).is_null()


func test_honestidade_reacao_de_100ms() -> void:
	# Fora do tick de decisão, o bot mantém o rumo mesmo com estímulo novo.
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.FAZENDEIRO, 3)  # id 1
	arena.adicionar_cobra(bot)
	arena.comidas.append(CENTRO + Vector2(150.0, 0.0))
	bot.direcao = Vector2.UP
	var motor: BotEngine = BotEngine.new()
	var rng: RngService = RngService.new(1)
	motor.atualizar(0, arena, rng)  # (0 + 1) % 6 != 0 → não é a vez dele
	assert_float(bot.direcao.dot(Vector2.UP)).is_greater(0.99)
	motor.atualizar(5, arena, rng)  # (5 + 1) % 6 == 0 → decide agora
	assert_float(bot.direcao.dot(Vector2.RIGHT)).is_greater(0.99)


func test_bot_morto_nao_decide() -> void:
	var arena: ArenaModel = _arena()
	var bot: SnakeModel = _bot(SnakeModel.Personalidade.FAZENDEIRO, 3)
	arena.adicionar_cobra(bot)
	arena.comidas.append(CENTRO + Vector2(150.0, 0.0))
	bot.viva = false
	bot.direcao = Vector2.UP
	BotEngine.new().atualizar(5, arena, RngService.new(1))
	assert_float(bot.direcao.dot(Vector2.UP)).is_greater(0.99)


func test_decisoes_sao_deterministicas() -> void:
	# Sem estímulo → vagueio via RNG; mesma seed → mesmo rumo.
	var direcoes: Array[Vector2] = []
	for rodada: int in 2:
		var arena: ArenaModel = _arena()
		var bot: SnakeModel = _bot(SnakeModel.Personalidade.FAZENDEIRO, 3)
		arena.adicionar_cobra(bot)
		direcoes.append(BotEngine.new().decidir(bot, arena, RngService.new(77)))
	assert_vector(direcoes[0]).is_equal(direcoes[1])
