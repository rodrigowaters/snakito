class_name ProgressoLocal
extends RefCounted
## Progresso persistido no aparelho (`user://progresso.cfg`): desafios
## concluídos, skin equipada, onboarding e dificuldade escolhida.
## Leituras passam por cache em memória — o render consulta a skin a cada
## frame e não pode tocar disco.

const CAMINHO: String = "user://progresso.cfg"

## Dificuldade do Arcade escolhida no onboarding (docs §8, passo 4).
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


# --------------------------------------------------------- onboarding & jogo

static func onboarding_visto() -> bool:
	return _abrir().get_value("onboarding", "visto", false)


static func marcar_onboarding_visto() -> void:
	_abrir().set_value("onboarding", "visto", true)
	_salvar()


static func dificuldade() -> Dificuldade:
	return _abrir().get_value("jogo", "dificuldade", Dificuldade.CHEIA)


static func definir_dificuldade(valor: Dificuldade) -> void:
	_abrir().set_value("jogo", "dificuldade", valor)
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
