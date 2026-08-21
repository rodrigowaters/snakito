class_name Jogo
extends Node2D
## Cena da partida: dona do GameEngine. A cada tick de física, entrega o input
## ao motor e manda o render/HUD refletirem o novo estado. NENHUMA regra de
## jogo aqui (regra dura #1).

const T := preload("res://src/ui/theme/tokens.gd")

const CENA_RESULTADO: String = "res://src/ui/resultado/resultado.tscn"
const CENA_HOME: String = "res://src/ui/home/home.tscn"

## Suavização da câmera (posição) e do zoom.
const CAMERA_SUAVIZACAO: float = 6.0
## Zoom BASE da câmera (cobra pequena). 1:1 no celular deixava tudo
## minúsculo — "a visibilidade está péssima" (playtest 10/08); 1.6 enquadra
## ~258×572 unidades: a cobra fica legível e a visão ainda cabe na tela.
const ZOOM_BASE: float = 1.6
## Piso do zoom-out ao crescer (abaixo disso volta a virar poeira).
const ZOOM_MIN: float = 0.85
## Pausa dramática entre o fim da partida e a tela de resultado.
const DELAY_RESULTADO_MORTE: float = 1.2
const DELAY_RESULTADO_TEMPO: float = 0.6
## Vibração na morte, em ms (docs §7; no desktop é no-op).
const VIBRACAO_MORTE_MS: int = 500

var motor: GameEngine
var render: ArenaRender
var camera: Camera2D
var hud: Hud
var efeitos: Efeitos

var _transicionando: bool = false
## Prêmio de 1ª conclusão de desafio creditado NESTA partida (0 = nenhum).
var _premio_desafio: int = 0
## A partida só ANDA depois do primeiro toque — sem isso a cobra sai andando
## sozinha na direção padrão e morre antes de o jogador se orientar
## ("não consigo jogar", playtest 10/08).
var _comecou: bool = false
## Início da partida em UTC — vai no payload da sessão (docs §6).
var _inicio_utc: String
# Estado do tick anterior, por id — para detectar eventos (comer/abate/morte)
# sem sujar o domínio com sinais.
var _comidas_previas: Dictionary[int, int] = {}
var _pontos_previos: Dictionary[int, int] = {}
var _abates_previos: Dictionary[int, int] = {}
var _vivas_previas: Dictionary[int, bool] = {}
var _cortes_sofridos_previos: int = 0
var _cortes_feitos_previos: int = 0

## Vibração ao SOFRER um corte (docs §2.7) — mais curta que a da morte.
const VIBRACAO_CORTE_MS: int = 150
## Vibração ao ABATER (clímax da caçada) — linguagem háptica completa:
## curta = fui ferido · média = cacei · longa = morri.
const VIBRACAO_ABATE_MS: int = 200


func _ready() -> void:
	_inicio_utc = Time.get_datetime_string_from_system(true) + "Z"
	motor = GameEngine.new(Sessao.config_para_jogar())

	render = ArenaRender.new()
	render.motor = motor
	add_child(render)

	efeitos = Efeitos.new()
	add_child(efeitos)

	camera = Camera2D.new()
	camera.position = motor.jogador().posicao
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	hud.sair_pedido.connect(_sair_para_home)
	add_child(hud)
	hud.atualizar(motor)
	render.registrar_tick()  # primeiro frame do mundo congelado
	_memorizar_estado()


func _physics_process(delta: float) -> void:
	if _transicionando:
		return
	if motor.estado == GameEngine.Estado.ENCERRADA:
		_transicionando = true
		_ir_para_resultado()
		return

	# Mundo congelado até o primeiro toque (bots também — justo).
	if not _comecou:
		if _direcao_do_input() != Vector2.ZERO:
			_comecou = true
			hud.esconder_convite_de_inicio()
		else:
			return

	motor.avancar(_direcao_do_input(), hud.turbo_desejado())
	_processar_eventos()
	render.registrar_tick()
	hud.atualizar(motor)
	_seguir_jogador(delta)

	# Desafio ativo: resolver (meta atingida ou falha) encerra a partida já.
	if Sessao.regras_desafio != null \
			and Sessao.regras_desafio.avaliar(motor) != ChallengeRules.Estado.EM_ANDAMENTO:
		if Sessao.regras_desafio.estado == ChallengeRules.Estado.CONCLUIDO:
			# Prêmio SÓ na primeira conclusão (desafios são lições fixas —
			# prêmio re-farmável quebraria a economia). Antes do marcar!
			if not ProgressoLocal.desafio_concluido(Sessao.regras_desafio.desafio):
				ProgressoLocal.adicionar_moedas(Economia.PREMIO_DESAFIO)
				_premio_desafio = Economia.PREMIO_DESAFIO
			ProgressoLocal.marcar_desafio_concluido(Sessao.regras_desafio.desafio)
		_transicionando = true
		_ir_para_resultado()


