extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready():
	$CPUParticles2D.emitting = true
	await get_tree().create_timer($CPUParticles2D.lifetime).timeout
	
	queue_free()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_released("attack"):
		particles.restart()
		particles.emitting = true
		
