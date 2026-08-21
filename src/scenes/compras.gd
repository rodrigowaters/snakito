extends Node
## Autoload `Compras` — única porta do jogo para o Google Play Billing
## (docs §5 Fase 3). Análogo ao `Anuncios`: fora do Android fica inerte e
## a UI degrada para os placeholders.
##
## Regra que organiza tudo: **o Play cobra, o SERVIDOR concede.** O recibo
## vai para a Edge Function `validate_purchase`, que confere com a Google
## Play Developer API e grava o direito. O cliente só credita saldo local
## DEPOIS do 200 do servidor — nunca antes, nunca por conta própria.
##
## Ordem de um fluxo completo:
##   comprar() → Play cobra → on_purchase_updated → FilaRecibos.enfileirar
##   → despachar() → validate_purchase → conceder localmente →
##   acknowledge (não consumível) ou consume (consumível) → remover da fila
##
## `acknowledge` só depois do servidor: recibo não reconhecido em 3 dias é
## REEMBOLSADO pelo Play automaticamente — é a rede de segurança do
## jogador se a nossa validação estiver quebrada.

signal precos_prontos
## Compra concluída e concedida (a UI recarrega saldos/entitlements).
signal compra_concedida(product_id: String)
signal compra_falhou(motivo: String)

var _cliente: BillingClient = null
var _pronto: bool = false
## product_id → texto de preço formatado pelo Play ("R$ 14,90").
var _precos: Dictionary[String, String] = {}
var _despachando: bool = false


func _ready() -> void:
	if OS.get_name() != "Android":
		_log("fora do Android — serviço inerte")
		return
	_cliente = BillingClient.new()
	add_child(_cliente)
	_cliente.connected.connect(_ao_conectar)
	_cliente.disconnected.connect(func() -> void:
		_pronto = false
		_log("desconectado do Play"))
	_cliente.connect_error.connect(func(codigo: int, msg: String) -> void:
		_log("falha ao conectar (%d) %s" % [codigo, msg]))
	_cliente.query_product_details_response.connect(_ao_receber_precos)
	_cliente.on_purchase_updated.connect(_ao_atualizar_compra)
	_cliente.query_purchases_response.connect(_ao_listar_compras)
	_cliente.start_connection()


func disponivel() -> bool:
	return _pronto


## Preço formatado pelo Play ("" = ainda não sei; a UI esconde o CTA).
func preco(product_id: String) -> String:
	return _precos.get(product_id, "")


## Abre o fluxo de compra do Play. O resultado chega em
## `on_purchase_updated` — inclusive cancelamento.
func comprar(product_id: String) -> void:
	if not _pronto:
		compra_falhou.emit("loja indisponível")
		return
	if CatalogoProdutos.por_id(product_id).is_empty():
		push_warning("Compras: produto fora do catálogo: " + product_id)
		return
	_log("iniciando compra de " + product_id)
	var resultado: Dictionary = _cliente.purchase(product_id)
	var codigo: int = int(resultado.get("response_code", -1))
	if codigo != BillingClient.BillingResponseCode.OK:
		_log("purchase() recusou (%d)" % codigo)
		compra_falhou.emit(_motivo(codigo))


## "Restaurar compras" (tela 10) e boot: pergunta ao Play o que a conta
## possui e revalida o que faltar. É também a rede de segurança de quem
## trocou de aparelho.
func restaurar() -> void:
	if not _pronto:
		compra_falhou.emit("loja indisponível")
		return
	_log("restaurando compras")
	_cliente.query_purchases(BillingClient.ProductType.INAPP)


# ------------------------------------------------------------------ internos

func _log(mensagem: String) -> void:
	if OS.is_debug_build():
		print("Compras: ", mensagem)


func _ao_conectar() -> void:
	_pronto = true
	_log("conectado ao Play")
	_cliente.query_product_details(
		CatalogoProdutos.ids(), BillingClient.ProductType.INAPP)
	# Compras de outro aparelho/instalação e recibos pendentes de validação.
	restaurar()
	despachar()


func _ao_receber_precos(resposta: Dictionary) -> void:
	var detalhes: Array = resposta.get("product_details_list", [])
	for item: Dictionary in detalhes:
		var id: String = str(item.get("product_id", ""))
		# Estrutura do Play: one_time_purchase_offer_details.formatted_price
		var oferta: Dictionary = item.get("one_time_purchase_offer_details", {})
		var formatado: String = str(oferta.get("formatted_price", ""))
		if id != "" and formatado != "":
			_precos[id] = formatado
	_log("preços recebidos: %d de %d" % [_precos.size(), CatalogoProdutos.ids().size()])
	precos_prontos.emit()


