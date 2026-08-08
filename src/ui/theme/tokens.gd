## Tokens de design do Snakito — fonte única de valores visuais.
##
## REGRA DURA (CLAUDE.md §Arquitetura.4): nenhuma cor, fonte, espaçamento, raio
## ou alvo de toque pode ser escrito literalmente fora deste arquivo e de
## `snakito_theme.tres`. Cenas e scripts consomem SEMPRE as constantes daqui.
##
## Origem: `docs/design/snakito-tokens.json` (export do Claude Design v1.0,
## projeto "Design System Snakito"). Ao atualizar o design, reimporte o JSON e
## reescreva este arquivo — não edite valores à mão sem atualizar a fonte.
##
## Contraste: todos os pares texto/fundo abaixo foram validados em WCAG 2.1 AA
## (relatório em `docs/design/wcag-report.md`). 0 reprovações.
class_name SnakitoTokens
extends RefCounted


# ==============================================================================
# 1 · CORES — ARENA
# ==============================================================================

## Fundo padrão da arena de jogo.
const COR_ARENA_FUNDO: Color = Color("#131624")
## Linhas da grade da arena. Alpha baixo de propósito: guia sutil, não decoração.
const COR_ARENA_GRADE: Color = Color(1.0, 1.0, 1.0, 0.04)
## Lado da célula da grade, em dp.
const ARENA_GRADE_TAMANHO: int = 26
## Fundo da arena no modo duelo (confronto direto com o chefe).
const COR_ARENA_DUELO_FUNDO: Color = Color("#0F2233")
## Grade da arena de duelo — tom azulado para diferenciar do modo normal.
const COR_ARENA_DUELO_GRADE: Color = Color(Color("#8ADCFF"), 0.06)


# ==============================================================================
# 2 · CORES — FUNDO DO APP E SUPERFÍCIES
# ==============================================================================

## Início do gradiente de fundo do app (telas fora da arena).
const COR_APP_FUNDO_INICIO: Color = Color("#12141F")
## Fim do gradiente de fundo do app.
const COR_APP_FUNDO_FIM: Color = Color("#191430")
## Ângulo do gradiente de fundo, em graus.
const APP_FUNDO_ANGULO: float = 160.0

## Superfície nível 1 — cards, pílulas, modais.
const COR_SUPERFICIE_1: Color = Color("#1B1F30")
## Superfície nível 2 — botão secundário sólido, chips inativos.
const COR_SUPERFICIE_2: Color = Color("#232841")
## Preenchimento "vidro" sobre o gradiente do app.
const COR_SUPERFICIE_VIDRO: Color = Color(1.0, 1.0, 1.0, 0.06)
## Borda do vidro — dá o recorte que o preenchimento sozinho não dá.
const COR_SUPERFICIE_VIDRO_BORDA: Color = Color(1.0, 1.0, 1.0, 0.12)
## Vidro no estado pressionado — reduz o alpha (um véu branco não tem
## "tom mais escuro"; escurecer seria pintar de cinza).
const COR_SUPERFICIE_VIDRO_PRESS: Color = Color(1.0, 1.0, 1.0, 0.04)
## Fundo de card de conteúdo sobre o gradiente do app.
const COR_CARD_FUNDO: Color = Color(1.0, 1.0, 1.0, 0.05)
## Borda de card de conteúdo.
const COR_CARD_BORDA: Color = Color(1.0, 1.0, 1.0, 0.10)
## Fundo de controle desabilitado.
const COR_FUNDO_DESABILITADO: Color = Color(1.0, 1.0, 1.0, 0.04)
## Faixa do HUD sobreposta à arena; escurece o fundo sem escondê-lo.
const COR_SUPERFICIE_HUD: Color = Color(Color("#0E1018"), 0.78)
## Fundo de modal (opaco, para não competir com o conteúdo atrás).
const COR_SUPERFICIE_MODAL: Color = Color("#1B1F30")


# ==============================================================================
# 3 · CORES — COBRAS (8 skins-base)
# ==============================================================================

