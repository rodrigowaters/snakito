class_name GameEngine
extends RefCounted
## Motor da partida: física, colisão, crescimento, pontuação e regras de
## morte, em tick fixo de 60Hz (docs §2). Puro: a cena chama `avancar()` a
## cada physics frame e apenas RENDERIZA o estado resultante.
##
## Determinismo (regra dura #2): mesma ConfigPartida (mesma seed) + mesma
## sequência de inputs => partida idêntica. Toda aleatoriedade passa pelo
## RngService; toda iteração é em ordem fixa.

## Id fixo do jogador (sempre a primeira cobra da arena).
const ID_JOGADOR: int = 0

# --- Tempo -------------------------------------------------------------------
const TICKS_POR_SEGUNDO: int = 60
const DELTA: float = 1.0 / 60.0

# --- Movimento ---------------------------------------------------------------
## Velocidade BASE de toda cobra, em unidades/segundo. O turbo multiplica
## (docs §2.6); fora dele, todas andam igual.
const VELOCIDADE: float = 180.0

# --- Turbo (docs §2.6) ---------------------------------------------------------
## Consumo de energia com turbo ativo, por segundo.
const CONSUMO_TURBO: float = 40.0
## Regeneração com turbo solto, por segundo.
const REGEN_TURBO: float = 16.0
## Energia mínima para ATIVAR o turbo (histerese: uma vez ativo, só desliga
## em zero — evita liga-desliga trêmulo no limiar).
const ENERGIA_MIN_TURBO: float = 10.0

# --- Buffs (docs §2.6.2 — só o jogador, e só quando aplicar_buffs) -----------
const NIVEL_MAX_BUFF: int = 10
## +0.05 no multiplicador do turbo por nível (teto: ×2.0 no Nv 10).
const BUFF_VELOCIDADE_POR_NIVEL: float = 0.05
## Ímã: raio no Nv 1 e ganho por nível seguinte (teto: 175 no Nv 10).
const IMA_RAIO_NIVEL_1: float = 40.0
const IMA_RAIO_POR_NIVEL: float = 15.0
## Velocidade com que o ímã puxa a comida, em unidades/segundo.
const IMA_VELOCIDADE: float = 120.0
## +5 pontos iniciais por nível (teto: +50 no Nv 10).
const BUFF_PONTOS_POR_NIVEL: int = 5

# --- Corte de corpo (docs §2.7) -----------------------------------------------
## Proteção após sofrer um corte: 1s incortável (devorar a cabeça NÃO respeita
## esta proteção — ela existe só para a cabeça não retalhar o corpo em série).
const PROTECAO_CORTE_TICKS: int = 60
## "Espessura" de colisão do corpo, em fração do raio da vítima (o corpo
## desenhado afina em direção ao rabo; 0.7 é o meio-termo do render).
const ESPESSURA_CORPO: float = 0.7

# --- Pontuação (docs §2.2; onde a spec não fixa número, a constante fixa) ----
## Comida: +1 tamanho, +10 pontos (fixado na spec).
const PONTOS_COMIDA: int = 10
const CRESCIMENTO_COMIDA: int = 1
## "Tempo sobrevivido" pontua: +1 ponto por segundo vivo (escolha nossa).
const PONTOS_POR_SEGUNDO: int = 1
## Abate: 100–500 pontos, escala não-linear (spec fixa a faixa; a curva
## escolhida é 100·√(tamanho da vítima), com clamp).
const PONTOS_ABATE_MIN: int = 100
const PONTOS_ABATE_MAX: int = 500
## Crescimento por abate: proporcional ao tamanho da vítima (spec); fração
## escolhida = metade, mínimo 1.
const FRACAO_CRESCIMENTO_ABATE: float = 0.5

enum Estado { EM_ANDAMENTO, ENCERRADA }


