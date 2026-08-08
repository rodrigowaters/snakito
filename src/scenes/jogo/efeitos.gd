class_name Efeitos
extends Node2D
## Efeitos visuais da partida (docs §7): confete de kill e pontos flutuando.
## Camada de RENDER pura — nasce dos eventos que o jogo detecta no estado do
## motor, nunca altera o domínio. Cores vêm da paleta; números de tuning de
## partícula são constantes documentadas aqui.

const T := preload("res://src/ui/theme/tokens.gd")

## Quanto o rótulo de pontos sobe (unidades de mundo) e em quanto tempo.
const FLUTUACAO_ALTURA: float = 60.0
const FLUTUACAO_DURACAO: float = 0.8
## Tuning do confete de kill (docs §7: "confete no local").
const CONFETE_QTD: int = 24
const CONFETE_VIDA: float = 0.7
const CONFETE_VEL_MIN: float = 120.0
const CONFETE_VEL_MAX: float = 260.0
const CONFETE_GRAVIDADE: float = 320.0


## "+N" subindo e sumindo na posição do evento (docs §7: pontos flutuando).
func pontos_flutuantes(posicao: Vector2, valor: int) -> void:
	if valor <= 0:
		return
	var rotulo: Label = Label.new()
	rotulo.text = "+%d" % valor
	rotulo.theme_type_variation = &"TextoSucesso"
	rotulo.position = posicao
	rotulo.z_index = 10
	add_child(rotulo)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(rotulo, "position:y", posicao.y - FLUTUACAO_ALTURA, FLUTUACAO_DURACAO) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(rotulo, "modulate:a", 0.0, FLUTUACAO_DURACAO) \
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(rotulo.queue_free)


## Explosão de confete na cor da cobra devorada.
func confete(posicao: Vector2, cor: Color) -> void:
	var particulas: GPUParticles2D = GPUParticles2D.new()
	particulas.position = posicao
	particulas.amount = CONFETE_QTD
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.lifetime = CONFETE_VIDA
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = CONFETE_VEL_MIN
	material.initial_velocity_max = CONFETE_VEL_MAX
	material.gravity = Vector3(0.0, CONFETE_GRAVIDADE, 0.0)
	material.scale_min = 2.0
	material.scale_max = 4.5
	material.color = cor
	particulas.process_material = material
	add_child(particulas)
	particulas.emitting = true
	# Libera o nó depois que todas as partículas morreram.
	get_tree().create_timer(CONFETE_VIDA + 0.5).timeout.connect(particulas.queue_free)
