extends Node
## Autoload `Rede` — única porta do jogo para o Supabase (docs §6):
## auth (APENAS Google Sign-In), perfil, envio de sessões via Edge Function
## e ranking. Gameplay NUNCA passa por aqui (offline-first é regra dura #5).
##
## Autoload de propósito (desvio consciente do padrão "sem autoloads" das
## cenas): HTTPRequest precisa estar na árvore e a fila de sessões despacha
## de qualquer tela. Sem class_name — o nome do autoload já é `Rede`.
##
## Tokens em `user://sessao_auth.cfg` CRIPTOGRADO com chave do aparelho
## (docs §6). A chave publishable abaixo é pública por design.

signal sessao_mudou

const URL_BASE: String = "https://cfpsounmrhoodijmrths.supabase.co"
const CHAVE_PUBLICA: String = "sb_publishable_6F6vxEdvykR96c6fqE2ZMQ_EpQM16Yz"
const CAMINHO_TOKENS: String = "user://sessao_auth.cfg"
const VERSAO_CLIENTE: String = "0.1.0"

var _access_token: String = ""
var _refresh_token: String = ""
var _user_id: String = ""
var _username: String = ""
## created_at do perfil (ISO) — "jogando desde {mês}" da tela 02b.
var _criado_em: String = ""


func _ready() -> void:
	_carregar_tokens()
	if logado():
		# Valida a sessão guardada e aproveita para despachar pendências.
		await atualizar_perfil()
		despachar_fila()


func logado() -> bool:
	return _access_token != ""


func username() -> String:
	return _username


func tem_perfil() -> bool:
	return _username != ""


# ------------------------------------------------------------------- auth

## Login com o id_token do Google Sign-In nativo (docs §4.1: só Google).
func entrar_com_google(id_token: String) -> bool:
	var resposta: Dictionary = await _requisitar(
		HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=id_token",
		{"provider": "google", "id_token": id_token},
		false,
	)
	if resposta.status != 200 or resposta.dados == null:
		return false
	_guardar_sessao(resposta.dados)
	await atualizar_perfil()
	despachar_fila()
	sessao_mudou.emit()
	return true


func sair() -> void:
	_access_token = ""
	_refresh_token = ""
	_user_id = ""
	_username = ""
	DirAccess.remove_absolute(CAMINHO_TOKENS)
	sessao_mudou.emit()


func _renovar() -> bool:
	if _refresh_token == "":
		return false
	var resposta: Dictionary = await _requisitar(
		HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=refresh_token",
		{"refresh_token": _refresh_token},
		false,
	)
	if resposta.status != 200 or resposta.dados == null:
		sair()
		return false
	_guardar_sessao(resposta.dados)
	return true


# ----------------------------------------------------------------- perfil

## Busca o perfil (RLS: dono lê). username "" = perfil ainda não criado.
func atualizar_perfil() -> void:
	var resposta: Dictionary = await _com_renovacao(
		HTTPClient.METHOD_GET, "/rest/v1/profiles?select=username,created_at", {})
	if resposta.status == 200 and resposta.dados is Array and not (resposta.dados as Array).is_empty():
		_username = resposta.dados[0].get("username", "")
		_criado_em = str(resposta.dados[0].get("created_at", ""))
	else:
		_username = ""
		_criado_em = ""


## created_at do perfil em ISO ("" = desconhecido) — tela 02b.
func criado_em() -> String:
	return _criado_em


## Cria o perfil do usuário logado. `com_consentimento_parental` = usuário
## declarou <13 e um responsável autorizou (docs §9 — a idade em si NÃO é
## coletada, só o carimbo do consentimento quando necessário).
## Devolve "" em sucesso ou o motivo do erro.
func criar_perfil(nome: String, com_consentimento_parental: bool = false) -> String:
	if nome.length() < 3 or nome.length() > 20:
		return "o apelido precisa ter de 3 a 20 caracteres"
	var corpo: Dictionary = {"id": _user_id, "username": nome}
	if com_consentimento_parental:
		corpo["parental_consent_at"] = Time.get_datetime_string_from_system(true) + "Z"
	var resposta: Dictionary = await _com_renovacao(
		HTTPClient.METHOD_POST, "/rest/v1/profiles", corpo)
	if resposta.status == 201:
		_username = nome
		sessao_mudou.emit()
		return ""
	if resposta.status == 409:
		return "este apelido já está em uso"
	return "não deu para criar o perfil agora — tente de novo"