## Composição da partida = dificuldade (docs §2.4): quantidade, tamanho
## inicial e agressividade dos bots. Padrão = mini-arena do spike (30 bots).
class ConfigPartida:
	var semente: int = 1
	var tamanho_arena: Vector2 = Vector2(2400.0, 2400.0)
	var duracao_seg: int = 180
	var qtd_comida: int = 110
	var fazendeiros: int = 12
	var cacadores: int = 6
	var oportunistas: int = 12
	var tamanho_min_bot: int = 1
	var tamanho_max_bot: int = 5
	var agressividade: float = 0.5
	## Multiplicador de turbo dos BOTS — eixo de composição/dificuldade
	## (§2.6): capacidade transparente sob as mesmas regras de energia,
	## nunca acima do base do jogador. Playtest de 08/08 mostrou que a
	## paridade total (1.5 vs 1.5) torna a caça impossível em campo aberto.
	var turbo_bots: float = 1.4
	## Teto de crescimento dos bots (0 = sem teto). Bots se devoram e viram
	## gigantes (simulador: tamanho 286 em 2 min na arena compacta) — o teto
	## contém a bola de neve onde ela estraga a partida.
	var tamanho_teto_bot: int = 20
	## Teto próprio dos CAÇADORES (0 = herdam o teto geral). Permite
	## predadores-alfa que continuam ameaçando o jogador crescido — e visão
	## escala com tamanho, então a perseguição deles é longa por natureza —
	## enquanto o resto da arena fica contido.
	var tamanho_teto_cacador: int = 35
	## Tamanho de NASCIMENTO dos caçadores (0 = sorteio padrão). Ameaça desde
	## o primeiro segundo — e é o eixo que o Desafio 3 da spec exige
	## ("2 caçadores de tamanho 100+", docs §2.5).
	var tamanho_inicial_cacador: int = 0
	# Buffs do jogador (docs §2.6.2). Desafios criam a config com
	# aplicar_buffs = false — partida por seed tem que ser comparável.
	var aplicar_buffs: bool = true
	var nivel_velocidade: int = 0
	var nivel_ima: int = 0
	var nivel_pontos_iniciais: int = 0

	static func padrao(semente_: int) -> ConfigPartida:
		var config: ConfigPartida = ConfigPartida.new()
		config.semente = semente_
		return config


## Distância mínima de spawn de bot em relação ao jogador — ninguém nasce
## colado numa cobra que pode devorá-lo no primeiro tick.
const DISTANCIA_SPAWN_MIN: float = 550.0
## Tentativas de reposicionar um spawn ruim antes de aceitar o último ponto.
const TENTATIVAS_SPAWN: int = 20

var config: ConfigPartida
var arena: ArenaModel
var rng: RngService
var bots: BotEngine
var tick_atual: int = 0
var estado: Estado = Estado.EM_ANDAMENTO


func _init(config_: ConfigPartida) -> void:
	config = config_
	rng = RngService.new(config.semente)
	arena = ArenaModel.new(config.tamanho_arena)
	bots = BotEngine.new()

	# Jogador nasce no centro, tamanho 1 (docs §2.1).
	var jogador_: SnakeModel = SnakeModel.new(
		ID_JOGADOR, SnakeModel.Personalidade.JOGADOR, config.tamanho_arena * 0.5)
	arena.adicionar_cobra(jogador_)
	if config.aplicar_buffs:
		_aplicar_buffs(jogador_)
	# Ordem de spawn fixa (fazendeiros → caçadores → oportunistas): faz parte
	# do contrato de determinismo da seed.
	var proximo_id: int = ID_JOGADOR + 1
	proximo_id = _spawn_bots(SnakeModel.Personalidade.FAZENDEIRO, config.fazendeiros, proximo_id)
	proximo_id = _spawn_bots(SnakeModel.Personalidade.CACADOR, config.cacadores, proximo_id)
	proximo_id = _spawn_bots(SnakeModel.Personalidade.OPORTUNISTA, config.oportunistas, proximo_id)
	arena.repor_comida(config.qtd_comida, rng)


## Avança um tick de 60Hz. `direcao_jogador` = intenção do input (joystick);
## Vector2.ZERO mantém o rumo. `turbo_jogador` = botão de turbo segurado.
func avancar(direcao_jogador: Vector2, turbo_jogador: bool = false) -> void:
	if estado != Estado.EM_ANDAMENTO:
		return
	var jogador_: SnakeModel = jogador()
	if direcao_jogador != Vector2.ZERO:
		jogador_.direcao = direcao_jogador.normalized()
	jogador_.quer_turbo = turbo_jogador

	bots.atualizar(tick_atual, arena, rng)
	_resolver_turbo()
	_mover_cobras()
	_registrar_corpos()
	_resolver_comida()
	_resolver_contatos()
	_resolver_cortes()

	tick_atual += 1
	for cobra: SnakeModel in arena.cobras:
		if cobra.viva:
			cobra.ticks_vividos += 1
	if tick_atual % TICKS_POR_SEGUNDO == 0:
		for cobra: SnakeModel in arena.cobras:
			if cobra.viva:
				cobra.pontos += PONTOS_POR_SEGUNDO

	# Fim de partida: tempo esgotado ou morte do jogador (docs §2.1).
	if tick_atual >= config.duracao_seg * TICKS_POR_SEGUNDO or not jogador_.viva:
		estado = Estado.ENCERRADA


