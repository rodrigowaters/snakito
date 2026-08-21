extends SceneTree
## Screenshots da ficha da Play Store (portrait 412×915, o mesmo do design).
##   godot --path . --quit-after 300 -s tools/gerar_screenshots.gd
## Precisa de JANELA — headless não renderiza.
##
## Saída: assets/loja/screenshots/1_arena.png … 5_loja.png
##
## A primeira é GAMEPLAY REAL: a cena roda de verdade e um piloto simples
## dirige a cobra pelas ações `ui_*` (o fallback de teclado do joystick)
## caçando a comida mais próxima. Motivo: um roteiro fixo de curvas deixava
## a cobra em tamanho 1 e "30º de 31" — vitrine tem que mostrar uma cobra
## CRESCIDA, que é o que o jogo vira depois de um minuto.

const PASTA: String = "res://assets/loja/screenshots"

## Ticks de partida antes da foto (60 = 1s). ~50s dá uma cobra de bom
## tamanho sem chegar no fim do relógio de 3 min.
const TICKS_DE_PARTIDA: int = 3000
## De quantos em quantos ticks o piloto reavalia o alvo.
const CADENCIA_PILOTO: int = 8
const ACOES: Array[StringName] = [&"ui_right", &"ui_left", &"ui_down", &"ui_up"]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	_rodar.call_deferred()


func _rodar() -> void:
	# Arcade com bots (a config padrão): partida cheia, como o jogador vê.
	Sessao.desafio_pendente = -1
	Sessao.proxima_semente = 20260821  # arena bonita e reprodutível
	if "--candidatos" in OS.get_cmdline_user_args():
		await _capturar_candidatos()
		quit(0)
		return
	await _capturar_gameplay()

	# Pós-partida da partida que ACABOU de rodar (motor real, números reais).
	await _capturar_cena("res://src/ui/resultado/resultado.tscn", "2_resultado.png", 45)
	_preparar_progresso()
	await _capturar_cena("res://src/ui/home/home.tscn", "3_home.png", 40)
	await _capturar_cena("res://src/ui/desafios/desafios.tscn", "4_desafios.png", 40)
	load("res://src/ui/loja/loja.gd").set("proxima_aba", 0)  # aba Skins
	await _capturar_cena("res://src/ui/loja/loja.tscn", "5_loja.png", 40)
	quit(0)


## Estado local REPRESENTATIVO para as telas de menu: um jogador que já
## jogou. Sem isso a Home aparece com a modal da recompensa diária em cima
## (é a 1ª abertura do dia) e tudo zerado — vitrine tem que mostrar o app
## em uso, e este é um estado que o jogo alcança de verdade.
func _preparar_progresso() -> void:
	Economia.coletar_diaria()  # some com a modal do dia
	ProgressoLocal.adicionar_moedas(480 - ProgressoLocal.moedas())
	ProgressoLocal.adicionar_tickets(3 - ProgressoLocal.tickets())
	ProgressoLocal.marcar_desafio_concluido(ChallengeRules.Desafio.FARMING_PURO)
	ProgressoLocal.marcar_desafio_concluido(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)


## Roda a partida de verdade, com piloto caçando comida, e fotografa.
func _capturar_gameplay() -> void:
	change_scene_to_file("res://src/scenes/jogo/jogo.tscn")
	await process_frame
	await process_frame
	var jogo: Node = current_scene
	for tick: int in TICKS_DE_PARTIDA:
		if tick % CADENCIA_PILOTO == 0:
			_pilotar(jogo)
		await physics_frame
		# Morreu antes da foto? Recomeça — vitrine não mostra derrota.
		var motor: GameEngine = jogo.get("motor") as GameEngine
		if motor == null or not motor.jogador().viva:
			break
	for acao: StringName in ACOES:
		Input.action_release(acao)
	for i: int in 5:
		await process_frame
	_salvar("1_arena.png")
	# A tela de resultado lê o motor da última partida — e as moedas, que
	# normalmente são creditadas no fim de `jogo.gd` (o piloto não passa
	# por lá). Sem isso a foto mostra "Moedas ganhas +0", que é falso.
	var motor_final: GameEngine = jogo.get("motor") as GameEngine
	Sessao.ultimo_motor = motor_final
	Sessao.moedas_ganhas = Economia.moedas_da_partida(motor_final.jogador().pontos)


