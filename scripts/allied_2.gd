extends CharacterBody2D
class_name Allied_2


enum State { WALK_FORWARD, PRE_ATTACK, ATTACK, WALK_BACK, IDLE, HURT, DEAD }

@export_category("Stats")
@export var health: int = 100
@export var walk_speed: float = 170.0
@export var danio_a_base : int = 10
@export var danio_a_muralla:int =10
@export var danio_a_enemigo : int = 20
@export_category("Comportamiento_Ataque")
@export var walk_duration: float = 1.6
@export var attack_range: float = 80.0
@export var pre_attack_delay: float = 0.3
@export var idle_duration: float = 5.0
@export var attack_knockback: float = 400.0
@export_category("Seguimiento")
@export var follow_range: float = 80.0
@export_category("Range_seeker")
@export var custom_detection_range: float = 500.0 # Nuevo rango de detección por defecto
@export var use_custom_range: bool = false # Bandera para usar el rango personalizado
@export_category("Misc")
@export var steps_volume_db: float = -23.0
@export var sapucay :AudioStreamPlayer

@export var animated_sprite: AnimatedSprite2D 
@onready var attack_area: Area2D = $AttackArea

@onready var coin_scene = preload("res://scenes/coin.tscn")
@onready var powerUp_scene = preload("res://scenes/power_up.tscn") 


var base_attack_area_position: Vector2
var state: State = State.IDLE
var walk_direction: int = 1
var can_attack_sound := true
var is_dead := false
var flashing := false
var hurt_cooldown := false
var idle_timer_active := false

var target_elegido : Node

var sapucay_hecho : bool = false



func _ready() -> void:
	base_attack_area_position = attack_area.position
	attack_area.monitoring = false
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	Global.add_tribe_member()
	walk_speed += randi_range(-4,0)
	idle_duration += randi_range(-0.4,0.5)
	walk_duration+= randi_range(0,0.4)


# -------------------- DETECCIÓN DE OBJETIVO: MÁS CERCANO (MODIFICADO) --------------------
# 1) Modificación solicitada: Encuentra todos los objetivos válidos y devuelve el más cercano.
func _get_target_with_priority3() -> Node:
	var all_targets = []
	var max_range = INF
	
	# Si está habilitado, el objetivo debe estar dentro del rango personalizado (Requisito 2)
	if use_custom_range:
		max_range = custom_detection_range


	## 2. Recolectar Murallas válidas (no destruidas)
	#var murallas_raw = []
	#murallas_raw.append_array(get_tree().get_nodes_in_group("Muralla Enemiga"))
	#
	##print(murallas_raw)
	#for m in murallas_raw:
		## Se asume que el objeto Muralla tiene el método `is_destroyed()`
		##print(m)
		#if is_instance_valid(m):
			##print(m)
			#if m.has_method("is_destroyed"):
				#var destruida = m.is_destroyed()
				##print(destruida)
				#if destruida == false:
					#all_targets.append(m)
					##print(all_targets)
			##else:
				## Si no tiene el método, se considera un objetivo válido por defecto.
				##all_targets.append(m)
				#pass

	
	all_targets.append_array(get_tree().get_nodes_in_group("Enemy"))
	all_targets.append_array(get_tree().get_nodes_in_group("Muralla Enemiga"))
	all_targets.append_array(get_tree().get_nodes_in_group("Hut Enemigo"))
	
	
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
					if closest_target.is_in_group("Muralla Enemiga"):
						if !sapucay_hecho:
							if sapucay != null:
								sapucay.play()
								sapucay_hecho = true
				
	if closest_target == null:
		$Label.text = "?"
		var player = get_tree().get_nodes_in_group("Player_Body")
		var dist_player = global_position.distance_to(player[0].global_position)
		if dist_player <= follow_range *2:
			#all_targets.append_array(get_tree().get_nodes_in_group("Player_Body"))
			closest_target = player[0]
			$Label.text = "^_^"
	
		
	
	#print("TARGET CERCANO:")
	#print(closest_target)
	
	return closest_target



