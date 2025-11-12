extends CharacterBody2D
class_name Allied_1

# -------------------- VARIABLES --------------------
var attack_cooldown := false
var preloadArrow = preload("res://scenes/arrow.tscn")


enum State { IDLE, ATTACK, HURT, DEAD, RUN }

@export_category("Stats")
@export var health: int = 30
@export var intervalo_ataque : float = 0.3
@export var variacion_intervalo_ataque : float = 0.2
@export var rango_ataque : float = 500.0
@export_category("Comportamiento TakeDamage")
@export var knockback_force: float = 200.0
@export var knockback_friction: float = 800.0
@export var damage_flash_time: float = 0.2
@export var flash_duration: float = 0.4
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export_category("Comportamiento automatico")
@export var distancia_a_la_muralla : float = 100
@export var variacion_dist_muralla : float = 50
@export var walk_speed : float = 50.0

var target_seleccionado : Node
var muralla_seleccionada : Node
var distancia_a_muralla_seleccionada : float

var state: State = State.IDLE
var walk_direction: int = 1
var steps_volume_db = -25.0

var flashing: bool = false
var is_dead := false
var is_hurt := false

func _ready() -> void:
	# Idle inicial con frame aleatorio
	#_play_idle()
	#
	#do_attack()
	set_state(State.RUN)
	
	
func _init() -> void:
	#print("AgregoMiemro")
	Global.add_tribe_member()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	

	if state == State.IDLE:
		var target = _get_target_with_priority3()
		if target != null:
			set_state(State.ATTACK)
		pass
		
		if muralla_seleccionada != null:
			var dist = global_position.distance_to(muralla_seleccionada.global_position)
			dist = int(dist)
			if !_get_cerca_de_muralla():
				set_state(State.RUN)
	
#	se va a IDLE si no hay muralla
	if muralla_seleccionada == null:
		if state != State.IDLE:
			set_state(State.IDLE)
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
		
	if state == State.ATTACK:
		pass
	if state == State.DEAD:
		pass
	if state == State.RUN:
		
		if muralla_seleccionada != null:
			var new_direction = sign(muralla_seleccionada.global_position.x - global_position.x)
			if new_direction == 0:
				new_direction = 1
			walk_direction = new_direction
			#_update_sprite_flip()
			#_update_attack_area_direction()
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
				$Steps.volume_db = -30.0  
				if not $Steps.playing:
					$Steps.play()
			velocity.x = walk_speed * walk_direction
			
			#var dist = global_position.distance_to(muralla_seleccionada.global_position)
			#dist = int(dist)
			if _get_cerca_de_muralla():
				set_state(State.IDLE)
			pass
			
		if muralla_seleccionada == null: set_state(State.IDLE)
		
	
	# Mover con velocity y desacelerar
	if velocity != Vector2.ZERO:
		move_and_slide()
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	## Si terminó hurt, volver a idle
	#if is_hurt and animated_sprite.animation != "hurt":
		#is_hurt = false
		#_play_idle()
		#
		
		
func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	
	target_seleccionado = _get_target_with_priority3()
	muralla_seleccionada = _get_muralla()
	
	match state:
		State.ATTACK:
			do_attack(target_seleccionado)
			attack_cooldown = false
			
			pass
		State.IDLE:
			_play_idle()
			pass
		State.HURT:
			if is_hurt and animated_sprite.animation != "hurt":
				is_hurt = false
			set_state(State.IDLE)
			pass
		State.RUN:
			distancia_a_muralla_seleccionada = distancia_a_la_muralla + randf_range(0 ,variacion_dist_muralla)
			if muralla_seleccionada:
				walk_direction = sign(muralla_seleccionada.global_position.x - global_position.x)
				if walk_direction == 0:
					walk_direction = 1
				#_update_sprite_flip()
				#_update_attack_area_direction()
			animated_sprite.play("run")
			$Steps.volume_db = steps_volume_db
			$Steps.play()
			pass



				
func _get_target_with_priority3() -> Node:
	var all_targets = []
	var max_range = INF

	max_range = rango_ataque
	
	all_targets.append_array(get_tree().get_nodes_in_group("Enemy"))
	#all_targets.append_array(get_tree().get_nodes_in_group("Muralla Enemiga"))
	
	if all_targets.is_empty():
		return null

	# Encontrar el objetivo más cercano que esté dentro del rango (Requisito 1 y 2)
	var closest_target: Node = null
	var min_dist: float = INF
	
	for target in all_targets:
		# Se realiza una verificación de validez y posición
		if is_instance_valid(target): # and target.has_method("global_position"):
			var dist = global_position.distance_to(target.global_position)
			
			# Aplicar filtro de rango de detección (Requisito 2)
			if dist <= max_range:
				if dist < min_dist:
					min_dist = dist 
					closest_target = target
					$Label.text = ">:("
				
	if closest_target == null:
		$Label.text = "?"

	return closest_target


