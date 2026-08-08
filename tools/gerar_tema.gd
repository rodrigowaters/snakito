@tool
extends EditorScript
## Regenerador do tema — casca fina para o editor.
##
## USO: com o projeto aberto no editor Godot, abra este script e rode com
## Arquivo > Executar (Cmd/Ctrl+Shift+X). Commite o `.tres` resultante.
##
## A lógica de construção vive em `tema_builder.gd` (RefCounted estático),
## porque `EditorScript` só instancia dentro do editor e a regeneração também
## precisa rodar headless (validação local e CI).

const TemaBuilder := preload("res://tools/tema_builder.gd")


func _run() -> void:
	if TemaBuilder.gerar_e_salvar() == OK:
		print("Tema regenerado: ", TemaBuilder.CAMINHO_SAIDA)
