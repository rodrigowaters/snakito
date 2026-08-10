class_name FilaSessoes
extends RefCounted
## Fila offline de sessões terminadas (docs §6): toda partida encerrada entra
## aqui — logado ou não — e o autoload `Rede` despacha quando houver rede,
## login e perfil. Arquivo CRIPTOGRADO com chave do aparelho.

const CAMINHO: String = "user://fila_sessoes.cfg"
## Proteção contra crescimento infinito de fila sem login (30d é também o
## limite de idade que o servidor aceita).
const MAX_PENDENTES: int = 200


## Enfileira o payload de uma sessão encerrada (formato do submit_session).
static func enfileirar(payload: Dictionary) -> void:
	var cfg: ConfigFile = _abrir()
	var secoes: PackedStringArray = cfg.get_sections()
	if secoes.size() >= MAX_PENDENTES:
		cfg.erase_section(secoes[0])  # descarta a mais antiga
	var id: String = "%d_%06d" % [Time.get_unix_time_from_system(), randi() % 1000000]
	cfg.set_value(id, "payload", payload)
	cfg.save_encrypted_pass(CAMINHO, OS.get_unique_id())


## Pendências em ordem de chegada: [{id, payload}].
static func pendentes() -> Array[Dictionary]:
	var cfg: ConfigFile = _abrir()
	var lista: Array[Dictionary] = []
	var secoes: Array = Array(cfg.get_sections())
	secoes.sort()  # id começa com unix time → ordem cronológica
	for id: String in secoes:
		lista.append({"id": id, "payload": cfg.get_value(id, "payload", {})})
	return lista


static func remover(id: String) -> void:
	var cfg: ConfigFile = _abrir()
	if cfg.has_section(id):
		cfg.erase_section(id)
		cfg.save_encrypted_pass(CAMINHO, OS.get_unique_id())


static func tamanho() -> int:
	return _abrir().get_sections().size()


static func _abrir() -> ConfigFile:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load_encrypted_pass(CAMINHO, OS.get_unique_id())  # ausente = fila vazia
	return cfg