# -------------------- MOVIMIENTO Y ATAQUE --------------------
func _physics_process(delta: float) -> void:
	if Global.paused:
		set_state(State.IDLE)
		return
	var cerca_de_jugador : bool = false
	if is_dead:
		return
	
	# Detectar el objetivo en cada frame
	var target = _get_target_with_priority3()
	
	
	if target != null:
		if target.is_in_group("Player_Body"):
			var dist_player = global_position.distance_to(target.global_position)
			if dist_player <= follow_range:
				cerca_de_jugador = true
				
						
	# 1. Lógica de transición desde IDLE (Inicio del ciclo)
	if state == State.IDLE:
		if target != null:
			# FIX 1: Cambiamos la comparación 'state == State.WALK_FORWARD' 
			# por la llamada a la función de transición 'set_state()'.
			# Esto inicia el movimiento y el ciclo de ataque.
			if not cerca_de_jugador:
				if not idle_timer_active:
					set_state(State.WALK_FORWARD) 
			
			

	# Lógica de WALK_FORWARD (solo se ejecuta si el estado es WALK_FORWARD)
	if state == State.WALK_FORWARD:
		if target and not cerca_de_jugador:
			var new_direction = sign(target.global_position.x - global_position.x)
			if new_direction == 0:
				new_direction = 1
			walk_direction = new_direction
			animated_sprite.flip_h = walk_direction < 0
			_update_attack_area_direction()

			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		if target == null:
			set_state(State.IDLE) 

	# Velocidad según estado
	if state == State.WALK_FORWARD and not cerca_de_jugador:
		velocity.x = walk_speed * walk_direction
	elif state == State.WALK_BACK and not cerca_de_jugador:
		velocity.x = -walk_speed * walk_direction
	else:
		velocity.x = 0

	# --- Movimiento ---
	move_and_slide()

	# --- Chequeo posterior de colisión o rango (solo si está avanzando) ---
	if state == State.WALK_FORWARD:
		if target:
			#$Label.text = str(target)
			#print(global_position.distance_to(target.global_position))
			#print(attack_range)
			if global_position.distance_to(target.global_position) <= attack_range \
			and (\
			target.is_in_group("Muralla Enemiga") \
			or target.is_in_group("Enemy") \
			or target.is_in_group("Hut Enemigo")\
			):
				set_state(State.PRE_ATTACK)
				#print("Aliado 2 ataca")
			if global_position.distance_to(target.global_position) <= follow_range \
			and (target.is_in_group("Player_Body")) :
				set_state(State.IDLE)

# -------------------- DETECTAR COLISIÓN CON BASE --------------------
func _is_touching_base() -> bool:
	var count := get_slide_collision_count()
	for i in range(count):
		var col = get_slide_collision(i)
		if col and col.get_collider() and col.get_collider().is_in_group("Base"):
			return true
	return false

func set_target_detection_range(range_value: float, enable: bool = true) -> void:
	if enable and range_value > 0:
		use_custom_range = true
		custom_detection_range = range_value
	else:
		# Desactiva el uso del rango, permitiendo al enemigo detectar cualquier objetivo (o el más cercano, según la lógica de _get_target_with_priority2)
		use_custom_range = false

# -------------------- ESTADOS --------------------
func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	#var target = _get_target_with_priority3()
	target_elegido = _get_target_with_priority3()
	match state:
		State.WALK_FORWARD:
			if target_elegido:
				var new_direction = sign(target_elegido.global_position.x - global_position.x)
				if new_direction == 0:
					new_direction = 1
				walk_direction = new_direction
				animated_sprite.flip_h = walk_direction < 0
				_update_attack_area_direction()

				animated_sprite.play("walk")
				$Steps.volume_db = steps_volume_db
				$Steps.set_deferred("pitch_scale",randf_range(0.60,0.75))
				
				$Steps.play()
				attack_area.monitoring = true
		

		State.PRE_ATTACK:
			velocity = Vector2.ZERO
			$Steps.stop()
			animated_sprite.play("idle")
			_pre_attack_timer()

		State.ATTACK:
			attack_area.monitoring = true
			animated_sprite.play("attack")
			if can_attack_sound:
				$Attack.play()
				can_attack_sound = false
				_reset_attack_sound_cooldown()

		State.WALK_BACK:
			velocity.x = -walk_speed * walk_direction
			animated_sprite.flip_h = (-walk_direction) < 0
			_update_attack_area_direction()
			animated_sprite.play("walk")
			$Steps.volume_db = steps_volume_db
			$Steps.set_deferred("pitch_scale",randf_range(0.60,0.75))
			$Steps.play()
			_start_walk_back_timer()

		State.IDLE:
			velocity = Vector2.ZERO
			$Steps.stop()
			attack_area.monitoring = false
			animated_sprite.play("idle")
			_start_idle_timer()
			
				## --- Pequeño desplazamiento lateral ---
			#var offset = 10.0
			#global_position.x += offset * walk_direction
			#
			if target_elegido:
				var dir = sign(target_elegido.global_position.x - global_position.x)
				if dir != 0:
					walk_direction = dir
					animated_sprite.flip_h = walk_direction < 0
					_update_attack_area_direction()

		State.HURT:
			velocity = Vector2.ZERO
			animated_sprite.play("hurt")
			$Steps.stop()
			attack_area.monitoring = false

		State.DEAD:
			$Label.visible = false
			$Aliado_2_Body.disabled = true
			remove_from_group("Aliado_2")
			is_dead = true
			velocity = Vector2.ZERO
			animated_sprite.play("death")
			
			$Steps.stop()
			
			attack_area.monitoring = false
			
			Global.remove_tribe_member()
			var tween := create_tween()
			tween.tween_interval(5.0)
			tween.tween_property(animated_sprite, "modulate:a", 0.0, 2.5)
			tween.tween_callback(Callable(self, "_on_fade_out_finished"))
			#_entregar_recompensa()
			#queue_free()
			
