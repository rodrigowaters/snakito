extends SceneTree
## Playtest dirigido dos efeitos do docs §7: monta um roteiro determinístico
## (comer → abater → morrer) manipulando o estado do motor em momentos
## conhecidos e captura frames para inspeção visual.
##   godot --resolution 412x915 -s tools/playtest_dirigido.gd -- <dir_saida>
## Precisa de janela (headless não renderiza). Duração ~10s; fecha sozinho.

var _dir: String
var _contador: int = 0


func _initialize() -> void:
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	if argumentos.is_empty():
		printerr("uso: godot -s tools/playtest_dirigido.gd -- <dir_saida>")
		quit(1)
		return
	_dir = argumentos[0]
	Sessao.proxima_semente = 42
	change_scene_to_file("res://src/scenes/jogo/jogo.tscn")
	_roteiro.call_deferred()


func _roteiro() -> void:
	await process_frame
	await process_frame
	var jogo: Jogo = current_scene as Jogo
	var motor: GameEngine = jogo.motor
	var jogador: SnakeModel = motor.jogador()

	# Palco limpo: bots para o canto oposto (longe demais para interferir no
	# roteiro) e nenhuma comida aleatória.
	for cobra: SnakeModel in motor.arena.cobras:
		if not cobra.eh_jogador():
			cobra.posicao = Vector2(2200.0, 2200.0) + Vector2(cobra.id * 7.0, cobra.id * 3.0)
	motor.config.qtd_comida = 0
	motor.arena.comidas.clear()

	print("FASE 1 — comer (pulso + '+10' flutuando)")
	motor.arena.comidas.append(jogador.posicao + Vector2(60.0, 0.0))
	await _capturar(12, 3)  # ~0.6s: aproximação, comer, pulso, rótulo

	print("FASE 2 — abater (confete + pontos flutuando)")
	jogador.tamanho = 12
	jogador.nivel = 12
	var vitima: SnakeModel = SnakeModel.new(
		_id_sem_decisao_imediata(motor.tick_atual),
		SnakeModel.Personalidade.FAZENDEIRO,
		jogador.posicao + Vector2(42.0, 0.0),
		1,
	)
	vitima.direcao = Vector2.LEFT  # vem de encontro; morre antes de decidir fugir
	motor.arena.adicionar_cobra(vitima)
	await _capturar(12, 3)

	print("FASE 3 — morrer (flash vermelho + pausa dramática)")
	var predadora: SnakeModel = SnakeModel.new(
		950, SnakeModel.Personalidade.CACADOR, jogador.posicao + Vector2(50.0, 0.0), 60)
	predadora.direcao = Vector2.LEFT
	motor.arena.adicionar_cobra(predadora)
	await _capturar(14, 3)

	print("FASE 4 — transição para o resultado")
	for i: int in 80:  # cobre o delay de 1.2s
		await process_frame
	await _capturar(2, 5)

	print("capturas em ", _dir, " (", _contador, " frames)")
	quit(0)


## Id de bot cuja PRIMEIRA decisão não cai nos 2 próximos ticks — a vítima
## precisa sobreviver 1 tick (para entrar no cache de eventos) e morrer
## antes de fugir.
func _id_sem_decisao_imediata(tick: int) -> int:
	for id: int in range(900, 912):
		if (tick + 1 + id) % BotEngine.TICKS_REACAO != 0 \
				and (tick + 2 + id) % BotEngine.TICKS_REACAO != 0:
			return id
	return 900  # inalcançável


func _capturar(quantidade: int, a_cada: int) -> void:
	for i: int in quantidade:
		for j: int in a_cada:
			await process_frame
		var imagem: Image = root.get_texture().get_image()
		imagem.save_png("%s/frame_%03d.png" % [_dir, _contador])
		_contador += 1
