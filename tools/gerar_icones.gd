extends SceneTree
## Rasteriza os ícones do Snakito a partir dos SVGs do design.
##   godot --headless --quit-after 60 -s tools/gerar_icones.gd
##
## Saídas (versionadas — o export do Android precisa dos PNGs):
##   assets/icone/png/launcher_192.png      · ícone clássico do launcher
##   assets/icone/png/adaptativo_frente.png · camada de frente (Android 8+)
##   assets/icone/png/adaptativo_fundo.png  · camada de fundo
##   assets/icone/png/loja_512.png          · ficha da Play Store
##
## Por que rasterizar aqui: o Godot já importa SVG (thorvg) e o `sips` do
## macOS não converte SVG. Assim o PNG é sempre derivado do SVG do design,
## sem editor de imagem no meio.

const SAIDAS: Array[Dictionary] = [
	{"svg": "res://assets/icone/icon.svg", "png": "launcher_192.png", "lado": 192},
	{"svg": "res://assets/icone/icone_frente.svg", "png": "adaptativo_frente.png", "lado": 432},
	{"svg": "res://assets/icone/icone_fundo.svg", "png": "adaptativo_fundo.png", "lado": 432},
	{"svg": "res://assets/icone/icon.svg", "png": "loja_512.png", "lado": 512},
]


func _initialize() -> void:
	var pasta: String = "res://assets/icone/png"
	DirAccess.make_dir_recursive_absolute(pasta)
	var falhas: int = 0
	for saida: Dictionary in SAIDAS:
		var textura: Texture2D = load(saida.svg) as Texture2D
		if textura == null:
			printerr("não carregou: ", saida.svg)
			falhas += 1
			continue
		var imagem: Image = textura.get_image()
		imagem.decompress()
		var lado: int = int(saida.lado)
		imagem.resize(lado, lado, Image.INTERPOLATE_LANCZOS)
		var destino: String = "%s/%s" % [pasta, saida.png]
		var erro: Error = imagem.save_png(destino)
		print("%s  %dx%d  (erro=%d)" % [saida.png, lado, lado, erro])
		if erro != OK:
			falhas += 1
	quit(1 if falhas > 0 else 0)
