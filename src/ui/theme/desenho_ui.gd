class_name DesenhoUi
extends RefCounted
## Desenhos que o StyleBoxFlat não faz (M2, fidelidade ao Claude Design):
## polígono de retângulo arredondado e preenchimento em gradiente diagonal
## com cor por vértice. Usado pela Home e pelo HUD; cores SEMPRE de tokens.

## Segmentos por canto do polígono arredondado.
const ARCO_PASSOS: int = 8


## Contorno de retângulo arredondado como polígono.
static func poligono_arredondado(rect: Rect2, raio: float) -> PackedVector2Array:
	var pontos: PackedVector2Array = PackedVector2Array()
	var cantos: Array[Vector2] = [
		rect.position + Vector2(raio, raio),
		Vector2(rect.end.x - raio, rect.position.y + raio),
		rect.end - Vector2(raio, raio),
		Vector2(rect.position.x + raio, rect.end.y - raio),
	]
	for canto: int in 4:
		var inicio: float = PI + PI * 0.5 * canto
		for passo: int in ARCO_PASSOS + 1:
			var angulo: float = inicio + PI * 0.5 * float(passo) / float(ARCO_PASSOS)
			pontos.append(cantos[canto] + Vector2(cos(angulo), sin(angulo)) * raio)
	return pontos


## Retângulo arredondado preenchido por gradiente diagonal (135° do design):
## polígono com cor POR VÉRTICE.
static func gradiente_arredondado(
	alvo: CanvasItem,
	tamanho: Vector2,
	raio: float,
	cor_a: Color,
	cor_b: Color,
) -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, tamanho)
	var pontos: PackedVector2Array = poligono_arredondado(rect, raio)
	var cores: PackedColorArray = PackedColorArray()
	var diagonal: float = tamanho.x + tamanho.y
	for ponto: Vector2 in pontos:
		cores.append(cor_a.lerp(cor_b, (ponto.x + ponto.y) / diagonal))
	alvo.draw_polygon(pontos, cores)
