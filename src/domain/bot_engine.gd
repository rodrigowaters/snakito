class_name BotEngine
extends RefCounted
## Decisão de direção dos bots, por tick. Três personalidades (docs §2.4):
## Fazendeiro (foge e farma), Caçador (persegue menores), Oportunista
## (farma, mas ataca vulneráveis que cruzam o caminho).
##
## BOTS HONESTOS (regra dura #3):
## 1. Só enxergam o que está dentro do próprio `raio_visao()` — nada de ver
##    através da névoa.
## 2. Só decidem a cada `TICKS_REACAO` ticks (100ms a 60Hz) — nada de reação
##    sobre-humana. Entre decisões, mantêm o rumo.
## A dificuldade vem da COMPOSIÇÃO da arena (quantidade, tamanho inicial,
## agressividade), nunca de trapaça.

## Intervalo entre decisões (6 ticks a 60Hz = 100ms — reação humana plausível).
## As decisões são escalonadas por id para os bots não virarem em sincronia.
const TICKS_REACAO: int = 6
## Chance de trocar o rumo de vagueio a cada decisão sem estímulo.
const CHANCE_MUDAR_VAGUEIO: float = 0.15
## Distância da borda em que o bot passa a rumar para o centro.
const MARGEM_BORDA: float = 150.0
## Alcance de caça do Caçador: fração da visão = base + ganho × agressividade.
const CACA_BASE: float = 0.6
const CACA_POR_AGRESSIVIDADE: float = 0.4
## Alcance de ataque do Oportunista (bem menor: ele só ataca quem "cruza o
## caminho"; farmar é o comportamento padrão).
const OPORTUNIDADE_BASE: float = 0.35
const OPORTUNIDADE_POR_AGRESSIVIDADE: float = 0.4

## Coragem por personalidade (§2.7, playtest 11/08: "se atacarem as caudas
## podem se alimentar e ficar do mesmo nível"): fração da visão em que um
## devorador À VISTA vira motivo de fuga. Fazendeiro foge ao avistar (1.0);
## caçador e oportunista toleram cabeça superior distante — é a janela em
## que colhem o rabo dos grandes. Honesto: a coragem não enxerga mais longe,
## só foge mais tarde (e às vezes paga com a vida).
const MEDO_FAZENDEIRO: float = 1.0
const MEDO_CACADOR: float = 0.6
const MEDO_OPORTUNISTA: float = 0.75

## Rumo de vagueio corrente por id de bot (memória entre decisões).
var _vagueio: Dictionary[int, Vector2] = {}


## Atualiza a direção dos bots cuja vez de decidir chegou neste tick.
## Percorre `arena.cobras` em ordem — parte do contrato de determinismo.
func atualizar(tick: int, arena: ArenaModel, rng: RngService) -> void:
	for cobra: SnakeModel in arena.cobras:
		if not cobra.viva or cobra.eh_jogador():
			continue
		if (tick + cobra.id) % TICKS_REACAO != 0:
			continue
		cobra.direcao = decidir(cobra, arena, rng)


## Decide a direção — e a INTENÇÃO de turbo (docs §2.6) — de um bot AGORA.
## Turbo: liga ao fugir (todas as personalidades) e ao caçar; farmar/vaguear
## não gasta energia. Quem resolve a intenção contra as regras de energia é
## o GameEngine, com as MESMAS regras do jogador (bots honestos).
func decidir(bot: SnakeModel, arena: ArenaModel, rng: RngService) -> Vector2:
	# Fugir de quem pode nos devorar tem prioridade máxima em TODAS as
	# personalidades — bot que não foge não ensina risco/recompensa, só morre.
	var ameaca: SnakeModel = ameaca_mais_proxima(bot, arena)
	if ameaca != null:
		bot.quer_turbo = true
		var fuga: Vector2 = bot.posicao - ameaca.posicao
		return fuga.normalized() if fuga != Vector2.ZERO else Vector2.RIGHT
	bot.quer_turbo = false

	match bot.personalidade:
		SnakeModel.Personalidade.CACADOR:
			var alcance_caca: float = bot.raio_visao() \
				* (CACA_BASE + CACA_POR_AGRESSIVIDADE * bot.agressividade)
			var presa: SnakeModel = presa_mais_proxima(bot, arena, alcance_caca)
			if presa != null:
				bot.quer_turbo = true
				return (ponto_de_ataque(bot, presa) - bot.posicao).normalized()
			# Sem presa devorável: colher rabo (até de superiores — a cabeça
			# deles está fora do raio de medo, senão estaríamos fugindo).
			var rabo_caca: Vector2 = _rabo_mais_proximo(bot, arena, alcance_caca)
			if rabo_caca != Vector2.INF:
				bot.quer_turbo = true
				return (rabo_caca - bot.posicao).normalized()
		SnakeModel.Personalidade.OPORTUNISTA:
			var alcance_oportunidade: float = bot.raio_visao() \
				* (OPORTUNIDADE_BASE + OPORTUNIDADE_POR_AGRESSIVIDADE * bot.agressividade)
			var presa: SnakeModel = presa_mais_proxima(bot, arena, alcance_oportunidade)
			if presa != null:
				bot.quer_turbo = true
				return (ponto_de_ataque(bot, presa) - bot.posicao).normalized()
			# Corte livre (§2.7 em teste): sem presa devorável, colher o rabo
			# de QUALQUER cobra é oportunidade — inclusive do líder gigante.
			# Honesto por construção: se um devorador está com a cabeça
			# dentro da visão, a fuga (acima) já decidiu — chegar aqui
			# significa que só há rabo "seguro" por perto.
			var rabo: Vector2 = _rabo_mais_proximo(bot, arena, alcance_oportunidade)
			if rabo != Vector2.INF:
				bot.quer_turbo = true
				return (rabo - bot.posicao).normalized()

	# Fazendeiro sempre cai aqui; Caçador/Oportunista caem sem presa à vista.
	return _rumo_comida_ou_vagueio(bot, arena, rng)