# ----------- COMPORTAMIENTO MURALLA 
func _get_cerca_de_muralla()-> bool :
	var esta_cerca:bool = false
	var closest_target = _get_muralla()
					
	var distb = global_position.distance_to(closest_target.global_position)
	distb = int(distb)
	
	if abs(distb) <= distancia_a_muralla_seleccionada:
		esta_cerca = true
	return esta_cerca

func _get_muralla() -> Node:
	var all_targets = []
	all_targets.append_array(get_tree().get_nodes_in_group("Muralla"))
	if all_targets.is_empty():
		return null
		# Encontrar el objetivo más cercano que esté dentro del rango (Requisito 1 y 2)
	var closest_target: Node = null
	var min_dist: float = INF
	var max_range: float = INF

	for target in all_targets:
	# Se realiza una verificación de validez y posición
		if is_instance_valid(target): # and target.has_method("global_position"):
			var dist = global_position.distance_to(target.global_position)
			
			# Aplicar filtro de rango de detección (Requisito 2)
			if dist <= max_range:
				if dist < min_dist:
					min_dist = dist 
					closest_target = target
					
	return closest_target



func do_attack(target:Node2D) -> void:
	if attack_cooldown or is_dead or not is_inside_tree():
		return

	if target == null :
		attack_cooldown = true
		_play_idle()
		return
		
	animated_sprite.flip_h = target.global_position.x < global_position.x
	
	var intervalo_random : float = randf_range(intervalo_ataque - 0.2, intervalo_ataque + 0.2)
	# Instanciar flecha
	intervalo_ataque + randf_range(0, variacion_intervalo_ataque)
	await get_tree().create_timer(intervalo_ataque).timeout
	animated_sprite.play("attack")
	
	

	if $Attack:
		$Attack.pitch_scale = randf_range(0.8, 1.0)
		$Attack.play()

	# Esperar que termine la animación para volver a idle
	await animated_sprite.animation_finished
	
	var arrow = preloadArrow.instantiate()
	arrow.global_position = $ArrowPosition.global_position
	get_parent().add_child(arrow)
	if target.is_inside_tree():
		arrow.launch_towards_enemy(target)
		
		
	if not is_dead:
		set_state(State.IDLE)
		
	attack_cooldown = false
	


func take_damage(damage:int, from_direction: Vector2= Vector2(0,0), _unused: bool = true) -> void:
	if health <= 0 or is_dead:
		return

	
	health -= damage
	if $AttackHit:
		$AttackHit.play()

	# Flash
	flash_white()

	# Animación hurt
	animated_sprite.play("hurt")
	animated_sprite.frame = 0

	# Knockback
	if from_direction != Vector2.ZERO:
		velocity = from_direction.normalized() * knockback_force

	# Esperar que termine hurt antes de volver a idle
	await animated_sprite.animation_finished

	if health > 0 and not is_dead:
		_play_idle()
	else:
		set_state_dead()


func flash_white() -> void:
	if flashing:
		return
	flashing = true
	var original = animated_sprite.modulate
	animated_sprite.modulate = Color(2,2,2,1)

	var t = Timer.new()
	t.wait_time = flash_duration
	t.one_shot = true
	add_child(t)
	t.start()
	t.timeout.connect(func():
		animated_sprite.modulate = original
		flashing = false
		t.queue_free()
	)

func set_state_dead() -> void:
	is_dead = true
	remove_from_group("Aliado_1")
	$Aliado_1_Body.disabled = true
	attack_cooldown = true
	animated_sprite.play("death")
	if $Steps:
		$Steps.stop()
	Global.remove_tribe_member()
	var tween := create_tween()
	tween.tween_interval(7)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 3.5)
	tween.tween_callback(Callable(self, "_on_fade_out_finished"))
	#queue_free()

func _on_fade_out_finished() -> void:
	queue_free()

func _play_idle() -> void:
	if is_dead:
		return
	animated_sprite.play("idle")
	#animated_sprite.frame = randi() % animated_sprite.sprite_frames.get_frame_count("idle")


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack" and state == State.ATTACK:
		
		pass # Replace with function body.