## Identidade de cor de uma cobra. Use SEMPRE este enum como índice —
## os arrays abaixo estão na mesma ordem.
enum CorCobra {
	VERDE,
	AZUL,
	ROSA,
	AMARELA,
	LARANJA,
	ROXA,
	TURQUESA,
	LIMA,
}

## Total de cores de cobra disponíveis.
const TOTAL_CORES_COBRA: int = 8

## Cor base do corpo, indexada por `CorCobra`.
const CORES_COBRA_BASE: Array[Color] = [
	Color("#4ADE80"),  # verde     · 10.32:1 vs arena
	Color("#38BDF8"),  # azul      ·  8.39:1 vs arena
	Color("#F472B6"),  # rosa      ·  6.79:1 vs arena
	Color("#FFD43B"),  # amarela   · 12.61:1 vs arena
	Color("#FF9F45"),  # laranja   ·  8.82:1 vs arena
	Color("#A78BFA"),  # roxa      ·  6.61:1 vs arena
	Color("#2DD4BF"),  # turquesa  ·  9.66:1 vs arena
	Color("#BEF264"),  # lima      · 13.76:1 vs arena
]

## Tom escuro de cada cobra — contorno dos segmentos e sombra "de brinquedo".
const CORES_COBRA_ESCURA: Array[Color] = [
	Color("#2CA35B"),  # verde
	Color("#1E88BF"),  # azul
	Color("#C24A87"),  # rosa
	Color("#C9A11C"),  # amarela
	Color("#C86F1F"),  # laranja
	Color("#7757CE"),  # roxa
	Color("#1B9A8A"),  # turquesa
	Color("#8CB93A"),  # lima
]


# ==============================================================================
# 4 · MODO DALTONISMO — símbolos geométricos
# ==============================================================================

## Símbolo geométrico único por cor de cobra. Existe porque a distinção entre
## as cobras é de matiz, não de luminância: os pares mais próximos ficam em
## ~1.03:1 de contraste relativo (rosa×roxa), o que é indistinguível para
## parte dos jogadores daltônicos. O símbolo é o canal redundante obrigatório.
enum SimboloDaltonismo {
	CIRCULO,
	TRIANGULO,
	QUADRADO,
	LOSANGO,
	ESTRELA,
	HEXAGONO,
	CRUZ,
	MEIA_LUA,
}

## Símbolo de cada cobra, indexado por `CorCobra`. Valores são `SimboloDaltonismo`.
## Tipado como Array[int] porque GDScript não aceita arrays tipados por enum.
const SIMBOLOS_COBRA: Array[int] = [
	SimboloDaltonismo.CIRCULO,    # verde
	SimboloDaltonismo.TRIANGULO,  # azul
	SimboloDaltonismo.QUADRADO,   # rosa
	SimboloDaltonismo.LOSANGO,    # amarela
	SimboloDaltonismo.ESTRELA,    # laranja
	SimboloDaltonismo.HEXAGONO,   # roxa
	SimboloDaltonismo.CRUZ,       # turquesa
	SimboloDaltonismo.MEIA_LUA,   # lima
]

## Cor de preenchimento do símbolo — sempre branco, sobre qualquer cobra.
const COR_SIMBOLO_DALTONISMO: Color = Color("#FFFFFF")
## Traço escuro de apoio, para o símbolo não sumir nas cobras claras (lima, amarela).
const COR_SIMBOLO_DALTONISMO_TRACO: Color = Color(Color("#12141F"), 0.55)
## O símbolo é estampado na cabeça e a cada N segmentos.
const SIMBOLO_INTERVALO_SEGMENTOS: int = 3
## Fração do diâmetro do segmento ocupada pelo símbolo.
const SIMBOLO_ESCALA: float = 0.62

## Diretório dos assets SVG dos símbolos (gerados a partir de `docs/design`).
const DIR_SIMBOLOS_DALTONISMO: String = "res://assets/daltonismo/"
## Nome do arquivo de cada símbolo, indexado por `SimboloDaltonismo`.
const ARQUIVOS_SIMBOLO: Array[String] = [
	"circulo", "triangulo", "quadrado", "losango",
	"estrela", "hexagono", "cruz", "meia_lua",
]


