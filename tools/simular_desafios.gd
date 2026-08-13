extends SceneTree
## Simulador de viabilidade/tuning dos desafios. Jogadores sintéticos
## HONESTOS (só veem dentro da própria visão, mesmas regras de energia)
## jogam a partida real. Para o D2, roda um LOTE de 12 trajetórias (mesma
## arena — a seed do desafio é fixa —, RNG de decisão do jogador variando)
## e reporta a distribuição: taxa de conclusão/morte, pressão de fuga, tempo.
##   godot --headless -s tools/simular_desafios.gd

const NOMES_ESTADO: Array[String] = ["EM_ANDAMENTO", "CONCLUIDO", "FALHOU"]
const NOMES_MOTIVO: Array[String] = ["NENHUM", "META", "MATOU", "MORREU", "TEMPO"]
const LOTE: int = 24


func _initialize() -> void:
	print("== Desafio 1 ==")
	var r1: Dictionary = _jogar(ChallengeRules.Desafio.FARMING_PURO, 999, false)
	print("  farmando: %s (%s) | %.1fs | pontos %d" % [
		NOMES_ESTADO[r1.estado], NOMES_MOTIVO[r1.motivo], r1.tempo, r1.pontos])
	var r2: Dictionary = _jogar_parado()
	print("  parado:   %s (%s) | %.1fs | pontos %d  (exploit de sobrevivência?)" % [
		NOMES_ESTADO[r2.estado], NOMES_MOTIVO[r2.motivo], r2.tempo, r2.pontos])

	print("== Desafio 2 · lote de %d trajetórias ==" % LOTE)
	var conclusoes: int = 0
	var mortes: int = 0
	var soma_fuga: float = 0.0
	var soma_vizinhos: float = 0.0
	var soma_tempo_conclusao: float = 0.0
	for semente_jogador: int in range(1, LOTE + 1):
		var r: Dictionary = _jogar(
			ChallengeRules.Desafio.AGRESSAO_CONTROLADA, semente_jogador, true)
		soma_fuga += r.fuga
		soma_vizinhos += r.vizinhos
		if r.estado == ChallengeRules.Estado.CONCLUIDO:
			conclusoes += 1
			soma_tempo_conclusao += r.tempo
		elif r.motivo == ChallengeRules.Motivo.MORREU:
			mortes += 1
		print("  #%02d: %s (%s) | %5.1fs | abates %d | fuga %2.0f%%" % [
			semente_jogador, NOMES_ESTADO[r.estado], NOMES_MOTIVO[r.motivo],
			r.tempo, r.abates, r.fuga])
	print("RESUMO D2: conclui %d/%d | morre %d/%d | fuga média %.0f%% | lotação média %.1f bots NA TELA | conclusão média %.0fs" % [
		conclusoes, LOTE, mortes, LOTE, soma_fuga / LOTE, soma_vizinhos / LOTE,
		(soma_tempo_conclusao / conclusoes) if conclusoes > 0 else 0.0])

	_lote_desafio(ChallengeRules.Desafio.DEFESA, "D3")
	_lote_desafio(ChallengeRules.Desafio.INTEGRACAO_TOTAL, "D4")
	_lote_arcade()
	quit()


## Lote genérico de um desafio (mesmo formato do D2).
func _lote_desafio(desafio: ChallengeRules.Desafio, nome: String) -> void:
	print("== %s · lote de %d trajetórias ==" % [nome, LOTE])
	var conclusoes: int = 0
	var mortes: int = 0
	var soma_fuga: float = 0.0
	var soma_tempo: float = 0.0
	for semente_jogador: int in range(1, LOTE + 1):
		var r: Dictionary = _jogar(desafio, semente_jogador, true)
		soma_fuga += r.fuga
		if r.estado == ChallengeRules.Estado.CONCLUIDO:
			conclusoes += 1
			soma_tempo += r.tempo
		elif r.motivo == ChallengeRules.Motivo.MORREU:
			mortes += 1
		print("  #%02d: %s (%s) | %5.1fs | abates %d | fuga %2.0f%%" % [
			semente_jogador, NOMES_ESTADO[r.estado], NOMES_MOTIVO[r.motivo],
			r.tempo, r.abates, r.fuga])
	print("RESUMO %s: conclui %d/%d | morre %d/%d | fuga média %.0f%% | conclusão média %.0fs" % [
		nome, conclusoes, LOTE, mortes, LOTE, soma_fuga / LOTE,
		(soma_tempo / conclusoes) if conclusoes > 0 else 0.0])