## Compara o estado com o tick anterior e dispara os feedbacks do docs §7.
func _processar_eventos() -> void:
	for cobra: SnakeModel in motor.arena.cobras:
		# Comeu → pulso de crescimento; jogador também vê os pontos subirem.
		var comidas_novas: int = cobra.comidas - _comidas_previas.get(cobra.id, cobra.comidas)
		if comidas_novas > 0 and cobra.viva:
			render.pulsar_crescimento(cobra.id)
			if cobra.eh_jogador():
				efeitos.pontos_flutuantes(
					cobra.posicao, comidas_novas * GameEngine.PONTOS_COMIDA)
		# Abateu (só jogador ganha rótulo — 30 bots geram spam).
		if cobra.eh_jogador() and cobra.abates > _abates_previos.get(cobra.id, cobra.abates):
			var delta_pontos: int = cobra.pontos - _pontos_previos.get(cobra.id, cobra.pontos)
			efeitos.pontos_flutuantes(
				cobra.posicao, delta_pontos - comidas_novas * GameEngine.PONTOS_COMIDA)
			render.pulsar_crescimento(cobra.id)
			if ProgressoLocal.vibracao():
				Input.vibrate_handheld(VIBRACAO_ABATE_MS)
		# Morreu neste tick → confete na cor da vítima; jogador ganha flash+háptica.
		if not cobra.viva and _vivas_previas.get(cobra.id, false):
			efeitos.confete(cobra.posicao, ArenaRender.cor_de(cobra))
			if cobra.eh_jogador():
				hud.flash_morte()
				if ProgressoLocal.vibracao():
					Input.vibrate_handheld(VIBRACAO_MORTE_MS)
	# Cortes do jogador (docs §2.7): sofreu → háptica curta; aplicou → pulso.
	var jogador: SnakeModel = motor.jogador()
	if jogador.cortes_sofridos > _cortes_sofridos_previos and ProgressoLocal.vibracao():
		Input.vibrate_handheld(VIBRACAO_CORTE_MS)
	if jogador.cortes_feitos > _cortes_feitos_previos:
		render.pulsar_crescimento(jogador.id)
	_cortes_sofridos_previos = jogador.cortes_sofridos
	_cortes_feitos_previos = jogador.cortes_feitos
	_memorizar_estado()


func _memorizar_estado() -> void:
	for cobra: SnakeModel in motor.arena.cobras:
		_comidas_previas[cobra.id] = cobra.comidas
		_pontos_previos[cobra.id] = cobra.pontos
		_abates_previos[cobra.id] = cobra.abates
		_vivas_previas[cobra.id] = cobra.viva


