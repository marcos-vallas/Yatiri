extends CharacterBody2D


@export var path_follow : PathFollow2D
@export var speed = 50


var direccion :Vector2
var posicion_anterior : Vector2

@export var flip : bool = false

func _ready():
	posicion_anterior = path_follow.global_position
	
func _physics_process(delta: float) -> void:
	path_follow.progress += speed * delta
	
	var pos = path_follow.global_position
	
	self.global_position = pos
	
	direccion = (pos-posicion_anterior).normalized()
	posicion_anterior = pos
	
func _process(delta: float) -> void:
	
	if !flip:
		if direccion.x < 0:
			$AnimatedSprite2D.flip_h = false
		if direccion.x > 0:
			$AnimatedSprite2D.flip_h = true
			
	if flip:
		if direccion.x > 0:
			$AnimatedSprite2D.flip_h = false
		if direccion.x < 0:
			$AnimatedSprite2D.flip_h = true


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		#play_hit_sound()
		#var dir = Vector2(sign(body.global_position.x - global_position.x), 0) * attack_knockback
		body.take_damage(300, (Vector2(0,1)))
		pass # Replace with function body.
