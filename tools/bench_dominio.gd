extends SceneTree
## Benchmark do domínio puro: quanto custa um tick da arena padrão do spike
## (30 bots + 80 comidas)? Orçamento a 60fps = 16.6ms/frame TOTAL; o domínio
## precisa ser fração disso para sobrar tempo de render no aparelho.
##   godot --headless -s tools/bench_dominio.gd


func _initialize() -> void:
	var motor: GameEngine = GameEngine.new(GameEngine.ConfigPartida.padrao(1))
	var alvo: int = motor.config.duracao_seg * GameEngine.TICKS_POR_SEGUNDO
	var executados: int = 0
	var inicio: int = Time.get_ticks_usec()
	for t: int in alvo:
		motor.avancar(Vector2.RIGHT.rotated(float(t) * 0.01))
		executados = t + 1
		if motor.estado == GameEngine.Estado.ENCERRADA:
			break
	var total_ms: float = float(Time.get_ticks_usec() - inicio) / 1000.0
	print("partida: %d ticks (%.0fs de jogo) | total %.1fms | média %.4fms/tick" % [
		executados, executados / 60.0, total_ms, total_ms / float(executados),
	])
	print("orçamento de frame a 60fps: 16.667ms")
	quit()