func _ir_para_resultado() -> void:
	Sessao.ultimo_motor = motor
	# Morte no ARCADE passa pelo Renascimento (blueprint 04b — morte suave);
	# desafio não: morte resolve o desafio e renascer quebraria a seed.
	if not motor.jogador().viva and Sessao.regras_desafio == null:
		await get_tree().create_timer(DELAY_RESULTADO_MORTE).timeout
		var renascimento: Renascimento = Renascimento.new()
		# A tela 04b é a tela de morte do design: aparece sempre. Sem
		# chance restante (já renasceu), as saídas de renascer ficam
		# desligadas — o interlúdio continua o mesmo.
		renascimento.permitir_renascer = motor.pode_renascer()
		add_child(renascimento)
		await renascimento.resolvido
		if renascimento.renascer and motor.renascer_jogador():
			renascimento.queue_free()
			# A morte já foi consumida: memorizar antes de voltar a rodar
			# evita redisparar os efeitos de morte no próximo tick.
			_memorizar_estado()
			_transicionando = false
			return
	else:
		var espera: float = DELAY_RESULTADO_TEMPO if motor.jogador().viva \
			else DELAY_RESULTADO_MORTE
		await get_tree().create_timer(espera).timeout
	# Estatísticas locais da conta (tela 02b): recorde e abates acumulados.
	ProgressoLocal.registrar_partida(motor.jogador().pontos, motor.jogador().abates)
	# Economia (docs §5): ~5% dos pontos viram moedas em TODA partida; o
	# prêmio de desafio (se houve) já foi creditado ao resolver.
	var moedas_partida: int = Economia.moedas_da_partida(motor.jogador().pontos)
	ProgressoLocal.adicionar_moedas(moedas_partida)
	Sessao.moedas_ganhas = moedas_partida + _premio_desafio
	# Toda partida encerrada entra na fila offline — logado ou não (docs §6);
	# a Rede despacha quando houver rede + login + perfil.
	FilaSessoes.enfileirar(_payload_da_sessao())
	Rede.despachar_fila()
	# Vitórias celebram primeiro (blueprint 12c): desafio concluído ou a
	# ARENA DOMINADA no Arcade; o resto vai direto à pós-partida.
	var desafio_concluido: bool = Sessao.regras_desafio != null \
		and Sessao.regras_desafio.estado == ChallengeRules.Estado.CONCLUIDO
	var arcade_dominado: bool = Sessao.regras_desafio == null and motor.arena_dominada()
	if desafio_concluido or arcade_dominado:
		get_tree().change_scene_to_file("res://src/ui/celebracao/celebracao.tscn")
	else:
		get_tree().change_scene_to_file(CENA_RESULTADO)


## Payload no formato do `submit_session` (limites validados no servidor).
func _payload_da_sessao() -> Dictionary:
	var jogador: SnakeModel = motor.jogador()
	var regras: ChallengeRules = Sessao.regras_desafio
	return {
		"seed": motor.rng.semente,
		"started_at": _inicio_utc,
		"duration_seconds": maxi(1, int(motor.segundos_decorridos())),
		"final_rank": motor.posicao_no_ranking(jogador),
		"score": jogador.pontos,
		"size_reached": jogador.nivel,  # nível = pico (monotônico, §2.7)
		"kills": jogador.abates,
		"food_eaten": jogador.comidas,
		"challenge": int(regras.desafio) if regras != null else null,
		"challenge_completed": (regras.estado == ChallengeRules.Estado.CONCLUIDO) \
			if regras != null else null,
		# Desafio nunca aplica buffs (config zera); Arcade envia os níveis reais.
		"buff_speed_level": motor.config.nivel_velocidade,
		"buff_magnet_level": motor.config.nivel_ima,
		"buff_start_points_level": motor.config.nivel_pontos_iniciais,
		"client_version": Rede.VERSAO_CLIENTE,
	}


## Joystick tem prioridade; teclado (setas/WASD via ações ui_*) serve ao
## desenvolvimento no desktop.
func _direcao_do_input() -> Vector2:
	var direcao: Vector2 = hud.joystick.direcao()
	if direcao == Vector2.ZERO:
		direcao = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	return direcao


## Câmera segue o jogador; o zoom abre conforme a visão cresce — é a leitura
## de render do "quanto maior, maior o raio de visão" (docs §2.2).
func _seguir_jogador(delta: float) -> void:
	var jogador: SnakeModel = motor.jogador()
	camera.position = camera.position.lerp(jogador.posicao, minf(1.0, CAMERA_SUAVIZACAO * delta))
	var alvo_zoom: float = clampf(
		ZOOM_BASE * SnakeModel.VISAO_BASE / jogador.raio_visao(), ZOOM_MIN, ZOOM_BASE)
	var zoom_atual: float = lerpf(camera.zoom.x, alvo_zoom, minf(1.0, CAMERA_SUAVIZACAO * delta))
	camera.zoom = Vector2(zoom_atual, zoom_atual)


func _sair_para_home() -> void:
	get_tree().change_scene_to_file(CENA_HOME)