func jogador() -> SnakeModel:
	return arena.cobra_por_id(ID_JOGADOR)


func segundos_decorridos() -> float:
	return tick_atual * DELTA


## Posição no ranking da partida (1 = líder), por pontos; empate decide pelo
## menor id (estável e determinístico). Inclui mortas — pontos são mantidos
## ao morrer (docs §2.3).
func posicao_no_ranking(cobra: SnakeModel) -> int:
	var na_frente: int = 0
	for outra: SnakeModel in arena.cobras:
		if outra == cobra:
			continue
		if outra.pontos > cobra.pontos \
				or (outra.pontos == cobra.pontos and outra.id < cobra.id):
			na_frente += 1
	return na_frente + 1


## Pontos por devorar uma vítima do tamanho dado: 100·√tamanho, clamp 100–500.
## Não-linear como a spec pede; vítimas ≥25 já valem o teto.
static func pontos_por_abate(tamanho_vitima: int) -> int:
	return clampi(
		roundi(100.0 * sqrt(float(tamanho_vitima))),
		PONTOS_ABATE_MIN,
		PONTOS_ABATE_MAX,
	)


# ------------------------------------------------------------------ internos


## Aplica os buffs da config ao jogador (docs §2.6.2), com teto por nível.
func _aplicar_buffs(jogador_: SnakeModel) -> void:
	var nv_velocidade: int = clampi(config.nivel_velocidade, 0, NIVEL_MAX_BUFF)
	jogador_.multiplicador_turbo = SnakeModel.TURBO_BASE \
		+ BUFF_VELOCIDADE_POR_NIVEL * nv_velocidade
	var nv_ima: int = clampi(config.nivel_ima, 0, NIVEL_MAX_BUFF)
	if nv_ima > 0:
		jogador_.raio_ima = IMA_RAIO_NIVEL_1 + IMA_RAIO_POR_NIVEL * (nv_ima - 1)
	var nv_pontos: int = clampi(config.nivel_pontos_iniciais, 0, NIVEL_MAX_BUFF)
	jogador_.pontos += BUFF_PONTOS_POR_NIVEL * nv_pontos


## Resolve intenção de turbo → turbo de fato, pelas regras de energia (§2.6):
## ativa com ≥ ENERGIA_MIN_TURBO, permanece até zerar (histerese), regenera
## quando solto.
func _resolver_turbo() -> void:
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva:
			continue
		var pode_ativar: bool = cobra.turbo_ativo or cobra.energia >= ENERGIA_MIN_TURBO
		if cobra.quer_turbo and pode_ativar and cobra.energia > 0.0:
			cobra.turbo_ativo = true
			cobra.energia = maxf(0.0, cobra.energia - CONSUMO_TURBO * DELTA)
			# Epsilon: 100 - 150×(40/60) deixa resíduo de ~1e-15 em float;
			# sem isso o turbo "desligaria" um tick depois do esperado.
			if cobra.energia <= 0.0001:
				cobra.energia = 0.0
				cobra.turbo_ativo = false
		else:
			cobra.turbo_ativo = false
			cobra.energia = minf(SnakeModel.ENERGIA_MAX, cobra.energia + REGEN_TURBO * DELTA)


func _spawn_bots(personalidade: SnakeModel.Personalidade, quantidade: int, primeiro_id: int) -> int:
	var jogador_pos: Vector2 = config.tamanho_arena * 0.5
	var area: Rect2 = arena.limites().grow(-SnakeModel.RAIO_BASE * 4.0)
	for i: int in quantidade:
		var posicao: Vector2 = rng.ponto_no_retangulo(area)
		for tentativa: int in TENTATIVAS_SPAWN:
			if posicao.distance_to(jogador_pos) >= DISTANCIA_SPAWN_MIN:
				break
			posicao = rng.ponto_no_retangulo(area)
		var tamanho_inicial: int
		if personalidade == SnakeModel.Personalidade.CACADOR \
				and config.tamanho_inicial_cacador > 0:
			tamanho_inicial = config.tamanho_inicial_cacador
		else:
			tamanho_inicial = rng.int_entre(config.tamanho_min_bot, config.tamanho_max_bot)
		var bot: SnakeModel = SnakeModel.new(
			primeiro_id + i,
			personalidade,
			posicao,
			tamanho_inicial,
		)
		bot.agressividade = config.agressividade
		bot.multiplicador_turbo = minf(config.turbo_bots, SnakeModel.TURBO_BASE)
		arena.adicionar_cobra(bot)
	return primeiro_id + quantidade


