extends SceneTree
## Simulador de viabilidade dos desafios: jogadores sintéticos HONESTOS
## (só veem dentro da própria visão, mesmas regras de energia) jogam a
## partida real de cada desafio com estratégias diferentes. Uso:
##   godot --headless -s tools/simular_desafios.gd
## Serve para calibrar composição/metas ANTES do playtest humano.

const NOMES_ESTADO: Array[String] = ["EM_ANDAMENTO", "CONCLUIDO", "FALHOU"]
const NOMES_MOTIVO: Array[String] = ["NENHUM", "META", "MATOU", "MORREU", "TEMPO"]


func _initialize() -> void:
	_jogar(ChallengeRules.Desafio.FARMING_PURO, "Desafio 1 (farming)")
	_jogar(ChallengeRules.Desafio.AGRESSAO_CONTROLADA, "Desafio 2 (caça)")
	_jogar_parado()
	_jogar_cacador_esperto()
	_jogar_pressao_e_bote()
	quit()


## O Desafio 1 pode ser vencido SEM FAZER NADA? (sobrevivência = +1/s)
func _jogar_parado() -> void:
	var motor: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.FARMING_PURO))
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	while motor.estado == GameEngine.Estado.EM_ANDAMENTO \
			and regras.estado == ChallengeRules.Estado.EM_ANDAMENTO:
		motor.avancar(Vector2.ZERO)
		regras.avaliar(motor)
	print("Desafio 1 PARADO → %s (%s) | %.1fs | pontos %d" % [
		NOMES_ESTADO[regras.estado], NOMES_MOTIVO[regras.motivo],
		motor.segundos_decorridos(), motor.jogador().pontos])


## D2 com caça de janela curta (estilo Oportunista) e turbo dedicado.
func _jogar_cacador_esperto() -> void:
	var motor: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA))
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var cerebro: BotEngine = BotEngine.new()
	var rng_jogador: RngService = RngService.new(999)
	while motor.estado == GameEngine.Estado.EM_ANDAMENTO \
			and regras.estado == ChallengeRules.Estado.EM_ANDAMENTO:
		var jogador: SnakeModel = motor.jogador()
		var direcao: Vector2 = cerebro.decidir(jogador, motor.arena, rng_jogador)
		var turbo: bool = jogador.quer_turbo
		if jogador.tamanho >= 3 and not jogador.quer_turbo:
			# Só ataca presa PRÓXIMA (janela de 180) — sem perseguições longas.
			var presa: SnakeModel = cerebro.presa_mais_proxima(jogador, motor.arena, 180.0)
			if presa != null:
				direcao = (presa.posicao - jogador.posicao).normalized()
				turbo = jogador.energia > 15.0
		motor.avancar(direcao, turbo)
		regras.avaliar(motor)
	print("Desafio 2 ESPERTO → %s (%s) | %.1fs | pontos %d | abates %d | tamanho %d" % [
		NOMES_ESTADO[regras.estado], NOMES_MOTIVO[regras.motivo],
		motor.segundos_decorridos(), motor.jogador().pontos,
		motor.jogador().abates, motor.jogador().tamanho])


## D2 com a tática que o desafio quer ensinar: PRESSIONAR sem turbo (a presa
## foge gastando a energia dela) e dar o BOTE de turbo só depois — energia
## cheia contra presa exaurida.
func _jogar_pressao_e_bote() -> void:
	var motor: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.AGRESSAO_CONTROLADA))
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	var cerebro: BotEngine = BotEngine.new()
	var rng_jogador: RngService = RngService.new(999)
	var alvo_id: int = -1
	var ticks_pressao: int = 0
	while motor.estado == GameEngine.Estado.EM_ANDAMENTO \
			and regras.estado == ChallengeRules.Estado.EM_ANDAMENTO:
		var jogador: SnakeModel = motor.jogador()
		var direcao: Vector2 = cerebro.decidir(jogador, motor.arena, rng_jogador)
		var turbo: bool = jogador.quer_turbo  # fuga tem prioridade
		if jogador.tamanho >= 3 and not jogador.quer_turbo:
			var presa: SnakeModel = cerebro.presa_mais_proxima(jogador, motor.arena, 260.0)
			if presa != null:
				if presa.id == alvo_id:
					ticks_pressao += 1
				else:
					alvo_id = presa.id
					ticks_pressao = 0
				direcao = (presa.posicao - jogador.posicao).normalized()
				# Fase 1 (0–3s): pressão a velocidade base — a presa foge de
				# turbo e esgota. Fase 2: bote com turbo e energia cheia.
				turbo = ticks_pressao > 180 and jogador.energia > 25.0
			else:
				alvo_id = -1
				ticks_pressao = 0
		motor.avancar(direcao, turbo)
		regras.avaliar(motor)
	var maior_bot: int = 0
	for cobra: SnakeModel in motor.arena.cobras:
		if not cobra.eh_jogador() and cobra.tamanho > maior_bot:
			maior_bot = cobra.tamanho
	print("Desafio 2 PRESSÃO+BOTE → %s (%s) | %.1fs | pontos %d | abates %d | tamanho %d | maior bot %d" % [
		NOMES_ESTADO[regras.estado], NOMES_MOTIVO[regras.motivo],
		motor.segundos_decorridos(), motor.jogador().pontos,
		motor.jogador().abates, motor.jogador().tamanho, maior_bot])


func _jogar(desafio: ChallengeRules.Desafio, nome: String) -> void:
	var motor: GameEngine = GameEngine.new(ChallengeRules.config_do_desafio(desafio))
	var regras: ChallengeRules = ChallengeRules.new(desafio)
	var cerebro: BotEngine = BotEngine.new()
	# RNG PRÓPRIO do jogador sintético — não perturba a sequência da partida.
	var rng_jogador: RngService = RngService.new(999)

	while motor.estado == GameEngine.Estado.EM_ANDAMENTO \
			and regras.estado == ChallengeRules.Estado.EM_ANDAMENTO:
		var jogador: SnakeModel = motor.jogador()
		# Personalidade JOGADOR não tem braço no match do BotEngine → decidir()
		# vira "fazendeiro honesto": foge de ameaça, senão busca comida.
		var direcao: Vector2 = cerebro.decidir(jogador, motor.arena, rng_jogador)
		var turbo: bool = jogador.quer_turbo  # fuga decidida pelo cérebro
		if desafio == ChallengeRules.Desafio.AGRESSAO_CONTROLADA and jogador.tamanho >= 3:
			var presa: SnakeModel = cerebro.presa_mais_proxima(
				jogador, motor.arena, jogador.raio_visao())
			if presa != null and not jogador.quer_turbo:
				direcao = (presa.posicao - jogador.posicao).normalized()
				turbo = jogador.energia > 30.0
		motor.avancar(direcao, turbo)
		regras.avaliar(motor)

	var jogador_final: SnakeModel = motor.jogador()
	print("%s → %s (%s) | tick %d (%.1fs) | pontos %d | abates %d | tamanho %d" % [
		nome, NOMES_ESTADO[regras.estado], NOMES_MOTIVO[regras.motivo],
		motor.tick_atual, motor.segundos_decorridos(),
		jogador_final.pontos, jogador_final.abates, jogador_final.tamanho,
	])