# ==============================================================================
# 5 · CORES — COMIDA
# ==============================================================================

## Comida comum (+1 segmento).
const COR_COMIDA_COMUM: Color = Color("#FF6B6B")
## Brilho/realce da comida comum (pulso de atenção).
const COR_COMIDA_COMUM_REALCE: Color = Color("#FF9B9B")
## Comida premium (multiplicador de pontos).
const COR_COMIDA_PREMIUM: Color = Color("#FFD43B")


# ==============================================================================
# 6 · CORES — SEMÂNTICAS
# ==============================================================================

## Sucesso: fase concluída, item equipado, confirmação.
const COR_SUCESSO: Color = Color("#4ADE80")
## Perigo como AÇÃO (borda/fundo de botão destrutivo). Não usar como texto pequeno.
const COR_PERIGO_ACAO: Color = Color("#FF6B6B")
## Perigo como TEXTO (mensagens de erro) — clareado para passar AA em corpo 13px.
const COR_PERIGO_TEXTO: Color = Color("#FF9B9B")
## Fundo do botão destrutivo (véu do vermelho de ação).
const COR_PERIGO_FUNDO: Color = Color(Color("#FF6B6B"), 0.14)
## Borda do botão destrutivo.
const COR_PERIGO_BORDA: Color = Color(Color("#FF6B6B"), 0.4)
## Alerta: tempo esgotando, saldo insuficiente.
const COR_ALERTA: Color = Color("#FFD43B")
## Informação: dicas estratégicas do analisador.
const COR_INFO: Color = Color("#8ADCFF")
## Oferta de anúncio recompensado. Cor exclusiva — nunca reutilizar em UI neutra,
## para a criança distinguir "isto é um anúncio" de "isto é o jogo".
const COR_OFERTA_ANUNCIO: Color = Color("#FF9F45")


# ==============================================================================
# 7 · CORES — TEXTO
# ==============================================================================

## Texto principal.
const COR_TEXTO_PRIMARIO: Color = Color("#F4F6FF")
## Texto secundário (subtítulos, descrições).
const COR_TEXTO_SECUNDARIO: Color = Color("#A6AECB")
## Texto de apoio. RESTRIÇÃO DE USO: sobre vidro em cima de superfície/1 esta cor
## fica em 3.93:1 — passa o 3.0:1 de "texto grande", reprova o 4.5:1 de texto
## normal. Logo só pode ser usada em tamanho de texto grande (ver constantes
## abaixo). Em qualquer outro tamanho, use `COR_TEXTO_SECUNDARIO` (6.28:1 no
## pior caso).
const COR_TEXTO_MUTED: Color = Color("#7E88A8")
## Tamanho mínimo (px) para `COR_TEXTO_MUTED` EM NEGRITO (peso ≥ 700).
## WCAG 2.1 define texto grande em negrito como ≥ 14pt = 18.66px; arredondamos
## para cima para não ficar na fronteira.
const TAM_MIN_TEXTO_MUTED_BOLD: int = 19
## Tamanho mínimo (px) para `COR_TEXTO_MUTED` em peso normal. WCAG 2.1: ≥ 18pt.
const TAM_MIN_TEXTO_MUTED_REGULAR: int = 24

## Texto sobre o CTA primário (verde).
const COR_TEXTO_SOBRE_PRIMARIO: Color = Color("#0B2416")
## Texto sobre superfícies âmbar (badge lendária, CTA VIP).
const COR_TEXTO_SOBRE_ALERTA: Color = Color("#3A2E00")
## Texto sobre o CTA de anúncio (laranja).
const COR_TEXTO_SOBRE_OFERTA_ANUNCIO: Color = Color("#3A1F00")


