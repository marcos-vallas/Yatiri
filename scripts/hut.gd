extends Area2D

signal muralla_destruida

@onready var hut: Sprite2D = $Hut
@onready var collision: CollisionShape2D = $BaseCollision
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D

var damage_flash_count: int = 2        # cantidad de parpadeos
var damage_flash_duration: float = 0.1 # duración de cada parpadeo
var flash_counter: int = 0
var flash_timer: Timer


func _ready() -> void:
	add_to_group("Base")
	$Explotion.hide()
	# Timer interno para efecto de daño
	flash_timer = Timer.new()
	flash_timer.one_shot = false
	add_child(flash_timer)
	flash_timer.timeout.connect(_on_flash_timer_timeout)

	# Asegurar que el StaticBody2D bloquee, pero esta Area2D reciba daño
	monitorable = true
	monitoring = true

func take_damage(amount: int) -> void:
	if Global.base_health <= 0:
		return
	
	$Hit.play()
	Global.damage_base(amount)
	
	if Global.base_health <= 0:
		_on_destroyed()
	else:
		_start_flash()
		
		
func _start_flash() -> void:
	flash_counter = 0
	flash_timer.start(damage_flash_duration)

func _on_flash_timer_timeout() -> void:
	if flash_counter < damage_flash_count * 2:
		var active = flash_counter % 2 == 0
		if hut.material:
			hut.material.set_shader_parameter("effect_enabled", active)
		flash_counter += 1
	else:
		flash_timer.stop()
		if hut.material:
			hut.material.set_shader_parameter("effect_enabled", false)

func _on_destroyed() -> void:
	await get_tree().create_timer(0.1).timeout
	emit_signal("muralla_destruida")
	hut.hide()
	$Explotion.show()
	$Explotion2.play()
	collision.disabled = true
	$Explotion.play("default")
	await $Explotion.animation_finished
	$Explotion.hide()
	await get_tree().create_timer(6.0).timeout
	Global.game_result_text = "¡Destruyeron la base!\n\n¿Jugar de nuevo?"
	await get_tree().create_timer(0.05).timeout 
	get_tree().change_scene_to_file("res://scenes/game_over_screen.tscn")
	queue_free()