## Exclusão de conta dentro do app (docs §9): a Edge Function apaga o
## usuário e o cascade elimina perfil, sessões e leaderboard.
func excluir_conta() -> bool:
	var resposta: Dictionary = await _com_renovacao(
		HTTPClient.METHOD_POST, "/functions/v1/delete_account", {"confirmar": true})
	if resposta.status == 200:
		sair()
		return true
	return false


# ------------------------------------------------------------------ sessões

## Envia UMA sessão para a Edge Function. Devolve o status HTTP (0 = sem rede).
func enviar_sessao(payload: Dictionary) -> int:
	var resposta: Dictionary = await _com_renovacao(
		HTTPClient.METHOD_POST, "/functions/v1/submit_session", payload)
	return resposta.status


## Despacha a fila offline: para no primeiro sinal de falta de rede/login;
## descarta o que o servidor julgou implausível (422 nunca vai passar).
func despachar_fila() -> void:
	if not logado() or not tem_perfil():
		return
	for pendente: Dictionary in FilaSessoes.pendentes():
		var status: int = await enviar_sessao(pendente.payload)
		if status == 201 or status == 422:
			if status == 422:
				push_warning("Rede: sessão implausível descartada da fila")
			FilaSessoes.remover(pendente.id)
		else:
			break  # sem rede/login — tenta na próxima oportunidade


# ------------------------------------------------------------------ ranking

## Ranking da semana atual. Devolve Array de dicionários ou [] em erro.
func ranking_semanal() -> Array:
	var resposta: Dictionary = await _com_renovacao(
		HTTPClient.METHOD_POST, "/rest/v1/rpc/ranking_semanal", {})
	if resposta.status == 200 and resposta.dados is Array:
		return resposta.dados
	return []


# ------------------------------------------------------------------ internos

func _guardar_sessao(dados: Dictionary) -> void:
	_access_token = dados.get("access_token", "")
	_refresh_token = dados.get("refresh_token", "")
	var usuario: Dictionary = dados.get("user", {})
	_user_id = usuario.get("id", _user_id)
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("auth", "access_token", _access_token)
	cfg.set_value("auth", "refresh_token", _refresh_token)
	cfg.set_value("auth", "user_id", _user_id)
	cfg.save_encrypted_pass(CAMINHO_TOKENS, OS.get_unique_id())


func _carregar_tokens() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load_encrypted_pass(CAMINHO_TOKENS, OS.get_unique_id()) != OK:
		return
	_access_token = cfg.get_value("auth", "access_token", "")
	_refresh_token = cfg.get_value("auth", "refresh_token", "")
	_user_id = cfg.get_value("auth", "user_id", "")


## Requisição com renovação automática do token em 401 (uma tentativa).
func _com_renovacao(metodo: int, caminho: String, corpo: Dictionary) -> Dictionary:
	var resposta: Dictionary = await _requisitar(metodo, caminho, corpo, true)
	if resposta.status == 401 and await _renovar():
		resposta = await _requisitar(metodo, caminho, corpo, true)
	return resposta


## Uma requisição HTTP. Devolve {"status": int (0 = falha de rede), "dados": Variant}.
func _requisitar(
	metodo: int,
	caminho: String,
	corpo: Dictionary,
	com_auth: bool,
) -> Dictionary:
	var http: HTTPRequest = HTTPRequest.new()
	http.timeout = 15.0
	add_child(http)
	var headers: PackedStringArray = PackedStringArray([
		"apikey: " + CHAVE_PUBLICA,
		"Content-Type: application/json",
		"Prefer: return=representation",
	])
	if com_auth and _access_token != "":
		headers.append("Authorization: Bearer " + _access_token)
	var corpo_json: String = JSON.stringify(corpo) if not corpo.is_empty() else ""
	if http.request(URL_BASE + caminho, headers, metodo as HTTPClient.Method, corpo_json) != OK:
		http.queue_free()
		return {"status": 0, "dados": null}
	var resultado: Array = await http.request_completed
	http.queue_free()
	var codigo_transporte: int = resultado[0]
	var status: int = resultado[1]
	var texto: String = (resultado[3] as PackedByteArray).get_string_from_utf8()
	if OS.is_debug_build():
		print("Rede: %s %s → transporte=%d http=%d corpo[0:80]=%s" % [
			"GET" if metodo == HTTPClient.METHOD_GET else "POST",
			caminho, codigo_transporte, status, texto.substr(0, 80).c_escape()])
	var dados: Variant = null
	if texto != "":
		dados = JSON.parse_string(texto)  # null se o corpo não for JSON
	return {"status": status, "dados": dados}