# ==============================================================================
# 8 · CORES — CTAs (gradientes)
# ==============================================================================
# Godot não desenha gradiente em StyleBoxFlat. O tema usa o TOM MÉDIO como
# aproximação sólida; o gradiente real exige StyleBoxTexture ou shader.
# Ambas as pontas e o tom médio passam AA contra o texto correspondente.

## CTA primário — início do gradiente.
const COR_CTA_PRIMARIO_INICIO: Color = Color("#4ADE80")
## CTA primário — fim do gradiente.
const COR_CTA_PRIMARIO_FIM: Color = Color("#2FBF8F")
## CTA primário — tom médio sólido (fallback do tema). 8.12:1 vs texto.
const COR_CTA_PRIMARIO_MEDIO: Color = Color("#3CCE88")

## CTA de anúncio — início do gradiente.
const COR_CTA_ANUNCIO_INICIO: Color = Color("#FF9F45")
## CTA de anúncio — fim do gradiente.
const COR_CTA_ANUNCIO_FIM: Color = Color("#F5893B")
## CTA de anúncio — tom médio sólido. 6.81:1 vs texto.
const COR_CTA_ANUNCIO_MEDIO: Color = Color("#FA9440")

## CTA VIP — início do gradiente.
const COR_CTA_VIP_INICIO: Color = Color("#FFD43B")
## CTA VIP — fim do gradiente.
const COR_CTA_VIP_FIM: Color = Color("#FF9F45")
## CTA VIP — tom médio sólido. 7.86:1 vs texto.
const COR_CTA_VIP_MEDIO: Color = Color("#FFBA40")

## Ângulo dos gradientes de CTA, em graus.
const CTA_GRADIENTE_ANGULO: float = 135.0


# ==============================================================================
# 9 · CORES — RARIDADE DE SKIN
# ==============================================================================

## Raridade de uma skin da loja.
enum Raridade { COMUM, RARA, EPICA, LENDARIA }

## Cor de cada raridade, indexada por `Raridade`.
const CORES_RARIDADE: Array[Color] = [
	Color("#A6AECB"),  # comum
	Color("#38BDF8"),  # rara
	Color("#A78BFA"),  # épica
	Color("#FFD43B"),  # lendária
]


# ==============================================================================
# 10 · TIPOGRAFIA
# ==============================================================================
# Fontes variáveis (licença OFL, cópias e licenças em `assets/fonts/`).
# O Theme aplica cada peso via `FontVariation` no eixo `wght`.

## Fonte display — títulos, números, rótulos de botão. Arredondada e amigável.
const CAMINHO_FONTE_DISPLAY: String = "res://assets/fonts/fredoka-variable.ttf"
## Fonte de corpo — UI e parágrafos. x-height alta, legível em 12px.
const CAMINHO_FONTE_CORPO: String = "res://assets/fonts/nunito-variable.ttf"

## Pesos usados (eixo `wght` da fonte variável, via `FontVariation`).
const PESO_REGULAR: int = 400
const PESO_MEDIO: int = 500
const PESO_SEMIBOLD: int = 600
const PESO_BOLD: int = 700
const PESO_EXTRABOLD: int = 800

# --- Escala tipográfica. Cada token expõe tamanho, altura de linha e peso. ---

## display/hero — Fredoka 700 · 44/48. Nome do app, número de destaque.
const TAM_HERO: int = 44
const ALTURA_LINHA_HERO: int = 48
const PESO_HERO: int = PESO_BOLD

## display/score — Fredoka 700 · 34/38. Pontuação grande do HUD e do resultado.
const TAM_SCORE: int = 34
const ALTURA_LINHA_SCORE: int = 38
const PESO_SCORE: int = PESO_BOLD

## title/lg — Fredoka 600 · 26/32. Título de modal, anúncio de chefe.
const TAM_TITULO_LG: int = 26
const ALTURA_LINHA_TITULO_LG: int = 32
const PESO_TITULO_LG: int = PESO_SEMIBOLD

## title/md — Fredoka 600 · 20/26. Título de seção, nome de fase.
const TAM_TITULO_MD: int = 20
const ALTURA_LINHA_TITULO_MD: int = 26
const PESO_TITULO_MD: int = PESO_SEMIBOLD

