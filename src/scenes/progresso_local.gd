class_name ProgressoLocal
extends RefCounted
## Progresso persistido no aparelho (`user://progresso.cfg`): quais desafios
## foram concluídos. M1 usa só o local; a sincronização com a conta
## (Supabase) entra junto com a fila de sessões.

const CAMINHO: String = "user://progresso.cfg"


static func desafio_concluido(desafio: ChallengeRules.Desafio) -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CAMINHO) != OK:
		return false
	return cfg.get_value("desafios", str(int(desafio)), false)


static func marcar_desafio_concluido(desafio: ChallengeRules.Desafio) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CAMINHO)  # falha silenciosa = arquivo ainda não existe
	cfg.set_value("desafios", str(int(desafio)), true)
	cfg.save(CAMINHO)
