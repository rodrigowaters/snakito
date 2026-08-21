class_name FilaRecibos
extends RefCounted
## Fila de recibos do Play ainda não validados pelo servidor (docs §5).
## Mesmo padrão da `FilaSessoes` — arquivo CRIPTOGRADO com chave do
## aparelho — mas por um motivo mais sério: aqui há DINHEIRO envolvido.
##
## O jogador pode comprar e a validação falhar (sem rede, Google fora,
## credencial ainda não configurada). Perder o recibo seria perder a
## compra; então ele fica aqui até o servidor confirmar, e o Play também
## guarda a sua cópia (`query_purchases` no boot recupera o que faltar).

const CAMINHO: String = "user://fila_recibos.cfg"
## Teto defensivo: recibo é raro (uma compra é evento), 50 é folga enorme.
const MAX_PENDENTES: int = 50


## Enfileira um recibo. `token` é a chave: reenfileirar o mesmo recibo não
## duplica (o servidor também é idempotente, mas não custa nada aqui).
static func enfileirar(product_id: String, token: String) -> void:
	var cfg: ConfigFile = _abrir()
	if cfg.has_section(token):
		return
	var secoes: PackedStringArray = cfg.get_sections()
	if secoes.size() >= MAX_PENDENTES:
		cfg.erase_section(secoes[0])
	cfg.set_value(token, "product_id", product_id)
	cfg.set_value(token, "criado_em", Time.get_unix_time_from_system())
	_salvar(cfg)


static func pendentes() -> Array[Dictionary]:
	var cfg: ConfigFile = _abrir()
	var lista: Array[Dictionary] = []
	for token: String in cfg.get_sections():
		lista.append({
			"token": token,
			"product_id": str(cfg.get_value(token, "product_id", "")),
		})
	return lista


static func remover(token: String) -> void:
	var cfg: ConfigFile = _abrir()
	if cfg.has_section(token):
		cfg.erase_section(token)
		_salvar(cfg)


static func tamanho() -> int:
	return _abrir().get_sections().size()


static func _abrir() -> ConfigFile:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load_encrypted_pass(CAMINHO, OS.get_unique_id())  # ausente = vazia
	return cfg


static func _salvar(cfg: ConfigFile) -> void:
	cfg.save_encrypted_pass(CAMINHO, OS.get_unique_id())
