class_name CatalogoProdutos
extends RefCounted
## Produtos do Google Play (docs §5 Fase 3). **Espelha o CATALOGO da Edge
## Function `validate_purchase`** — id, tipo e o que concede precisam bater
## nos dois lados; o servidor é a autoridade e recusa id desconhecido.
##
## PREÇO NÃO MORA AQUI: vem do Play em `query_product_details` (moeda e
## formato do país do jogador). Preço hardcoded é mentira em qualquer país
## que não seja o nosso — e mudaria sem o app saber.
##
## `tipo`: NAO_CONSUMIVEL vira entitlement perpétuo no servidor;
## CONSUMIVEL é creditado no aparelho (economia é local, decisão 13/08) e
## precisa de `consume_purchase` para poder ser comprado de novo.

enum Tipo { NAO_CONSUMIVEL, CONSUMIVEL }

## Produtos na ordem em que aparecem na aba Pacotes (blueprint 09c).
const PRODUTOS: Array[Dictionary] = [
	{
		"id": "remover_anuncios", "tipo": Tipo.NAO_CONSUMIVEL,
		"entitlements": ["ads_removed"], "moedas": 0, "tickets": 0,
	},
	{
		"id": "pacote_neon", "tipo": Tipo.NAO_CONSUMIVEL,
		"entitlements": ["skin_neon"], "moedas": 0, "tickets": 0,
	},
	{
		"id": "pacote_cosmico", "tipo": Tipo.NAO_CONSUMIVEL,
		"entitlements": ["skin_cosmico"], "moedas": 0, "tickets": 0,
	},
	{
		"id": "combo_turbinado", "tipo": Tipo.NAO_CONSUMIVEL,
		"entitlements": ["ads_removed"], "moedas": 500, "tickets": 0,
	},
	{
		"id": "combo_sem_interrupcao", "tipo": Tipo.NAO_CONSUMIVEL,
		"entitlements": ["ads_removed"], "moedas": 0, "tickets": 10,
	},
	{"id": "moedas_500", "tipo": Tipo.CONSUMIVEL, "entitlements": [], "moedas": 500, "tickets": 0},
	{"id": "moedas_1200", "tipo": Tipo.CONSUMIVEL, "entitlements": [], "moedas": 1200, "tickets": 0},
	{"id": "moedas_3000", "tipo": Tipo.CONSUMIVEL, "entitlements": [], "moedas": 3000, "tickets": 0},
	{"id": "tickets_5", "tipo": Tipo.CONSUMIVEL, "entitlements": [], "moedas": 0, "tickets": 5},
	{"id": "tickets_15", "tipo": Tipo.CONSUMIVEL, "entitlements": [], "moedas": 0, "tickets": 15},
	{"id": "tickets_40", "tipo": Tipo.CONSUMIVEL, "entitlements": [], "moedas": 0, "tickets": 40},
]


static func por_id(id: String) -> Dictionary:
	for produto: Dictionary in PRODUTOS:
		if produto.id == id:
			return produto
	return {}


static func ids() -> PackedStringArray:
	var lista: PackedStringArray = PackedStringArray()
	for produto: Dictionary in PRODUTOS:
		lista.append(produto.id)
	return lista


## Um produto libera skins premium? (a Loja usa para desbloquear o pacote)
static func entitlement_de_skin(id: String) -> String:
	var produto: Dictionary = por_id(id)
	for chave: String in produto.get("entitlements", []):
		if chave.begins_with("skin_"):
			return chave
	return ""
