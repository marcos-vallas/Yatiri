extends Node

@export_category("Objeto")
#@export var coin_scene : Node
@onready var coin_scene = preload("res://scenes/coin.tscn")

func _init() -> void:
	spawn_coins(1)
	print("Enemigo suelta moneda")
	
	
func spawn_coins(count: int) -> void:
	for i in range(count):
		var coin = coin_scene.instantiate()
		
		# Posición inicial un poco arriba de la final
		var final_pos = get_parent().global_position
		coin.position = final_pos + Vector2(0, +50)  # empieza 50px arriba
		coin.position = get_parent().global_position
		add_child(coin)
		
		# Tween para caída/bounce
		var tween = create_tween()
		tween.tween_property(coin, "position", final_pos, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