func _mover_cobras() -> void:
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva:
			continue
		cobra.posicao += cobra.direcao * VELOCIDADE * cobra.multiplicador_velocidade() * DELTA
		# Borda é parede: desliza, não mata (decisão: morte por parede
		# invisível frustra o público 7+; se mudar, vire flag de config).
		var r: float = cobra.raio()
		cobra.posicao.x = clampf(cobra.posicao.x, r, arena.tamanho.x - r)
		cobra.posicao.y = clampf(cobra.posicao.y, r, arena.tamanho.y - r)


func _resolver_comida() -> void:
	# Ímã (docs §2.6.2): comida dentro do raio deriva na direção da cobra.
	# A regra é geral, mas hoje só o jogador com buff tem raio_ima > 0.
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva or cobra.raio_ima <= 0.0:
			continue
		var raio2: float = cobra.raio_ima * cobra.raio_ima
		for i: int in arena.comidas.size():
			if cobra.posicao.distance_squared_to(arena.comidas[i]) <= raio2:
				arena.comidas[i] = arena.comidas[i].move_toward(
					cobra.posicao, IMA_VELOCIDADE * DELTA)

	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva:
			continue
		var alcance: float = cobra.raio() + ArenaModel.RAIO_COMIDA
		var alcance2: float = alcance * alcance
		var i: int = 0
		while i < arena.comidas.size():
			if cobra.posicao.distance_squared_to(arena.comidas[i]) <= alcance2:
				arena.comer_comida(i)
				_crescer_com_teto(cobra, CRESCIMENTO_COMIDA)
				cobra.pontos += PONTOS_COMIDA
				cobra.comidas += 1
			else:
				i += 1
	# Reposição imediata mantém a densidade da arena constante.
	arena.repor_comida(config.qtd_comida, rng)


## Atualiza a trilha do corpo de cada cobra (docs §2.7): a cabeça deste tick
## entra na frente; o rabo é aparado no comprimento-alvo do tamanho atual.
func _registrar_corpos() -> void:
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva:
			continue
		cobra.corpo.insert(0, cobra.posicao)
		var alvo: float = cobra.comprimento_corpo()
		var acumulado: float = 0.0
		for i: int in range(1, cobra.corpo.size()):
			acumulado += cobra.corpo[i - 1].distance_to(cobra.corpo[i])
			if acumulado > alvo:
				cobra.corpo.resize(i + 1)
				break


## Corte de corpo (docs §2.7): cabeça encostando no corpo alheio corta ali —
## a vítima encolhe para a fração do ponto do corte e o trecho perdido vira
## comida. Sem pontos; kill continua sendo só pela cabeça.
## Corte livre (aprovado em playtest, 11/08): QUALQUER cobra corta qualquer
## corpo, sem regra de tamanho — o contra-golpe do pequeno contra o líder.
func _resolver_cortes() -> void:
	# Ordem fixa (atacante externo, vítima interno) — determinismo.
	for a: SnakeModel in arena.cobras:
		if not a.viva:
			continue
		for b: SnakeModel in arena.cobras:
			if b == a or not b.viva:
				continue
			if tick_atual < b.protegida_de_corte_ate:
				continue
			var indice: int = _indice_de_corte(a, b)
			if indice > 0:
				_cortar(a, b, indice)


## Índice do ponto do corpo de `b` onde a cabeça de `a` encosta (0 = nenhum).
## Pontos na zona do pescoço não contam — ali vale a colisão cabeça-cabeça.
func _indice_de_corte(a: SnakeModel, b: SnakeModel) -> int:
	var alcance: float = a.raio() + b.raio() * ESPESSURA_CORPO
	var alcance2: float = alcance * alcance
	# Rejeição barata: cabeça de A longe demais até do ponto mais distante
	# possível do corpo de B (cabeça de B + comprimento do corpo).
	var maximo: float = b.comprimento_corpo() + alcance
	if a.posicao.distance_squared_to(b.posicao) > maximo * maximo:
		return 0
	var pescoco: float = b.raio() * SnakeModel.CORPO_ZONA_PESCOCO_RAIOS
	var pescoco2: float = pescoco * pescoco
	for i: int in range(1, b.corpo.size()):
		var ponto: Vector2 = b.corpo[i]
		if b.posicao.distance_squared_to(ponto) < pescoco2:
			continue
		if a.posicao.distance_squared_to(ponto) <= alcance2:
			return i
	return 0


