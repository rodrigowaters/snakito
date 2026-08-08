class_name RngService
extends RefCounted
## RNG seedável centralizado — TODA aleatoriedade do domínio passa por aqui
## (regra dura #2 do CLAUDE.md). Mesma seed = mesma partida: desafios
## reproduzíveis e botão "Repetir esta arena".
##
## Nunca use `randf()`/`randi()` globais dentro do domínio: eles quebram o
## determinismo silenciosamente.

## Seed desta instância — exibida na tela de resultado ("Repetir esta arena").
var semente: int

var _rng: RandomNumberGenerator


func _init(semente_inicial: int) -> void:
	semente = semente_inicial
	_rng = RandomNumberGenerator.new()
	_rng.seed = semente_inicial


## Float uniforme em [0, 1).
func float_unitario() -> float:
	return _rng.randf()


## Float uniforme em [minimo, maximo].
func float_entre(minimo: float, maximo: float) -> float:
	return _rng.randf_range(minimo, maximo)


## Inteiro uniforme em [minimo, maximo] (inclusivo).
func int_entre(minimo: int, maximo: int) -> int:
	return _rng.randi_range(minimo, maximo)


## Vetor unitário em direção uniforme.
func direcao_unitaria() -> Vector2:
	return Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))


## Ponto uniforme dentro do retângulo.
func ponto_no_retangulo(retangulo: Rect2) -> Vector2:
	return Vector2(
		_rng.randf_range(retangulo.position.x, retangulo.end.x),
		_rng.randf_range(retangulo.position.y, retangulo.end.y),
	)


## Seed nova para o modo Arcade. Usa o RNG global de propósito: é o ÚNICO
## ponto legítimo de aleatoriedade não-seedável (escolher a seed da partida).
static func semente_aleatoria() -> int:
	return randi()
