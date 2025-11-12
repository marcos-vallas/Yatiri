extends Area2D

@export var value: int = 1 


func _ready():
	# Conectamos la señal de cuando algo entra al área
	body_entered.connect(_on_body_entered)
	
	
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"): # Solo el jugador puede recoger
		Global.add_coins(value)
		$Coin_Sound.pitch_scale = randf_range(0.95, 1.0)
		$Coin_Sound.play()
		$Coin.visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(0.2).timeout
		queue_free() 
