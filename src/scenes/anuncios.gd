extends Node
## Autoload `Anuncios` — única porta do jogo para o AdMob (docs §5).
## SÓ anúncio RECOMPENSADO (decisão 17/08: é o único formato que os
## blueprints/economia usam — buff sem saldo, renascer; banner/interstitial
## ficam fora até o design prever um lugar). Política de Famílias:
## `tagForChildDirectedTreatment` + TFUA + conteúdo classificação G,
## configurados ANTES do initialize; consentimento via UMP.
##
## Fora do Android o serviço fica inerte (`recompensado_disponivel()` =
## false) — a UI degrada para os placeholders esmaecidos de sempre.
##
## IDs: build de DEBUG sempre usa o bloco de TESTE do Google — usar ID de
## produção em playtest é o caminho conhecido para suspensão por tráfego
## inválido. Release usa `ID_RECOMPENSADO_PRODUCAO` (vazio = sem anúncio,
## nunca cai no de teste em release). O App ID vive em `project.godot`
## (`admob/general/android/app_id`), de onde o export do plugin o injeta
## no manifest; não é segredo — ele ship em todo APK publicado.

signal disponibilidade_mudou

## Bloco de demonstração público do Google (sempre devolve "Test Ad").
const ID_RECOMPENSADO_TESTE: String = "ca-app-pub-3940256099942544/5224354917"
## Bloco "Recompensado" do Snakito (formato Premiado — opt-in explícito, o
## único que casa com as nossas telas). Criado em 20/08; só é usado em
## RELEASE. Vazio faria release rodar sem anúncio, nunca cair no de teste.
const ID_RECOMPENSADO_PRODUCAO: String = "ca-app-pub-4383856231212698/1017525581"

var _recompensado: RewardedAd = null
var _carregando: bool = false
## Callable a premiar quando o anúncio em exibição pagar (docs: só entrega
## a recompensa no on_user_earned_reward — fechar antes da hora não paga).
var _ao_premiar: Callable = Callable()


## Log só em debug, prefixo `Anuncios:` (mesma convenção do `Rede:`). Sem
## isso não há como saber de que lado o fluxo parou — o logcat do SDK é
## verboso e não diz nada sobre as NOSSAS decisões.
func _log(mensagem: String) -> void:
	if OS.is_debug_build():
		print("Anuncios: ", mensagem)


func _ready() -> void:
	if OS.get_name() != "Android":
		_log("fora do Android — serviço inerte")
		return
	_log("iniciando (bloco %s)" % _id_recompensado())
	_configurar_familias()
	_atualizar_consentimento()


## Bloco a carregar: teste em debug, produção em release.
func _id_recompensado() -> String:
	if OS.is_debug_build():
		return ID_RECOMPENSADO_TESTE
	return ID_RECOMPENSADO_PRODUCAO


func recompensado_disponivel() -> bool:
	return _recompensado != null


## Mostra o anúncio carregado; `ao_premiar` roda SÓ se a recompensa for
## concedida (assistiu até o fim). O próximo anúncio carrega em seguida.
func mostrar_recompensado(ao_premiar: Callable) -> void:
	if _recompensado == null:
		return
	_ao_premiar = ao_premiar
	_log("exibindo recompensado")
	var ouvinte: OnUserEarnedRewardListener = OnUserEarnedRewardListener.new()
	ouvinte.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_log("recompensa CONCEDIDA")
		if _ao_premiar.is_valid():
			_ao_premiar.call()
		_ao_premiar = Callable()
	_recompensado.show(ouvinte)


# ------------------------------------------------------------------ internos

## COPPA/TFUA + classificação G — público 7+, política de Famílias.
func _configurar_familias() -> void:
	var config: RequestConfiguration = RequestConfiguration.new()
	config.tag_for_child_directed_treatment = \
		RequestConfiguration.TagForChildDirectedTreatment.TRUE
	config.tag_for_under_age_of_consent = \
		RequestConfiguration.TagForUnderAgeOfConsent.TRUE
	config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	MobileAds.set_request_configuration(config)
	_log("config de Famílias aplicada (tfcd=1, tfua=1, rating=G)")


