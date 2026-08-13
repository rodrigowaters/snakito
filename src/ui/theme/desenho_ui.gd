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


## Fantasminha do design (04b/11c): cobra branca esvanecendo com auréola
## dourada, olhos fechados e sorriso sereno. `tamanho` é o retângulo-alvo
## (proporção do viewBox 180×110 do desenho).
static func fantasma(alvo: CanvasItem, tamanho: Vector2) -> void:
	var t: GDScript = preload("res://src/ui/theme/tokens.gd")
	var escala: Vector2 = tamanho / Vector2(180.0, 110.0)
	var branco: Color = t.COR_TEXTO_PRIMARIO
	var corpo: Array[Vector3] = [
		Vector3(40.0, 84.0, 12.0), Vector3(66.0, 74.0, 15.0),
		Vector3(98.0, 64.0, 19.0), Vector3(134.0, 56.0, 24.0),
	]
	var alfas: Array[float] = [0.35, 0.55, 0.8, 1.0]
	for i: int in corpo.size():
		alvo.draw_circle(Vector2(corpo[i].x, corpo[i].y) * escala,
			corpo[i].z * escala.x, Color(branco, alfas[i]))
	var halo_centro: Vector2 = Vector2(134.0, 14.0) * escala
	alvo.draw_set_transform(halo_centro, 0.0, Vector2(1.0, 0.33))
	alvo.draw_arc(Vector2.ZERO, 17.0 * escala.x, 0.0, TAU, 24, t.COR_MOEDA, 4.0)
	alvo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var cabeca: Vector2 = Vector2(134.0, 56.0) * escala
	var raio: float = 24.0 * escala.x
	for lado: float in [-1.0, 1.0]:
		alvo.draw_arc(cabeca + Vector2(lado * raio * 0.3, -raio * 0.2),
			raio * 0.15, deg_to_rad(20.0), deg_to_rad(160.0), 8,
			t.COR_APP_FUNDO_INICIO, 3.0)
	alvo.draw_arc(cabeca + Vector2(0.0, raio * 0.35), raio * 0.26,
		deg_to_rad(35.0), deg_to_rad(145.0), 10, t.COR_APP_FUNDO_INICIO, 3.2)


## Ícone da Evolução (emoji ⬆️ do design, desenhado — U+FE0F rende glifo
## monocromático): seta branca em quadrado azul arredondado.
static func icone_evolucao(alvo: CanvasItem, caixa: Rect2) -> void:
	var t: GDScript = preload("res://src/ui/theme/tokens.gd")
	var lado: float = caixa.size.y
	alvo.draw_colored_polygon(
		poligono_arredondado(caixa, lado * 0.28), t.CORES_COBRA_BASE[1])
	var centro: Vector2 = caixa.get_center()
	var s: float = lado * 0.5
	var seta: PackedVector2Array = PackedVector2Array([
		centro + Vector2(0.0, -s * 0.5),
		centro + Vector2(s * 0.45, -s * 0.02),
		centro + Vector2(s * 0.18, -s * 0.02),
		centro + Vector2(s * 0.18, s * 0.5),
		centro + Vector2(-s * 0.18, s * 0.5),
		centro + Vector2(-s * 0.18, -s * 0.02),
		centro + Vector2(-s * 0.45, -s * 0.02),
	])
	alvo.draw_colored_polygon(seta, t.COR_SIMBOLO_DALTONISMO)


## Moedinha do design (🪙 rende monocromático): anel escuro, miolo dourado
## e brilho no topo-esquerda.
static func moedinha(alvo: CanvasItem, centro: Vector2, raio: float) -> void:
	var t: GDScript = preload("res://src/ui/theme/tokens.gd")
	alvo.draw_circle(centro, raio, t.COR_MOEDA_BORDA)
	alvo.draw_circle(centro, raio * 0.72, t.COR_MOEDA)
	alvo.draw_arc(centro, raio * 0.5, deg_to_rad(160.0), deg_to_rad(280.0), 10,
		Color(t.COR_MOEDA.lightened(0.45), 0.9), maxf(1.5, raio * 0.18))


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
