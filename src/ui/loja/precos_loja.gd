class_name PrecosLoja
extends RefCounted
## Preços dos buffs permanentes (docs §2.6.2): `200 × growth^N`, N = nível
## comprado. Conferido contra a tela do design: Velocidade Nv 2 = 298
## (200 × 1.22² = 297.68 → round). O teto Nv 10 vem do motor
## (`GameEngine.NIVEL_MAX_BUFF`) — a Loja nunca vende além dele.

const PRECO_BASE: int = 200

## Metadados de cada buff, na ordem da tela 09b. `chave` é a seção de
## `ProgressoLocal` E o sufixo do campo na `ConfigPartida` (nivel_<chave>).
const BUFFS: Array[Dictionary] = [
	{"chave": "velocidade", "icone": "⚡", "nome": "Velocidade",
		"efeito": "+0.05 de turbo por nível", "growth": 1.22},
	{"chave": "ima", "icone": "🧲", "nome": "Ímã",
		"efeito": "+15 de alcance de atração", "growth": 1.42},
	{"chave": "pontos", "icone": "", "nome": "Pontos iniciais",
		"efeito": "+5 pontos ao nascer", "growth": 1.13},
]


## Preço em moedas para comprar o nível `nivel_alvo` (1..10) de um buff.
static func preco_buff(growth: float, nivel_alvo: int) -> int:
	return roundi(PRECO_BASE * pow(growth, nivel_alvo))
