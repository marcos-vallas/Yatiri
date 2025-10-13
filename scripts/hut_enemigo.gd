extends Area2D

signal muralla_destruida

@export var health: int = 100
@onready var hut_enemigo: Sprite2D = $HutEnemigo
@onready var collision: CollisionShape2D = $CollisionShape2D


var damage_flash_count: int = 2       
var damage_flash_duration: float = 0.1 
var flash_counter: int = 0
var flash_timer: Timer

func _ready() -> void:
	$Explotion.hide()
	flash_timer = Timer.new()
	flash_timer.one_shot = false
	add_child(flash_timer)
	flash_timer.timeout.connect(_on_flash_timer_timeout)

func take_damage(amount: int) -> void:
	if health <= 0:
		return

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
		# alternar shader on/off
		var active = flash_counter % 2 == 0
		if hut_enemigo.material:
			hut_enemigo.material.set_shader_parameter("effect_enabled", active)
		flash_counter += 1
	else:
		flash_timer.stop()
		if hut_enemigo.material:
			hut_enemigo.material.set_shader_parameter("effect_enabled", false)

func _on_destroyed() -> void:
	
	await get_tree().create_timer(0.1).timeout
	emit_signal("muralla_destruida")
	$Explotion2.play()
	hut_enemigo.hide()
	collision.disabled = true
	$Explotion.show()
	$Explotion.play("default")
	await $Explotion.animation_finished
	$Explotion.hide()

	await get_tree().create_timer(6).timeout
	Global.game_result_text = "¡Ganaste!\n\n¿Jugar de nuevo?"
	get_tree().change_scene_to_file("res://scenes/game_over_screen.tscn")

	queue_free()