## Ponto de ataque na presa: o mais próximo entre cabeça e corpo (docs §2.7 —
## cortar o rabo é caça válida e mais segura que mirar a cabeça). Corpo
## amostrado com passo largo: decisão de 100ms não precisa de precisão de tick.
func ponto_de_ataque(bot: SnakeModel, presa: SnakeModel) -> Vector2:
	var melhor: Vector2 = presa.posicao
	var melhor_dist2: float = bot.posicao.distance_squared_to(presa.posicao)
	var i: int = 4
	while i < presa.corpo.size():
		var dist2: float = bot.posicao.distance_squared_to(presa.corpo[i])
		if dist2 < melhor_dist2:
			melhor_dist2 = dist2
			melhor = presa.corpo[i]
		i += 4
	return melhor


## Ponto de corpo alheio mais próximo dentro de `alcance` (corte livre, §2.7
## em teste). Vector2.INF = nenhum. Pula a zona do pescoço da dona (lá é
## colisão de cabeça, não corte).
func _rabo_mais_proximo(bot: SnakeModel, arena: ArenaModel, alcance: float) -> Vector2:
	var melhor: Vector2 = Vector2.INF
	var melhor_dist2: float = alcance * alcance
	for outra: SnakeModel in arena.cobras:
		if outra == bot or not outra.viva:
			continue
		var pescoco: float = outra.raio() * SnakeModel.CORPO_ZONA_PESCOCO_RAIOS
		var pescoco2: float = pescoco * pescoco
		var i: int = 4
		while i < outra.corpo.size():
			var ponto: Vector2 = outra.corpo[i]
			i += 4
			if outra.posicao.distance_squared_to(ponto) < pescoco2:
				continue
			var dist2: float = bot.posicao.distance_squared_to(ponto)
			if dist2 < melhor_dist2:
				melhor_dist2 = dist2
				melhor = ponto
	return melhor


## Cobra viva mais próxima que PODE DEVORAR o bot, dentro do raio de MEDO
## dele (fração da visão que depende da coragem da personalidade).
func ameaca_mais_proxima(bot: SnakeModel, arena: ArenaModel) -> SnakeModel:
	return _mais_proxima(bot, arena, bot.raio_visao() * _fracao_medo(bot),
		func(outra: SnakeModel) -> bool: return outra.pode_devorar(bot))


func _fracao_medo(bot: SnakeModel) -> float:
	match bot.personalidade:
		SnakeModel.Personalidade.CACADOR:
			return MEDO_CACADOR
		SnakeModel.Personalidade.OPORTUNISTA:
			return MEDO_OPORTUNISTA
		_:
			return MEDO_FAZENDEIRO


## Cobra viva mais próxima que o bot pode devorar, dentro de `alcance`.
func presa_mais_proxima(bot: SnakeModel, arena: ArenaModel, alcance: float) -> SnakeModel:
	return _mais_proxima(bot, arena, alcance,
		func(outra: SnakeModel) -> bool: return bot.pode_devorar(outra))


func _mais_proxima(
	bot: SnakeModel,
	arena: ArenaModel,
	alcance: float,
	criterio: Callable,
) -> SnakeModel:
	var melhor: SnakeModel = null
	var melhor_dist2: float = alcance * alcance
	for outra: SnakeModel in arena.cobras:
		if outra == bot or not outra.viva:
			continue
		if not criterio.call(outra):
			continue
		var dist2: float = bot.posicao.distance_squared_to(outra.posicao)
		if dist2 <= melhor_dist2:
			melhor_dist2 = dist2
			melhor = outra
	return melhor


## Rumo à comida visível mais próxima; sem comida à vista, vagueia.
func _rumo_comida_ou_vagueio(bot: SnakeModel, arena: ArenaModel, rng: RngService) -> Vector2:
	var indice: int = arena.comida_mais_proxima(bot.posicao, bot.raio_visao())
	if indice >= 0:
		var rumo: Vector2 = arena.comidas[indice] - bot.posicao
		if rumo != Vector2.ZERO:
			return rumo.normalized()
	return _vaguear(bot, arena, rng)


func _vaguear(bot: SnakeModel, arena: ArenaModel, rng: RngService) -> Vector2:
	# Perto da borda, rumar ao centro — evita bots "presos" na parede.
	var limites: Rect2 = arena.limites().grow(-MARGEM_BORDA)
	if not limites.has_point(bot.posicao):
		var para_centro: Vector2 = arena.tamanho * 0.5 - bot.posicao
		if para_centro != Vector2.ZERO:
			_vagueio[bot.id] = para_centro.normalized()
			return _vagueio[bot.id]
	if not _vagueio.has(bot.id) or rng.float_unitario() < CHANCE_MUDAR_VAGUEIO:
		_vagueio[bot.id] = rng.direcao_unitaria()
	return _vagueio[bot.id]