## button — Fredoka 600 · 18/24. Rótulo de botão.
const TAM_BOTAO: int = 18
const ALTURA_LINHA_BOTAO: int = 24
const PESO_BOTAO: int = PESO_SEMIBOLD

## body — Nunito 700 · 15/22. Texto corrido padrão.
const TAM_CORPO: int = 15
const ALTURA_LINHA_CORPO: int = 22
const PESO_CORPO: int = PESO_BOLD

## body/sm — Nunito 700 · 13/18. Texto de apoio, metadados.
const TAM_CORPO_SM: int = 13
const ALTURA_LINHA_CORPO_SM: int = 18
const PESO_CORPO_SM: int = PESO_BOLD

## caption — Nunito 800 · 12/16 · +4% tracking · CAIXA ALTA.
const TAM_LEGENDA: int = 12
const ALTURA_LINHA_LEGENDA: int = 16
const PESO_LEGENDA: int = PESO_EXTRABOLD
## Espaçamento entre letras da legenda, em em. Converter com `tracking_em_pixels()`.
const TRACKING_LEGENDA: float = 0.04

## Reserva de crescimento de texto para DE/FR. Botões e chips usam altura
## mínima, NUNCA altura fixa (ver `TOQUE_*`).
const RESERVA_CRESCIMENTO_TEXTO: float = 0.30


# ==============================================================================
# 11 · ESPAÇAMENTO (escala 4/8, em dp)
# ==============================================================================

const ESP_MICRO: int = 4
const ESP_XS: int = 8
const ESP_SM: int = 12
const ESP_MD: int = 16
const ESP_LG: int = 24
const ESP_XL: int = 32
const ESP_2XL: int = 48
const ESP_3XL: int = 64

## Escala completa, para telas que precisam iterar (ex.: gerador de layout).
const ESCALA_ESPACAMENTO: PackedInt32Array = PackedInt32Array([4, 8, 12, 16, 24, 32, 48, 64])


# ==============================================================================
# 12 · RAIOS DE CANTO (dp)
# ==============================================================================

## Chips e tags.
const RAIO_CHIP: int = 12
## Botões e cards padrão.
const RAIO_BOTAO: int = 16
## Cards grandes.
const RAIO_CARD: int = 20
## Modais.
const RAIO_MODAL: int = 26
## Pílula (contadores, chips de filtro). Valor alto = sempre semicircular.
const RAIO_PILULA: int = 999


# ==============================================================================
# 12b · LARGURAS DE BORDA (dp)
# ==============================================================================
# O design usa 1px / 1.5px / 2px. `StyleBoxFlat.border_width` é inteiro, então
# 1.5 foi arredondado para 2 — o que também nos alinha ao anel de foco.

## Borda de contorno sutil (vidro, cards).
const BORDA_FINA: int = 1
## Borda de destaque (campo focado, item selecionado, erro) e anel de foco.
const BORDA_DESTAQUE: int = 2


# ==============================================================================
# 13 · ALVOS DE TOQUE (dp) — público 7+, dedos pequenos
# ==============================================================================

## Mínimo absoluto (botões de ícone). Nada abaixo disto é tocável.
const TOQUE_MIN: int = 48
## Padrão (botões de texto, campos, itens de lista).
const TOQUE_PADRAO: int = 56
## CTA herói (Jogar).
const TOQUE_HEROI: int = 64


# ==============================================================================
# 14 · INTERAÇÃO
# ==============================================================================

## Deslocamento vertical no press, em dp.
const PRESS_DESLOCAMENTO_Y: int = 2
## Escurecimento aplicado ao fundo no press.
const PRESS_ESCURECIMENTO: float = 0.06
## Espessura do anel de foco, em dp.
const FOCO_ESPESSURA: int = 2
## Cor do anel de foco.
const COR_FOCO: Color = Color("#38BDF8")
## Fundo da seleção de texto em campos de edição.
const COR_SELECAO_TEXTO: Color = Color(Color("#4ADE80"), 0.35)
## Opacidade de controle desabilitado.
const OPACIDADE_DESABILITADO: float = 0.4


