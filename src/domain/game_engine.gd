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
## Velocidade de toda cobra, em unidades/segundo (constante: docs não prevê
## boost no MVP — §4.2 o marca como opcional).
const VELOCIDADE: float = 180.0

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
	var qtd_comida: int = 80
	var fazendeiros: int = 12
	var cacadores: int = 6
	var oportunistas: int = 12
	var tamanho_min_bot: int = 1
	var tamanho_max_bot: int = 8
	var agressividade: float = 0.5

	static func padrao(semente_: int) -> ConfigPartida:
		var config: ConfigPartida = ConfigPartida.new()
		config.semente = semente_
		return config


## Distância mínima de spawn de bot em relação ao jogador — ninguém nasce
## colado numa cobra que pode devorá-lo no primeiro tick.
const DISTANCIA_SPAWN_MIN: float = 400.0
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
	arena.adicionar_cobra(SnakeModel.new(
		ID_JOGADOR, SnakeModel.Personalidade.JOGADOR, config.tamanho_arena * 0.5
	))
	# Ordem de spawn fixa (fazendeiros → caçadores → oportunistas): faz parte
	# do contrato de determinismo da seed.
	var proximo_id: int = ID_JOGADOR + 1
	proximo_id = _spawn_bots(SnakeModel.Personalidade.FAZENDEIRO, config.fazendeiros, proximo_id)
	proximo_id = _spawn_bots(SnakeModel.Personalidade.CACADOR, config.cacadores, proximo_id)
	proximo_id = _spawn_bots(SnakeModel.Personalidade.OPORTUNISTA, config.oportunistas, proximo_id)
	arena.repor_comida(config.qtd_comida, rng)


## Avança um tick de 60Hz. `direcao_jogador` = intenção do input (joystick);
## Vector2.ZERO mantém o rumo atual.
func avancar(direcao_jogador: Vector2) -> void:
	if estado != Estado.EM_ANDAMENTO:
		return
	var jogador_: SnakeModel = jogador()
	if direcao_jogador != Vector2.ZERO:
		jogador_.direcao = direcao_jogador.normalized()

	bots.atualizar(tick_atual, arena, rng)
	_mover_cobras()
	_resolver_comida()
	_resolver_contatos()

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


func _spawn_bots(personalidade: SnakeModel.Personalidade, quantidade: int, primeiro_id: int) -> int:
	var jogador_pos: Vector2 = config.tamanho_arena * 0.5
	var area: Rect2 = arena.limites().grow(-SnakeModel.RAIO_BASE * 4.0)
	for i: int in quantidade:
		var posicao: Vector2 = rng.ponto_no_retangulo(area)
		for tentativa: int in TENTATIVAS_SPAWN:
			if posicao.distance_to(jogador_pos) >= DISTANCIA_SPAWN_MIN:
				break
			posicao = rng.ponto_no_retangulo(area)
		var bot: SnakeModel = SnakeModel.new(
			primeiro_id + i,
			personalidade,
			posicao,
			rng.int_entre(config.tamanho_min_bot, config.tamanho_max_bot),
		)
		bot.agressividade = config.agressividade
		arena.adicionar_cobra(bot)
	return primeiro_id + quantidade


func _mover_cobras() -> void:
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva:
			continue
		cobra.posicao += cobra.direcao * VELOCIDADE * DELTA
		# Borda é parede: desliza, não mata (decisão: morte por parede
		# invisível frustra o público 7+; se mudar, vire flag de config).
		var r: float = cobra.raio()
		cobra.posicao.x = clampf(cobra.posicao.x, r, arena.tamanho.x - r)
		cobra.posicao.y = clampf(cobra.posicao.y, r, arena.tamanho.y - r)


func _resolver_comida() -> void:
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva:
			continue
		var alcance: float = cobra.raio() + ArenaModel.RAIO_COMIDA
		var alcance2: float = alcance * alcance
		var i: int = 0
		while i < arena.comidas.size():
			if cobra.posicao.distance_squared_to(arena.comidas[i]) <= alcance2:
				arena.comer_comida(i)
				cobra.crescer(CRESCIMENTO_COMIDA)
				cobra.pontos += PONTOS_COMIDA
				cobra.comidas += 1
			else:
				i += 1
	# Reposição imediata mantém a densidade da arena constante.
	arena.repor_comida(config.qtd_comida, rng)


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
	predadora.pontos += pontos_por_abate(vitima.tamanho)
	predadora.abates += 1
	predadora.crescer(maxi(1, roundi(vitima.tamanho * FRACAO_CRESCIMENTO_ABATE)))


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
