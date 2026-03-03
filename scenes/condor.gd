extends CharacterBody2D


@export var path_follow : PathFollow2D
@export var speed = 50

var direccion :Vector2
var posicion_anterior : Vector2


func _ready():
	posicion_anterior = path_follow.global_position
	
func _physics_process(delta: float) -> void:
	path_follow.progress += speed * delta
	
	var pos = path_follow.global_position
	
	self.global_position = pos
	
	direccion = (pos-posicion_anterior).normalized()
	posicion_anterior = pos
	
func _process(delta: float) -> void:
	if direccion.x < 0:
		$AnimatedSprite2D.flip_h = false
	if direccion.x > 0:
		$AnimatedSprite2D.flip_h = true