## Fluxo UMP: atualiza o estado de consentimento e mostra o formulário se
## a região exigir; o SDK inicializa em qualquer desfecho (app infantil
## serve anúncios não personalizados — o UMP raramente exige formulário).
func _atualizar_consentimento() -> void:
	var parametros: ConsentRequestParameters = ConsentRequestParameters.new()
	parametros.tag_for_under_age_of_consent = true
	UserMessagingPlatform.consent_information.update(
		parametros,
		func() -> void:
			_log("consentimento atualizado (status %d)"
				% UserMessagingPlatform.consent_information.get_consent_status())
			if UserMessagingPlatform.consent_information.get_is_consent_form_available():
				UserMessagingPlatform.load_consent_form(
					_ao_carregar_formulario,
					func(_erro: FormError) -> void: _inicializar())
			else:
				_inicializar(),
		func(erro: FormError) -> void:
			_log("consentimento falhou (%s) — inicializando de todo jeito" % erro.message)
			_inicializar())


func _ao_carregar_formulario(formulario: ConsentForm) -> void:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	if info.get_consent_status() == info.ConsentStatus.REQUIRED:
		formulario.show(func(_erro: FormError) -> void: _inicializar())
	else:
		_inicializar()


func _inicializar() -> void:
	var ouvinte: OnInitializationCompleteListener = OnInitializationCompleteListener.new()
	ouvinte.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_log("SDK inicializado")
		# Reaplica a config de Famílias APÓS o initialize: o SDK do Google
		# auto-inicializa pelo App ID do manifest, então a config feita no
		# nosso `_ready` pode chegar tarde — o request de 20/08 saiu com
		# `tfcd=0&tfua=0` (visto no logcat) apesar de configurada antes.
		# Barato e idempotente; a verificação é o logcat mostrar tfcd=1.
		_configurar_familias()
		_carregar_recompensado()
	MobileAds.initialize(ouvinte)


func _carregar_recompensado() -> void:
	if _carregando or _recompensado != null:
		return
	var bloco: String = _id_recompensado()
	if bloco == "":
		push_warning("Anuncios: sem bloco de produção configurado — release sem anúncio")
		return
	_carregando = true
	_log("carregando bloco %s" % bloco)
	var retorno: RewardedAdLoadCallback = RewardedAdLoadCallback.new()
	retorno.on_ad_loaded = func(anuncio: RewardedAd) -> void:
		_log("anúncio CARREGADO")
		_carregando = false
		anuncio.full_screen_content_callback = _retorno_de_exibicao()
		_recompensado = anuncio
		disponibilidade_mudou.emit()
	retorno.on_ad_failed_to_load = func(erro: LoadAdError) -> void:
		_log("falha ao carregar: %s (código %d)" % [erro.message, erro.code])
		_carregando = false
		# Sem rede/estoque: tenta de novo mais tarde, sem martelar.
		get_tree().create_timer(30.0).timeout.connect(_carregar_recompensado)
	RewardedAdLoader.new().load(bloco, AdRequest.new(), retorno)


func _retorno_de_exibicao() -> FullScreenContentCallback:
	var retorno: FullScreenContentCallback = FullScreenContentCallback.new()
	retorno.on_ad_dismissed_full_screen_content = func() -> void:
		_descartar_e_recarregar()
	retorno.on_ad_failed_to_show_full_screen_content = func(_erro: AdError) -> void:
		_ao_premiar = Callable()
		_descartar_e_recarregar()
	return retorno


func _descartar_e_recarregar() -> void:
	if _recompensado != null:
		_recompensado.destroy()
		_recompensado = null
	disponibilidade_mudou.emit()
	_carregar_recompensado()
