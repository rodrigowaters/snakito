@tool
extends EditorPlugin
## Empacota o AAR do Google Sign-In no build Android e declara as
## dependências maven remotas (resolvidas pelo gradle do jogo).

var export_plugin: SignInExportPlugin


func _enter_tree() -> void:
	export_plugin = SignInExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class SignInExportPlugin extends EditorExportPlugin:
	const NOME := "GoogleSignIn"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var variante: String = "debug" if debug else "release"
		return PackedStringArray([NOME + "/bin/%s/%s-%s.aar" % [variante, NOME, variante]])

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"androidx.credentials:credentials:1.5.0",
			"androidx.credentials:credentials-play-services-auth:1.5.0",
			"com.google.android.libraries.identity.googleid:googleid:1.1.1",
		])

	func _get_name() -> String:
		return NOME
