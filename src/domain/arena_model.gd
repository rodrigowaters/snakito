class_name ArenaModel
extends RefCounted
## Mapa da partida: limites, comida e lista de cobras. Guarda ESTADO — quem
## aplica regras é o GameEngine; quem decide por bots é o BotEngine.

## Raio de colisão de uma comida, em unidades de mundo.
const RAIO_COMIDA: float = 6.0
## Margem das bordas onde comida não nasce (não força cobras contra a parede).
const MARGEM_SPAWN_COMIDA: float = 40.0

## Dimensões do mundo (retângulo de (0,0) a `tamanho`).
var tamanho: Vector2
## Todas as cobras da partida, vivas e mortas (mortas ficam para o ranking).
## A ORDEM deste array é parte do determinismo — nunca reordenar.
var cobras: Array[SnakeModel] = []
## Posições das comidas ativas.
var comidas: PackedVector2Array = PackedVector2Array()


func _init(tamanho_: Vector2) -> void:
	tamanho = tamanho_


func limites() -> Rect2:
	return Rect2(Vector2.ZERO, tamanho)


func adicionar_cobra(cobra: SnakeModel) -> void:
	cobras.append(cobra)


func cobra_por_id(id: int) -> SnakeModel:
	for cobra: SnakeModel in cobras:
		if cobra.id == id:
			return cobra
	return null


func cobras_vivas() -> Array[SnakeModel]:
	var vivas: Array[SnakeModel] = []
	for cobra: SnakeModel in cobras:
		if cobra.viva:
			vivas.append(cobra)
	return vivas


## Repõe comida até atingir `alvo` itens, em pontos aleatórios do RNG da
## partida (docs §2.4: spawn de comida é seedável).
func repor_comida(alvo: int, rng: RngService) -> void:
	var area: Rect2 = limites().grow(-MARGEM_SPAWN_COMIDA)
	while comidas.size() < alvo:
		comidas.append(rng.ponto_no_retangulo(area))


## Remove a comida no índice (foi comida).
func comer_comida(indice: int) -> void:
	comidas.remove_at(indice)


## Índice da comida mais próxima de `origem` dentro de `alcance`, ou -1.
## `alcance` = raio de visão de quem procura — é o que mantém os bots honestos.
func comida_mais_proxima(origem: Vector2, alcance: float) -> int:
	var melhor_indice: int = -1
	var melhor_dist2: float = alcance * alcance
	for i: int in comidas.size():
		var dist2: float = origem.distance_squared_to(comidas[i])
		if dist2 <= melhor_dist2:
			melhor_dist2 = dist2
			melhor_indice = i
	return melhor_indice