# ==============================================================================
# 15 · ACESSIBILIDADE — limiares de validação
# ==============================================================================

## Contraste mínimo para texto normal (WCAG 2.1 AA).
const CONTRASTE_MIN_TEXTO: float = 4.5
## Contraste mínimo para texto grande e componentes gráficos (WCAG 2.1 AA).
const CONTRASTE_MIN_GRAFICO: float = 3.0


# ==============================================================================
# ACESSORES TIPADOS
# ==============================================================================

## Cor base do corpo de uma cobra.
static func cor_cobra(cor: CorCobra) -> Color:
	return CORES_COBRA_BASE[int(cor)]


## Tom escuro (contorno/sombra) de uma cobra.
static func cor_cobra_escura(cor: CorCobra) -> Color:
	return CORES_COBRA_ESCURA[int(cor)]


## Símbolo geométrico do modo daltonismo para uma cobra.
static func simbolo_cobra(cor: CorCobra) -> SimboloDaltonismo:
	return SIMBOLOS_COBRA[int(cor)] as SimboloDaltonismo


## Cor de uma raridade de skin.
static func cor_raridade(raridade: Raridade) -> Color:
	return CORES_RARIDADE[int(raridade)]


## Caminho do asset SVG de um símbolo do modo daltonismo.
static func caminho_simbolo(simbolo: SimboloDaltonismo) -> String:
	return DIR_SIMBOLOS_DALTONISMO + ARQUIVOS_SIMBOLO[int(simbolo)] + ".svg"


## Cor de um CTA sólido no estado pressionado (escurecida em `PRESS_ESCURECIMENTO`).
static func cor_press(base: Color) -> Color:
	return base.darkened(PRESS_ESCURECIMENTO)


## Tracking em pixels inteiros para `FontVariation.spacing_glyph`.
## 0.04em × 12px = 0.48px arredondaria para zero e apagaria o tracking da
## legenda — por isso o piso é 1px.
static func tracking_em_pixels(tamanho: int) -> int:
	return maxi(1, roundi(TRACKING_LEGENDA * float(tamanho)))


## Converte altura de linha de design (CSS `line-height`) no `line_spacing`
## do Godot, que é espaço EXTRA e não altura total.
## Aproximação: o Godot já reserva ~1.2× o tamanho da fonte.
static func espacamento_linha(tamanho: int, altura_linha: int) -> int:
	return maxi(0, altura_linha - roundi(tamanho * 1.2))


## Razão de contraste WCAG 2.1 entre duas cores opacas.
## Usar em testes gdUnit4 para impedir regressão de tokens.
static func razao_contraste(frente: Color, fundo: Color) -> float:
	var l_frente: float = _luminancia_relativa(frente)
	var l_fundo: float = _luminancia_relativa(fundo)
	var claro: float = maxf(l_frente, l_fundo)
	var escuro: float = minf(l_frente, l_fundo)
	return (claro + 0.05) / (escuro + 0.05)


## Compõe uma cor com alpha sobre um fundo opaco, devolvendo a cor resultante.
## Necessário para validar contraste nas superfícies de vidro.
static func compor_sobre(frente: Color, fundo: Color) -> Color:
	var a: float = frente.a
	return Color(
		frente.r * a + fundo.r * (1.0 - a),
		frente.g * a + fundo.g * (1.0 - a),
		frente.b * a + fundo.b * (1.0 - a),
		1.0
	)


## Luminância relativa segundo WCAG 2.1.
static func _luminancia_relativa(cor: Color) -> float:
	return (
		0.2126 * _linearizar(cor.r)
		+ 0.7152 * _linearizar(cor.g)
		+ 0.0722 * _linearizar(cor.b)
	)


## Remove a curva sRGB de um canal.
static func _linearizar(canal: float) -> float:
	if canal <= 0.04045:
		return canal / 12.92
	return pow((canal + 0.055) / 1.055, 2.4)
