extends SceneTree
## Captura um screenshot de uma cena para verificação visual sem editor:
##   godot -s tools/capturar_tela.gd -- <res://cena.tscn> <saida.png> [frames]
## Precisa rodar COM janela (headless não renderiza). A janela fecha sozinha.


func _initialize() -> void:
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	if argumentos.size() < 2:
		printerr("uso: godot -s tools/capturar_tela.gd -- <cena> <saida.png> [frames]")
		quit(1)
		return
	var frames: int = int(argumentos[2]) if argumentos.size() > 2 else 90
	change_scene_to_file(argumentos[0])
	_capturar.call_deferred(argumentos[1], frames)


func _capturar(saida: String, frames: int) -> void:
	for i: int in frames:
		await process_frame
	var imagem: Image = root.get_texture().get_image()
	var erro: Error = imagem.save_png(saida)
	print("captura: ", saida, " (erro=", erro, ")")
	quit(0 if erro == OK else 1)
