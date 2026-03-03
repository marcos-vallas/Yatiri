extends Node2D

# Arrastra aquí la escena que quieres spawnear (el .tscn)
@export var preloadObject: PackedScene
@export var sec_btw_spawns : float = 1.0

#var preloadSpear = preload("res://scenes/spear.tscn")
@onready var spear_position: Node2D = $SpawnPos



func _ready() -> void:
	
	$SpawnTimer.autostart = true
	$SpawnTimer.wait_time = sec_btw_spawns


func _on_spawn_timer_timeout() -> void:
	if preloadObject:
		# 1. Crear la instancia del objeto
		var instancia = preloadObject.instantiate()
		
		# 2. Posicionarlo donde está el Spawner
		instancia.global_position = spear_position.global_position
		
		# 3. Añadirlo a la escena principal
		# Es mejor usar get_tree().current_scene para no mover el objeto si el spawner se mueve
		get_tree().current_scene.add_child(instancia)
