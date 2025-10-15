extends Area2D

signal muralla_destruida

@export var health: int = 100
@onready var muralla_1: Sprite2D = $Muralla
@onready var muralla_collision: CollisionShape2D = $MurallaCollision

@export var attack_effect_scene: PackedScene = preload("res://scenes/explosion.tscn")

var damage_flash_count: int = 2       
var damage_flash_duration: float = 0.1 
var flash_counter: int = 0
var flash_timer: Timer

func _ready() -> void:
	$Explotion.hide()
	remove_from_group("Muralla")
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
		if muralla_1.material:
			muralla_1.material.set_shader_parameter("effect_enabled", active)
		flash_counter += 1
	else:
		flash_timer.stop()
		if muralla_1.material:
			muralla_1.material.set_shader_parameter("effect_enabled", false)

func _on_destroyed() -> void:
	
	await get_tree().create_timer(0.1).timeout
	emit_signal("muralla_destruida")
	muralla_1.hide()
	muralla_collision.disabled = true
	$Explotion2.play()
	$Muralla2.hide()
	$Muralla3.hide()
	$Explotion.show()
	$Explotion.play("default")
	$StaticBody2D/CollisionShape2D.disabled = true
	$MurallaRota.show()
	$MurallaRota2.show()
	$MurallaRota3.show()
	await $Explotion.animation_finished
	$Explotion.hide()
	
