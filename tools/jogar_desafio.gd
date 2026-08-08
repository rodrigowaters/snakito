extends SceneTree
## Abre o jogo direto num desafio — teste manual enquanto a tela de seleção
## de desafios não existe (M1):
##   godot -s tools/jogar_desafio.gd -- 1    (Desafio 1 · farming puro)
##   godot -s tools/jogar_desafio.gd -- 2    (Desafio 2 · agressão controlada)


func _initialize() -> void:
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	var numero: int = int(argumentos[0]) if argumentos.size() > 0 else 2
	Sessao.desafio_pendente = int(ChallengeRules.Desafio.FARMING_PURO) if numero == 1 \
		else int(ChallengeRules.Desafio.AGRESSAO_CONTROLADA)
	change_scene_to_file("res://src/scenes/jogo/jogo.tscn")