## Fotografa a partida em VÁRIOS momentos: a cobra cresce e encolhe (corte,
## abate), então o melhor quadro é escolhido olhando, não confiando na
## sorte de um instante único. `--candidatos` gera a série.
func _capturar_candidatos() -> void:
	change_scene_to_file("res://src/scenes/jogo/jogo.tscn")
	await process_frame
	await process_frame
	var jogo: Node = current_scene
	var proxima_foto: int = 900
	var numero: int = 1
	for tick: int in 6000:
		if tick % CADENCIA_PILOTO == 0:
			_pilotar(jogo)
		await physics_frame
		var motor: GameEngine = jogo.get("motor") as GameEngine
		if motor == null or not motor.jogador().viva:
			break
		if tick >= proxima_foto:
			var eu: SnakeModel = motor.jogador()
			_salvar("candidato_%d_nivel%d_pts%d.png" % [numero, eu.nivel, eu.pontos])
			numero += 1
			proxima_foto += 450
	for acao: StringName in ACOES:
		Input.action_release(acao)


## Piloto de vitrine: aponta para a comida mais próxima, desviando de quem
## pode devorar a gente. Não é o bot do jogo (aquele é do domínio) — é só
## o suficiente para a cobra crescer e a foto ter vida.
func _pilotar(jogo: Node) -> void:
	var motor: GameEngine = jogo.get("motor") as GameEngine
	if motor == null:
		return
	var eu: SnakeModel = motor.jogador()
	if not eu.viva:
		return
	var rumo: Vector2 = Vector2.ZERO
	var perto: float = INF
	for comida: Vector2 in motor.arena.comidas:
		var distancia: float = eu.posicao.distance_to(comida)
		if distancia < perto:
			perto = distancia
			rumo = (comida - eu.posicao).normalized()
	# Fuga tem prioridade: quem pode nos devorar empurra o rumo pra longe.
	for cobra: SnakeModel in motor.arena.cobras_vivas():
		if cobra.eh_jogador() or not cobra.pode_devorar(eu):
			continue
		var delta: Vector2 = eu.posicao - cobra.posicao
		if delta.length() < eu.raio_visao() * 0.5:
			rumo += delta.normalized() * 2.0
	# Borda empurra para o centro: a arena termina em vazio e uma faixa
	# escura no topo da foto parece bug, não jogo.
	var limites: Rect2 = motor.arena.limites()
	# Empurrão FRACO e só bem perto: com peso alto (1.5/700u) o piloto
	# passava a orbitar a margem e parava de comer — travou no nível 41.
	var margem: float = 350.0
	var peso: float = 0.5
	if eu.posicao.x < limites.position.x + margem:
		rumo += Vector2.RIGHT * peso
	elif eu.posicao.x > limites.end.x - margem:
		rumo += Vector2.LEFT * peso
	if eu.posicao.y < limites.position.y + margem:
		rumo += Vector2.DOWN * peso
	elif eu.posicao.y > limites.end.y - margem:
		rumo += Vector2.UP * peso
	if rumo == Vector2.ZERO:
		rumo = Vector2.RIGHT
	rumo = rumo.normalized()
	# Traduz o rumo em ações (o joystick lê `ui_*` como fallback).
	Input.action_release(&"ui_right") if rumo.x < 0.0 else Input.action_press(&"ui_right")
	Input.action_release(&"ui_left") if rumo.x > 0.0 else Input.action_press(&"ui_left")
	Input.action_release(&"ui_down") if rumo.y < 0.0 else Input.action_press(&"ui_down")
	Input.action_release(&"ui_up") if rumo.y > 0.0 else Input.action_press(&"ui_up")


func _capturar_cena(caminho: String, nome: String, frames: int) -> void:
	change_scene_to_file(caminho)
	for i: int in frames:
		await process_frame
	_esconder_botoes_de_debug(current_scene)
	await process_frame
	_salvar(nome)


## O gatilho de crash do Sentry só existe em build de debug — e TODA
## captura roda em debug. Numa foto de vitrine ele parece bug do jogo.
func _esconder_botoes_de_debug(no: Node) -> void:
	if no is Button and "Crash" in (no as Button).text:
		(no as Button).visible = false
	for filho: Node in no.get_children():
		_esconder_botoes_de_debug(filho)


func _salvar(nome: String) -> void:
	var imagem: Image = root.get_texture().get_image()
	var destino: String = "%s/%s" % [PASTA, nome]
	var erro: Error = imagem.save_png(destino)
	print("screenshot: %s (%dx%d, erro=%d)"
		% [nome, imagem.get_width(), imagem.get_height(), erro])
