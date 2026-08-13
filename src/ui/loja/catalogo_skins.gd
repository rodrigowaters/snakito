class_name CatalogoSkins
extends RefCounted
## Catálogo de skins da Loja (blueprint 09). Skins NUNCA dão vantagem
## (regra dura #7) — é só a cor da sua cobra. Substitui a antiga tela de
## Skins do M1: agora a Loja é a casa delas.
##
## `indice` aponta para `SnakitoTokens.CORES_COBRA_BASE`. Turquesa ficou de
## fora de propósito: no tamanho de jogo ela é vizinha demais do verde —
## as 4 escolhidas são inconfundíveis entre si. `preco` 0 = grátis.
## Raras/épicas/lendárias entram com o Billing (docs §5, Fase 3).

const SKINS: Array[Dictionary] = [
	{"indice": 0, "nome": "Verdinha", "raridade": SnakitoTokens.Raridade.COMUM, "preco": 0},
	{"indice": 1, "nome": "Azulzinha", "raridade": SnakitoTokens.Raridade.COMUM, "preco": 0},
	{"indice": 2, "nome": "Rosinha", "raridade": SnakitoTokens.Raridade.COMUM, "preco": 0},
	{"indice": 3, "nome": "Amarelinha", "raridade": SnakitoTokens.Raridade.COMUM, "preco": 0},
]


## Skins de uma raridade, na ordem do catálogo.
static func da_raridade(raridade: SnakitoTokens.Raridade) -> Array[Dictionary]:
	var filtradas: Array[Dictionary] = []
	for skin: Dictionary in SKINS:
		if skin.raridade == raridade:
			filtradas.append(skin)
	return filtradas
