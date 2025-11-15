extends Node2D

@export var player: CharacterBody2D#= $Player
@export var tilemap: TileMapLayer #= $TileMap 
@onready var coin_scene = preload("res://scenes/coin.tscn") 
@onready var hut_scene = preload("res://scenes/hut.tscn")
@export var tutorial: Control #= $CanvasLayer2/Tutorial
@export var objetivos : Control
@export var monedas_init:int =13
@export var potions_init:int =10

var segment_width: int
var tiles: Array = []
var start_pause :bool = true

func _ready() -> void:
	set_process(false)  # Desactiva _process mientras se hace la transición
	
	Global.pause()
	tutorial.show()
	
	Global.set_coins(monedas_init)
	Global.set_potions(potions_init)
	Global.set_tribe_count(0)
	Global.health_base(100)
	
	
	if has_node("CanvasLayer2/TransitionControl"):
		var transition = $CanvasLayer2/TransitionControl
		get_tree().paused = false
		transition.visible = true
		var anim_player = transition.get_node("AnimationPlayer")
		anim_player.play("screen_transition")
		await anim_player.animation_finished
		transition.visible = false
	
	# Ahora que todo está listo:
	var rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	segment_width = rect.size.x * tile_size.x
	tiles.append(tilemap)
	#spawn_coins_in_row(Vector2(100, 342), 3, 220)
	
	set_process(true)  # Reactiva _process al final
	
	#await get_tree().create_timer(10.0).timeout

	#var tween = create_tween()
	#tween.tween_property(tutorial, "modulate:a", 0.0, 1.0)  # 1 segundo de duración
	#await tween.finished
	#tutorial.hide()
enum State {PAUSED, NORMAL}
var current_State :State = State.PAUSED

var cambiando_estado :bool = false

func set_state(new_State : State):
	if new_State == current_State:
		return
	cambiando_estado = true
	current_State = new_State
	
	
	match current_State:
		State.PAUSED:
			print("Pausado")
			objetivos.show()
			Global.pause()
			var tween = create_tween()
			tween.tween_property(objetivos, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.finished.connect(_on_objetive_fade_finished)
			
		State.NORMAL:
			print("Normal")
			#objetivos.hide()
			Global.unpause()
			var tween = create_tween()
			tween.tween_property(objetivos, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.finished.connect(_on_objetive_fade_finished)
	
	pass

func _on_objetive_fade_finished():
	cambiando_estado = false
	if current_State == State.NORMAL:
			#objetivos.show()
			objetivos.hide()
			#Global.pause()
			#set_state(State.PAUSED)
			pass
	elif current_State == State.PAUSED:
		#set_state( State.NORMAL)
			#objetivos.hide()
			#Global.unpause()
			pass

	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and tutorial.visible:
		var tween = create_tween()
		tween.tween_property(tutorial, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(_on_tutorial_fade_finished)
		#Global.unpause()
		set_state(State.NORMAL)
	
	if Input.is_action_just_pressed("pause") and !tutorial.visible:
		if cambiando_estado == false:
			if current_State == State.NORMAL:
				set_state(State.PAUSED)
				pass
			elif current_State == State.PAUSED:
				set_state( State.NORMAL)
			
	

	#var hut = hut_scene.instantiate()
	#add_child(hut)
	#hut.position = Vector2(-500, 285)  # podés ajustar Y según el suelo
	
	var player_x = player.global_position.x

	# Chequear si hay que duplicar a la derecha
	var max_x = tiles[tiles.size()-1].position.x
	if player_x > max_x:
		var new_tile = tilemap.duplicate()  # duplicamos el tilemap base
		add_child(new_tile)
		new_tile.position.x = max_x + segment_width
		tiles.append(new_tile)

	# Chequear si hay que duplicar a la izquierda
	var min_x = tiles[0].position.x
	if player_x < min_x:
		var new_tile = tilemap.duplicate()
		add_child(new_tile)
		new_tile.position.x = min_x - segment_width
		tiles.insert(0, new_tile)

func _on_tutorial_fade_finished() -> void:
	tutorial.hide()


func spawn_coins_in_row(start_pos: Vector2, count: int, spacing: int = 10) -> void:
	for i in range(count):
		var coin = coin_scene.instantiate()
		
		# Posición inicial un poco arriba de la final
		var final_pos = start_pos + Vector2(i * spacing, 0)
		coin.position = final_pos + Vector2(0, -50)  # empieza 50px arriba
		add_child(coin)
		
		# Tween para caída/bounce
		var tween = create_tween()
		tween.tween_property(coin, "position", final_pos, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		# Espera un tiempo aleatorio antes de instanciar la siguiente moneda
		var delay = randf_range(1.5, 4.5)
		await get_tree().create_timer(delay).timeout
