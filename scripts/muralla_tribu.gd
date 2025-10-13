extends Area2D

signal muralla_destruida

@export var health: int = 100
@onready var muralla_1: Sprite2D = $Muralla
@onready var muralla_2: Sprite2D = $Muralla2
@onready var muralla_collision: CollisionShape2D = $MurallaCollision
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D

var damage_flash_count: int = 2        # cantidad de parpadeos
var damage_flash_duration: float = 0.1 # duración de cada parpadeo
var flash_counter: int = 0
var flash_timer: Timer
var destroyed := false

func _ready() -> void:
	add_to_group("Muralla")
	$Explotion.hide()
	
	# Timer interno para efecto de daño
	flash_timer = Timer.new()
	flash_timer.one_shot = false
	add_child(flash_timer)
	flash_timer.timeout.connect(_on_flash_timer_timeout)

	# Asegurar que el StaticBody2D bloquee, pero esta Area2D reciba daño
	monitorable = true
	monitoring = true

func is_destroyed() -> bool:
	return destroyed
	
func take_damage(amount: int) -> void:
	if health <= 0 or destroyed:
		return
	
	$Hit.play()
	health -= amount

	if health <= 0:
		_on_destroyed()
	else:
		_start_flash()


func _start_flash() -> void:
	flash_counter = 0
	flash_timer.start(damage_flash_duration)


func _on_flash_timer_timeout() -> void:
	if flash_counter < damage_flash_count * 2:
		var active = flash_counter % 2 == 0

		if muralla_1.material:
			muralla_1.material.set_shader_parameter("effect_enabled", active)
		if muralla_2.material:
			muralla_2.material.set_shader_parameter("effect_enabled", active)

		flash_counter += 1
	else:
		flash_timer.stop()
		if muralla_1.material:
			muralla_1.material.set_shader_parameter("effect_enabled", false)
		if muralla_2.material:
			muralla_2.material.set_shader_parameter("effect_enabled", false)


func _on_destroyed() -> void:
	destroyed = true
	remove_from_group("Muralla")
	await get_tree().create_timer(0.1).timeout
	emit_signal("muralla_destruida")

	muralla_1.hide()
	muralla_2.hide()
	static_body.hide()
	muralla_collision.disabled = true
	static_collision.disabled = true

	$Explotion2.play()
	$Explotion.show()
	$Explotion.play("default")
		# Instanciar la escena de muralla rota
	var muralla_rota_scene = preload("res://scenes/muralla_rota.tscn")
	var muralla_rota_instance = muralla_rota_scene.instantiate()
	get_parent().add_child(muralla_rota_instance)
	muralla_rota_instance.global_position = global_position + Vector2(-4, -1)

	await $Explotion.animation_finished
	$Explotion.hide()
	await get_tree().create_timer(4.0).timeout 
	queue_free()