func _ao_atualizar_compra(resposta: Dictionary) -> void:
	var codigo: int = int(resposta.get("response_code", -1))
	if codigo != BillingClient.BillingResponseCode.OK:
		_log("compra não concluída (%d)" % codigo)
		compra_falhou.emit(_motivo(codigo))
		return
	_enfileirar_lista(resposta.get("purchases", []))
	despachar()


func _ao_listar_compras(resposta: Dictionary) -> void:
	if int(resposta.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	_enfileirar_lista(resposta.get("purchases", []))
	despachar()


## Guarda os recibos PAGOS na fila. Pendente (PENDING) não entra: o Play
## ainda vai confirmar — quando confirmar, ele reaparece aqui.
func _enfileirar_lista(compras: Array) -> void:
	for compra: Dictionary in compras:
		if int(compra.get("purchase_state", -1)) != BillingClient.PurchaseState.PURCHASED:
			continue
		var token: String = str(compra.get("purchase_token", ""))
		for id: String in compra.get("products", []):
			if token != "" and not CatalogoProdutos.por_id(id).is_empty():
				FilaRecibos.enfileirar(id, token)
				_log("recibo na fila: %s" % id)


## Manda cada recibo pendente ao servidor e concede o que ele autorizar.
## Para no primeiro erro de rede/validação — tenta de novo no próximo boot
## ou na próxima compra (o Play guarda a cópia dele).
func despachar() -> void:
	if _despachando:
		return
	if not Rede.logado() or not Rede.tem_perfil():
		_log("sem login/perfil — recibos ficam na fila")
		return
	_despachando = true
	for pendente: Dictionary in FilaRecibos.pendentes():
		var resposta: Dictionary = await Rede.validar_compra(
			str(pendente.product_id), str(pendente.token))
		var status: int = int(resposta.get("status", 0))
		if status == 200:
			_conceder(str(pendente.product_id), resposta.get("conceder", {}),
				bool(resposta.get("repetido", false)))
			_finalizar_no_play(str(pendente.product_id), str(pendente.token))
			FilaRecibos.remover(str(pendente.token))
		elif status == 409 or status == 422 or status == 400:
			# Recibo de outra conta, inválido ou produto desconhecido: não
			# vai passar nunca. Sai da fila para não travar os próximos.
			_log("recibo descartado (%d): %s" % [status, pendente.product_id])
			FilaRecibos.remover(str(pendente.token))
		else:
			_log("validação adiada (%d) — recibo fica na fila" % status)
			break
	_despachando = false


## Concede o que o SERVIDOR autorizou. Entitlement já foi gravado lá; aqui
## só espelhamos (para valer offline) e creditamos o saldo local.
func _conceder(product_id: String, concedido: Dictionary, repetido: bool) -> void:
	if not repetido:
		var moedas: int = int(concedido.get("moedas", 0))
		var tickets: int = int(concedido.get("tickets", 0))
		if moedas > 0:
			ProgressoLocal.adicionar_moedas(moedas)
		if tickets > 0:
			ProgressoLocal.adicionar_tickets(tickets)
		_log("concedido: %s (+%d moedas, +%d tickets)" % [product_id, moedas, tickets])
	await Rede.atualizar_entitlements()  # servidor é a autoridade
	compra_concedida.emit(product_id)


## Fecha o ciclo com o Play. Consumível é CONSUMIDO (pode comprar de novo);
## não consumível é RECONHECIDO (sem isso, reembolso automático em 3 dias).
func _finalizar_no_play(product_id: String, token: String) -> void:
	var produto: Dictionary = CatalogoProdutos.por_id(product_id)
	if produto.get("tipo", CatalogoProdutos.Tipo.NAO_CONSUMIVEL) \
			== CatalogoProdutos.Tipo.CONSUMIVEL:
		_cliente.consume_purchase(token)
	else:
		_cliente.acknowledge_purchase(token)


## Mensagem para o jogador — texto de criança, não código de erro.
func _motivo(codigo: int) -> String:
	match codigo:
		BillingClient.BillingResponseCode.USER_CANCELED:
			return ""  # desistiu: não é erro, não avisa nada
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			return "você já tem isso!"
		BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE, \
		BillingClient.BillingResponseCode.NETWORK_ERROR:
			return "sem internet agora"
		BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
			return "esse item não está disponível"
		_:
			return "não deu para comprar agora"
