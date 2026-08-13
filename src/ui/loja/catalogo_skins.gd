class_name CatalogoSkins
extends RefCounted
## Catálogo de skins da Loja (blueprints 09/09a). Skins NUNCA dão vantagem
## (regra dura #7) — é só o visual da sua cobra.
##
## Campos: `id` (chave de persistência), `indice` aponta para
## `SnakitoTokens.CORES_COBRA_BASE` (-1 = padrão premium, o render em jogo
## ainda não desenha — chega com o Billing/M3), `preco` em moedas (0 =
## grátis; -1 = só no pacote), `visual` = {tipo: solida|metades|listras,
## cores}, `tag` = etiqueta flutuante do card.
##
## Decisões: turquesa e lima ficam SÓ para bots (vizinhas demais do verde
## no tamanho de jogo); raras são as 2 sólidas restantes da paleta —
## compráveis com moedas DESDE JÁ (o render já desenha cor sólida); épicas
## e lendárias vêm do design (nomes/preços do blueprint 09 e 09a).

const SKINS: Array[Dictionary] = [
	# --- comuns (M1, grátis) ---
	{"id": "verdinha", "indice": 0, "nome": "Verdinha",
		"raridade": SnakitoTokens.Raridade.COMUM, "preco": 0, "tag": "",
		"visual": {"tipo": "solida", "cores": []}},
	{"id": "azulzinha", "indice": 1, "nome": "Azulzinha",
		"raridade": SnakitoTokens.Raridade.COMUM, "preco": 0, "tag": "",
		"visual": {"tipo": "solida", "cores": []}},
	{"id": "rosinha", "indice": 2, "nome": "Rosinha",
		"raridade": SnakitoTokens.Raridade.COMUM, "preco": 0, "tag": "",
		"visual": {"tipo": "solida", "cores": []}},
	{"id": "amarelinha", "indice": 3, "nome": "Amarelinha",
		"raridade": SnakitoTokens.Raridade.COMUM, "preco": 0, "tag": "",
		"visual": {"tipo": "solida", "cores": []}},
	# --- raras (sólidas da paleta, compráveis com moedas) ---
	{"id": "laranjinha", "indice": 4, "nome": "Laranjinha",
		"raridade": SnakitoTokens.Raridade.RARA, "preco": 400, "tag": "",
		"visual": {"tipo": "solida", "cores": []}},
	{"id": "roxinha", "indice": 5, "nome": "Roxinha",
		"raridade": SnakitoTokens.Raridade.RARA, "preco": 400, "tag": "",
		"visual": {"tipo": "solida", "cores": []}},
	# --- épicas (padrões do blueprint 09 — render em jogo é M3/Billing) ---
	{"id": "minhoca", "indice": -1, "nome": "Minhoca",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": 800, "tag": "NOVA",
		"visual": {"tipo": "metades", "cores": SnakitoTokens.SKIN_MINHOCA}},
	{"id": "abelha", "indice": -1, "nome": "Abelha",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": 800, "tag": "",
		"visual": {"tipo": "listras", "cores": SnakitoTokens.SKIN_ABELHA}},
	{"id": "melancia", "indice": -1, "nome": "Melancia",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": 800, "tag": "",
		"visual": {"tipo": "metades", "cores": SnakitoTokens.SKIN_MELANCIA}},
	{"id": "trem", "indice": -1, "nome": "Trem",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": 1000, "tag": "",
		"visual": {"tipo": "listras", "cores": SnakitoTokens.SKIN_TREM}},
	{"id": "tigre", "indice": -1, "nome": "Tigre",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": 1000, "tag": "",
		"visual": {"tipo": "listras", "cores": SnakitoTokens.SKIN_TIGRE}},
	{"id": "foguete", "indice": -1, "nome": "Foguete",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": 1000, "tag": "",
		"visual": {"tipo": "metades", "cores": SnakitoTokens.SKIN_FOGUETE}},
	# --- épicas do Pacote Neon (só no pacote — Billing M3) ---
	{"id": "neon_verde", "indice": -1, "nome": "Neon Verde",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": -1, "tag": "PACOTE",
		"visual": {"tipo": "solida", "cores": SnakitoTokens.SKIN_NEON_VERDE}},
	{"id": "neon_azul", "indice": -1, "nome": "Neon Azul",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": -1, "tag": "PACOTE",
		"visual": {"tipo": "solida", "cores": SnakitoTokens.SKIN_NEON_AZUL}},
	{"id": "neon_rosa", "indice": -1, "nome": "Neon Rosa",
		"raridade": SnakitoTokens.Raridade.EPICA, "preco": -1, "tag": "PACOTE",
		"visual": {"tipo": "solida", "cores": SnakitoTokens.SKIN_NEON_ROSA}},
	# --- lendárias (blueprint 09a + Pacote Cósmico) ---
	{"id": "fenix", "indice": -1, "nome": "Fênix",
		"raridade": SnakitoTokens.Raridade.LENDARIA, "preco": 2500, "tag": "",
		"visual": {"tipo": "metades", "cores": SnakitoTokens.SKIN_FENIX}},
	{"id": "nebulosa", "indice": -1, "nome": "Nebulosa",
		"raridade": SnakitoTokens.Raridade.LENDARIA, "preco": 2500, "tag": "",
		"visual": {"tipo": "metades", "cores": SnakitoTokens.SKIN_NEBULOSA}},
]


## Skins de uma raridade, na ordem do catálogo.
static func da_raridade(raridade: SnakitoTokens.Raridade) -> Array[Dictionary]:
	var filtradas: Array[Dictionary] = []
	for skin: Dictionary in SKINS:
		if skin.raridade == raridade:
			filtradas.append(skin)
	return filtradas


## A skin está desbloqueada? (grátis ou comprada)
static func desbloqueada(skin: Dictionary) -> bool:
	return skin.preco == 0 or ProgressoLocal.skin_comprada(skin.id)


## Quantas skins o jogador já tem (tela 02b: "Skins na coleção").
static func total_desbloqueadas() -> int:
	var total: int = 0
	for skin: Dictionary in SKINS:
		if desbloqueada(skin):
			total += 1
	return total