func _entregar_recompensa()-> void:
	var coin = coin_scene.instantiate()
	coin.global_position = global_position
	get_parent().get_parent().add_child(coin)
	
	pass
func _on_fade_out_finished() -> void:
	queue_free()

# -------------------- PRE ATTACK --------------------
func _pre_attack_timer() -> void:
	await get_tree().create_timer(pre_attack_delay).timeout
	if state == State.PRE_ATTACK:
		set_state(State.ATTACK)

# -------------------- ATAQUE --------------------
func _on_frame_changed() -> void:
	if state == State.ATTACK and animated_sprite.frame == 1:
		var bodies = attack_area.get_overlapping_bodies()
		var areas = attack_area.get_overlapping_areas()
		for body in bodies + areas:
			if not is_instance_valid(body):
				continue

			if body.has_method("take_damage"):
				if body.is_in_group("Enemy"):
					var dir = Vector2(sign(body.global_position.x - global_position.x), 0) * (attack_knockback / 2)
					var hit_from_right = body.global_position.x < global_position.x
					body.take_damage(danio_a_enemigo, dir)

				elif body.is_in_group("Muralla Enemiga"):
					body.take_damage(danio_a_muralla)

				elif body.is_in_group("Hut Enemigo"):
					body.take_damage(danio_a_base)
				
					
			$AttackHit.play()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack" and state == State.ATTACK:
		attack_area.monitoring = false
		set_state(State.WALK_BACK)
	elif animated_sprite.animation == "hurt" and state == State.HURT:
		if health <= 0:
			set_state(State.DEAD)
		elif idle_timer_active:
			set_state(State.IDLE)
		else:
			set_state(State.WALK_FORWARD)

# -------------------- WALK BACK --------------------
func _start_walk_back_timer() -> void:
	await get_tree().create_timer(walk_duration).timeout
	if not is_dead:
		set_state(State.IDLE)

# -------------------- IDLE --------------------
func _start_idle_timer() -> void:
	idle_timer_active = true
	await get_tree().create_timer(idle_duration).timeout
	idle_timer_active = false
	#if not is_dead and state == State.Idd

# -------------------- DAMAGE --------------------
func take_damage(amount: int, knockback_dir: Vector2 = Vector2(0,0), is_arrow_attack: bool = false) -> void:
	if health <= 0 or is_dead or hurt_cooldown:
		return
	health -= amount
	hurt_cooldown = true
	set_state(State.HURT)
	velocity = knockback_dir
	flash_white()
	await get_tree().create_timer(0.01).timeout
	hurt_cooldown = false

func flash_white() -> void:
	if flashing:
		return
	flashing = true
	var original = animated_sprite.modulate
	animated_sprite.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = original
	flashing = false

func _reset_attack_sound_cooldown() -> void:
	await get_tree().create_timer(3.0).timeout
	can_attack_sound = true

# -------------------- ACTUALIZAR ATTACK AREA --------------------
func _update_attack_area_direction() -> void:
	var offset = 50.0
	if walk_direction > 0:
		attack_area.position = base_attack_area_position + Vector2(offset, 0)
	else:
		attack_area.position = base_attack_area_position

func face_direction(looking_right: bool) -> void:
	if looking_right:
		walk_direction = 1
		animated_sprite.flip_h = false
	else:
		walk_direction = -1
		animated_sprite.flip_h = true
	
	var offset = 50.0
	if walk_direction > 0:
		attack_area.position = base_attack_area_position + Vector2(offset, 0)
	else:
		attack_area.position = base_attack_area_position
