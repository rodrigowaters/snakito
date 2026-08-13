class_name ProgressoLocal
extends RefCounted
## Progresso persistido no aparelho (`user://progresso.cfg`): desafios
## concluídos, skin equipada, economia e dificuldade escolhida.
## Leituras passam por cache em memória — o render consulta a skin a cada
## frame e não pode tocar disco.

const CAMINHO: String = "user://progresso.cfg"

## Dificuldade do Arcade (escolha vai para Configurações no M3).
enum Dificuldade { TRANQUILA, CHEIA }

static var _cache: ConfigFile = null


# ------------------------------------------------------------------ desafios

static func desafio_concluido(desafio: ChallengeRules.Desafio) -> bool:
	return _abrir().get_value("desafios", str(int(desafio)), false)


static func marcar_desafio_concluido(desafio: ChallengeRules.Desafio) -> void:
	_abrir().set_value("desafios", str(int(desafio)), true)
	_salvar()


# --------------------------------------------------------------------- skins

## Índice da skin equipada em `SnakitoTokens.CORES_COBRA_BASE` (0 = verde).
static func skin_equipada() -> int:
	return _abrir().get_value("skins", "equipada", 0)


static func equipar_skin(indice: int) -> void:
	_abrir().set_value("skins", "equipada", indice)
	_salvar()


# ----------------------------------------------------------------- economia
# Moedas e tickets (docs §5 — economia é M3): a Home já EXIBE os contadores
# (blueprint 1d) e a persistência está pronta; ganhar/gastar liga no M3.

static func moedas() -> int:
	return _abrir().get_value("economia", "moedas", 0)


static func tickets() -> int:
	return _abrir().get_value("economia", "tickets", 0)


static func adicionar_moedas(quantidade: int) -> void:
	_abrir().set_value("economia", "moedas", maxi(0, moedas() + quantidade))
	_salvar()


static func adicionar_tickets(quantidade: int) -> void:
	_abrir().set_value("economia", "tickets", maxi(0, tickets() + quantidade))
	_salvar()


# ---------------------------------------------------------------------- jogo

## Dificuldade do Arcade. Nasceu na escolha do onboarding (REMOVIDO em
## 13/08 por decisão do Rodrigo); passa a ser escolhida na tela de
## Configurações (M3). Até lá, vale o padrão CHEIA.
static func dificuldade() -> Dificuldade:
	return _abrir().get_value("jogo", "dificuldade", Dificuldade.CHEIA)


static func definir_dificuldade(valor: Dificuldade) -> void:
	_abrir().set_value("jogo", "dificuldade", valor)
	_salvar()


## Melhor posição no Arcade (blueprint 05: "sua melhor posição até hoje!").
## 0 = nunca terminou uma partida. Registrar devolve true se virou recorde.
static func melhor_posicao() -> int:
	return _abrir().get_value("jogo", "melhor_posicao", 0)


static func registrar_posicao(posicao: int) -> bool:
	var atual: int = melhor_posicao()
	if atual == 0 or posicao < atual:
		_abrir().set_value("jogo", "melhor_posicao", posicao)
		_salvar()
		return true
	return false


## Háptica ligada? (toggle da Pausa, blueprint 04c — padrão ligada)
static func vibracao() -> bool:
	return _abrir().get_value("jogo", "vibracao", true)


static func definir_vibracao(ligada: bool) -> void:
	_abrir().set_value("jogo", "vibracao", ligada)
	_salvar()


# ------------------------------------------------------------------ internos

static func _abrir() -> ConfigFile:
	if _cache == null:
		_cache = ConfigFile.new()
		_cache.load(CAMINHO)  # ausente = progresso zerado
	return _cache


static func _salvar() -> void:
	_cache.save(CAMINHO)


## Para testes: derruba o cache (o arquivo pode ter sido apagado por fora).
static func _resetar_cache_para_testes() -> void:
	_cache = null
