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


## Decide a direção de um bot AGORA (exposta para testes de personalidade).
func decidir(bot: SnakeModel, arena: ArenaModel, rng: RngService) -> Vector2:
	# Fugir de quem pode nos devorar tem prioridade máxima em TODAS as
	# personalidades — bot que não foge não ensina risco/recompensa, só morre.
	var ameaca: SnakeModel = ameaca_mais_proxima(bot, arena)
	if ameaca != null:
		var fuga: Vector2 = bot.posicao - ameaca.posicao
		return fuga.normalized() if fuga != Vector2.ZERO else Vector2.RIGHT

	match bot.personalidade:
		SnakeModel.Personalidade.CACADOR:
			var alcance_caca: float = bot.raio_visao() \
				* (CACA_BASE + CACA_POR_AGRESSIVIDADE * bot.agressividade)
			var presa: SnakeModel = presa_mais_proxima(bot, arena, alcance_caca)
			if presa != null:
				return (presa.posicao - bot.posicao).normalized()
		SnakeModel.Personalidade.OPORTUNISTA:
			var alcance_oportunidade: float = bot.raio_visao() \
				* (OPORTUNIDADE_BASE + OPORTUNIDADE_POR_AGRESSIVIDADE * bot.agressividade)
			var presa: SnakeModel = presa_mais_proxima(bot, arena, alcance_oportunidade)
			if presa != null:
				return (presa.posicao - bot.posicao).normalized()

	# Fazendeiro sempre cai aqui; Caçador/Oportunista caem sem presa à vista.
	return _rumo_comida_ou_vagueio(bot, arena, rng)


## Cobra viva mais próxima que PODE DEVORAR o bot, dentro da visão dele.
func ameaca_mais_proxima(bot: SnakeModel, arena: ArenaModel) -> SnakeModel:
	return _mais_proxima(bot, arena, bot.raio_visao(),
		func(outra: SnakeModel) -> bool: return outra.pode_devorar(bot))


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