func _cortar(cortadora: SnakeModel, vitima: SnakeModel, indice: int) -> void:
	# Fração do corpo que SOBRA = comprimento até o ponto / comprimento total.
	var ate_o_corte: float = 0.0
	var total: float = 0.0
	for i: int in range(1, vitima.corpo.size()):
		var trecho: float = vitima.corpo[i - 1].distance_to(vitima.corpo[i])
		total += trecho
		if i <= indice:
			ate_o_corte += trecho
	if total <= 0.0:
		return
	var novo_tamanho: int = maxi(1, floori(vitima.tamanho * ate_o_corte / total))
	var perda: int = vitima.tamanho - novo_tamanho
	if perda <= 0:
		return  # corte cosmético no extremo do rabo — nada acontece (§2.7)

	# O trecho perdido vira comida equivalente, espalhada ao longo dele (§2.7).
	var removidos: int = vitima.corpo.size() - indice
	for m: int in perda:
		var passo: int = indice + int(float(removidos - 1) * (float(m) + 0.5) / float(perda))
		arena.comidas.append(vitima.corpo[passo])

	# Só a MASSA cai — nível, visão, velocidade e pontos ficam intactos (§2.7).
	vitima.tamanho = novo_tamanho
	vitima.corpo.resize(indice)
	vitima.protegida_de_corte_ate = tick_atual + PROTECAO_CORTE_TICKS
	vitima.cortes_sofridos += 1
	cortadora.cortes_feitos += 1


func _resolver_contatos() -> void:
	# Pares em ordem fixa de índice — determinismo. Cobra devorada no meio da
	# varredura sai dos pares seguintes pelo check de `viva`.
	for i: int in arena.cobras.size():
		var a: SnakeModel = arena.cobras[i]
		if not a.viva:
			continue
		for j: int in range(i + 1, arena.cobras.size()):
			var b: SnakeModel = arena.cobras[j]
			if not b.viva or not a.viva:
				continue
			var alcance: float = a.raio() + b.raio()
			if a.posicao.distance_squared_to(b.posicao) > alcance * alcance:
				continue
			if a.pode_devorar(b):
				_devorar(a, b)
			elif b.pode_devorar(a):
				_devorar(b, a)
			else:
				_knockback(a, b)


func _devorar(predadora: SnakeModel, vitima: SnakeModel) -> void:
	vitima.viva = false
	vitima.corpo.clear()  # corpo de morta desaparece — não vira comida (§2.7)
	# Pontos pelo NÍVEL (o prestígio de vencer quem evoluiu); crescimento pela
	# MASSA (só se come o que existe fisicamente — vítima raspada rende menos).
	predadora.pontos += pontos_por_abate(vitima.nivel)
	predadora.abates += 1
	_crescer_com_teto(predadora, maxi(1, roundi(vitima.tamanho * FRACAO_CRESCIMENTO_ABATE)))


## Crescimento com o teto de composição aplicado aos BOTS (jogador nunca
## tem teto — a progressão dele é o jogo). O teto vale para as duas réguas.
func _crescer_com_teto(cobra: SnakeModel, quantidade: int) -> void:
	cobra.crescer(quantidade)
	if cobra.eh_jogador():
		return
	var teto: int = config.tamanho_teto_bot
	if cobra.personalidade == SnakeModel.Personalidade.CACADOR \
			and config.tamanho_teto_cacador > 0:
		teto = config.tamanho_teto_cacador
	if teto > 0:
		cobra.tamanho = mini(cobra.tamanho, teto)
		cobra.nivel = mini(cobra.nivel, teto)


## Contato sem devorar (diferença < 10%): as duas se empurram para fora da
## sobreposição, a menor deslocando mais (docs §2.3 — knockback como fuga).
## O limiar de "até 5% menores" da spec está contido neste modelo: qualquer
## par não-devorável se empurra, com força proporcional ao tamanho.
func _knockback(a: SnakeModel, b: SnakeModel) -> void:
	var eixo: Vector2 = a.posicao - b.posicao
	var dist: float = eixo.length()
	var direcao_ab: Vector2 = eixo / dist if dist > 0.0 else Vector2.RIGHT
	var sobreposicao: float = a.raio() + b.raio() - dist
	var total: float = float(a.tamanho + b.tamanho)
	a.posicao += direcao_ab * sobreposicao * (float(b.tamanho) / total)
	b.posicao -= direcao_ab * sobreposicao * (float(a.tamanho) / total)
