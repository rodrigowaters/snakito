class_name Conta
extends Control
## Tela de conta (docs §4.1): login APENAS via Google Sign-In. Três estados:
## deslogado → botão Google; logado sem perfil → escolher apelido;
## logado com perfil → resumo + sair.
## O plugin nativo do Google ainda não está integrado (pendência: OAuth
## clients + provider no painel) — o botão avisa quando indisponível.

const T := preload("res://src/ui/theme/tokens.gd")

var _coluna: VBoxContainer


func _ready() -> void:
	_montar_fundo()
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, T.ESP_LG)
	margem.add_theme_constant_override("margin_top", T.ESP_2XL)
	margem.add_theme_constant_override("margin_bottom", T.ESP_XL)
	add_child(margem)
	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", T.ESP_MD)
	margem.add_child(_coluna)
	Rede.sessao_mudou.connect(_remontar)
	_remontar()


func _remontar() -> void:
	for filho: Node in _coluna.get_children():
		filho.queue_free()
	var titulo: Label = Label.new()
	titulo.text = "Conta"
	titulo.theme_type_variation = &"TituloHero"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(titulo)

	if not Rede.logado():
		_montar_deslogado()
	elif not Rede.tem_perfil():
		_montar_criar_perfil()
	else:
		_montar_logado()

	var voltar: Button = Button.new()
	voltar.text = "Voltar"
	voltar.theme_type_variation = &"BotaoSecundario"
	voltar.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/ui/home/home.tscn"))
	_coluna.add_child(voltar)


func _montar_deslogado() -> void:
	_texto("Sua conta guarda o ranking global e as skins.\nO jogo continua 100% jogável sem ela.", &"TextoSecundario")
	var google: Button = Button.new()
	google.text = "Entrar com Google"
	google.theme_type_variation = &"BotaoPrimario"
	var disponivel: bool = Engine.has_singleton("GoogleSignIn") and _web_client_id() != ""
	google.disabled = not disponivel
	google.pressed.connect(_entrar_com_google)
	_coluna.add_child(google)
	if not disponivel:
		_texto("Login disponível no aparelho Android", &"TextoMuted")


func _montar_criar_perfil() -> void:
	_texto("Escolha seu apelido na arena.\nSem nome real — é público no ranking!", &"TextoSecundario")
	var campo: LineEdit = LineEdit.new()
	campo.placeholder_text = "ex.: CobraVeloz"
	campo.max_length = 20
	_coluna.add_child(campo)
	var erro: Label = _texto("", &"TextoPerigo")
	var criar: Button = Button.new()
	criar.text = "Criar perfil"
	criar.theme_type_variation = &"BotaoPrimario"
	criar.pressed.connect(func() -> void:
		criar.disabled = true
		var motivo: String = await Rede.criar_perfil(campo.text.strip_edges())
		if motivo != "":
			erro.text = motivo
			criar.disabled = false)
	_coluna.add_child(criar)


func _montar_logado() -> void:
	_texto("Olá, %s!" % Rede.username(), &"TituloMd")
	var pendentes: int = FilaSessoes.tamanho()
	if pendentes > 0:
		_texto("%d partida(s) aguardando envio" % pendentes, &"TextoSecundario")
	else:
		_texto("Todas as partidas sincronizadas ✓", &"TextoSucesso")
	var sair: Button = Button.new()
	sair.text = "Sair da conta"
	sair.theme_type_variation = &"BotaoDestrutivo"
	sair.pressed.connect(Rede.sair)
	_coluna.add_child(sair)


## Audiência do token: o OAuth client WEB (o mesmo do provider no Supabase).
## Vem do override.cfg (fora do git, dentro do export) — é público por design.
func _web_client_id() -> String:
	return str(ProjectSettings.get_setting("google/web_client_id", ""))


func _entrar_com_google() -> void:
	var plugin: Object = Engine.get_singleton("GoogleSignIn")
	plugin.connect("token_recebido", _ao_receber_token, CONNECT_ONE_SHOT)
	plugin.connect("falhou", _ao_falhar_google, CONNECT_ONE_SHOT)
	plugin.call("solicitar", _web_client_id())


func _ao_receber_token(id_token: String) -> void:
	if await Rede.entrar_com_google(id_token):
		_remontar()  # sessao_mudou também dispara; garantia extra
	else:
		_ao_falhar_google("supabase_recusou")


func _ao_falhar_google(codigo: String) -> void:
	push_warning("Conta: login Google falhou (%s)" % codigo)
	_remontar()
	_texto("Não deu para entrar agora (%s).\nTente de novo." % codigo, &"TextoPerigo")


func _texto(conteudo: String, variacao: StringName) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = conteudo
	rotulo.theme_type_variation = variacao
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coluna.add_child(rotulo)
	return rotulo


func _montar_fundo() -> void:
	var gradiente: Gradient = Gradient.new()
	gradiente.colors = PackedColorArray([T.COR_APP_FUNDO_INICIO, T.COR_APP_FUNDO_FIM])
	var textura: GradientTexture2D = GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2.ZERO
	textura.fill_to = Vector2.DOWN.rotated(deg_to_rad(T.APP_FUNDO_ANGULO - 180.0))
	var fundo: TextureRect = TextureRect.new()
	fundo.texture = textura
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