## Lote do ARCADE (config padrão, seed variando como no jogo real):
## mede as dores do playtest — ritmo de comida, tamanho alcançado e quantas
## cobras "maiores que eu" existem em média.
func _lote_arcade() -> void:
	print("== Arcade · lote de %d partidas ==" % LOTE)
	var mortes: int = 0
	var soma_vida: float = 0.0
	var soma_tamanho: float = 0.0
	var soma_comidas_min: float = 0.0
	var soma_ameacas: float = 0.0
	var soma_score: float = 0.0
	for semente: int in range(1, LOTE + 1):
		var motor: GameEngine = GameEngine.new(GameEngine.ConfigPartida.padrao(semente * 7919))
		var cerebro: BotEngine = BotEngine.new()
		var rng_jogador: RngService = RngService.new(semente)
		var soma_ameacas_partida: int = 0
		while motor.estado == GameEngine.Estado.EM_ANDAMENTO:
			var jogador: SnakeModel = motor.jogador()
			var direcao: Vector2 = cerebro.decidir(jogador, motor.arena, rng_jogador)
			var turbo: bool = jogador.quer_turbo
			if not jogador.quer_turbo and jogador.nivel >= 3:
				var presa: SnakeModel = cerebro.presa_mais_proxima(
					jogador, motor.arena, jogador.raio_visao())
				if presa != null:
					direcao = (presa.posicao - jogador.posicao).normalized()
					turbo = jogador.energia > 30.0
			direcao = direcao.rotated(rng_jogador.float_entre(-0.25, 0.25))
			motor.avancar(direcao, turbo)
			for outra: SnakeModel in motor.arena.cobras:
				if outra.viva and not outra.eh_jogador() and outra.pode_devorar(jogador):
					soma_ameacas_partida += 1
		var jogador_final: SnakeModel = motor.jogador()
		if not jogador_final.viva:
			mortes += 1
		var minutos: float = maxf(0.05, motor.segundos_decorridos() / 60.0)
		soma_vida += motor.segundos_decorridos()
		soma_tamanho += float(jogador_final.nivel)
		soma_comidas_min += jogador_final.comidas / minutos
		soma_ameacas += float(soma_ameacas_partida) / maxf(1.0, float(motor.tick_atual))
		soma_score += float(jogador_final.pontos)
	print("RESUMO ARCADE: morre %d/%d | vida média %.0fs | tamanho final médio %.1f | comidas/min %.1f | ameaças médias %.1f | score médio %.0f" % [
		mortes, LOTE, soma_vida / LOTE, soma_tamanho / LOTE,
		soma_comidas_min / LOTE, soma_ameacas / LOTE, soma_score / LOTE])


## Joga um desafio com o jogador sintético; `caca` liga a caça ingênua
## (persegue presa visível com turbo quando não está fugindo).
func _jogar(desafio: ChallengeRules.Desafio, semente_jogador: int, caca: bool) -> Dictionary:
	var motor: GameEngine = GameEngine.new(ChallengeRules.config_do_desafio(desafio))
	var regras: ChallengeRules = ChallengeRules.new(desafio)
	var cerebro: BotEngine = BotEngine.new()
	# RNG PRÓPRIO da trajetória — não perturba a sequência da partida.
	var rng_jogador: RngService = RngService.new(semente_jogador)
	var ticks_fugindo: int = 0
	var soma_vizinhos: int = 0  # lotação: bots dentro da visão do jogador

	while motor.estado == GameEngine.Estado.EM_ANDAMENTO \
			and regras.estado == ChallengeRules.Estado.EM_ANDAMENTO:
		var jogador: SnakeModel = motor.jogador()
		# Personalidade JOGADOR não tem braço no match do BotEngine → decidir()
		# vira "fazendeiro honesto": foge de ameaça, senão busca comida.
		var direcao: Vector2 = cerebro.decidir(jogador, motor.arena, rng_jogador)
		var turbo: bool = jogador.quer_turbo  # fuga decidida pelo cérebro
		if jogador.quer_turbo:
			ticks_fugindo += 1
		elif caca and jogador.nivel >= 3:
			var presa: SnakeModel = cerebro.presa_mais_proxima(
				jogador, motor.arena, jogador.raio_visao())
			if presa != null:
				direcao = (presa.posicao - jogador.posicao).normalized()
				turbo = jogador.energia > 30.0
		# "Imprecisão humana": ruído angular por tick, específico da trajetória.
		# Sem isso, comida sempre visível => caminho 100% determinístico e o
		# lote inteiro degenera na mesma partida.
		direcao = direcao.rotated(rng_jogador.float_entre(-0.25, 0.25))
		motor.avancar(direcao, turbo)
		regras.avaliar(motor)
		# Lotação como o JOGADOR vê: bots dentro do enquadramento da câmera
		# (mesma fórmula de zoom do jogo.gd — tela 412×915, zoom mín 0.55).
		var zoom: float = clampf(SnakeModel.VISAO_BASE / jogador.raio_visao(), 0.55, 1.0)
		var meia_tela: Vector2 = Vector2(412.0, 915.0) * 0.5 / zoom
		for outra: SnakeModel in motor.arena.cobras:
			if outra == jogador or not outra.viva:
				continue
			var delta_pos: Vector2 = (outra.posicao - jogador.posicao).abs()
			if delta_pos.x <= meia_tela.x and delta_pos.y <= meia_tela.y:
				soma_vizinhos += 1

	return {
		"estado": regras.estado,
		"motivo": regras.motivo,
		"tempo": motor.segundos_decorridos(),
		"pontos": motor.jogador().pontos,
		"abates": motor.jogador().abates,
		"fuga": 100.0 * ticks_fugindo / maxf(1.0, float(motor.tick_atual)),
		"vizinhos": float(soma_vizinhos) / maxf(1.0, float(motor.tick_atual)),
	}


## O Desafio 1 pode ser vencido SEM FAZER NADA? (sobrevivência = +1/s)
func _jogar_parado() -> Dictionary:
	var motor: GameEngine = GameEngine.new(
		ChallengeRules.config_do_desafio(ChallengeRules.Desafio.FARMING_PURO))
	var regras: ChallengeRules = ChallengeRules.new(ChallengeRules.Desafio.FARMING_PURO)
	while motor.estado == GameEngine.Estado.EM_ANDAMENTO \
			and regras.estado == ChallengeRules.Estado.EM_ANDAMENTO:
		motor.avancar(Vector2.ZERO)
		regras.avaliar(motor)
	return {
		"estado": regras.estado,
		"motivo": regras.motivo,
		"tempo": motor.segundos_decorridos(),
		"pontos": motor.jogador().pontos,
		"abates": 0,
		"fuga": 0.0,
	}
