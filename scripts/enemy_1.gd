extends CharacterBody2D
class_name Enemy

enum State { WALK_FORWARD, PRE_ATTACK, ATTACK, WALK_BACK, IDLE, HURT, DEAD }

@export var health: int = 100
@export var walk_speed: float = 170.0
@export var walk_duration: float = 1.6
@export var attack_knockback: float = 400.0
@export var steps_volume_db: float = -23.0
@export var attack_range: float = 50.0
@export var pre_attack_delay: float = 0.3
@export var idle_duration: float = 5.0
@export var attack_offset: float = 50.0

@onready var animated_sprite: AnimatedSprite2D = $Enemy
@onready var attack_area: Area2D = $AttackArea

var base_attack_area_position: Vector2
var state: State = State.WALK_FORWARD
var walk_direction: int = 1
var can_attack_sound := true
var is_dead := false
var flashing := false
var hurt_cooldown := false
var idle_timer_active := false

func _ready() -> void:
	base_attack_area_position = attack_area.position
	attack_area.monitoring = false
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)

# -------------------- DETECCIÓN DE OBJETIVO CON PRIORIDAD --------------------
func _get_target_with_priority() -> Node:
	# Primero Base
	var bases = get_tree().get_nodes_in_group("Base")
	if not bases.is_empty():
		var closest = bases.front()
		var min_dist = global_position.distance_to(closest.global_position)
		for b in bases:
			var dist = global_position.distance_to(b.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = b
		return closest

	# Luego muralla
	var murallas = get_tree().get_nodes_in_group("Muralla")
	if not murallas.is_empty():
		var closest = murallas.front()
		var min_dist = global_position.distance_to(closest.global_position)
		for m in murallas:
			var dist = global_position.distance_to(m.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = m
		return closest
	
	# Por último player
	var players = get_tree().get_nodes_in_group("Player")
	if not players.is_empty():
		var closest = players.front()
		var min_dist = global_position.distance_to(closest.global_position)
		for p in players:
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = p
		return closest
	
	return null

# -------------------- MOVIMIENTO Y ATAQUE --------------------
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if state == State.WALK_FORWARD:
		var target = _get_target_with_priority()
		if target:
			var new_direction = sign(target.global_position.x - global_position.x)
			if new_direction == 0:
				new_direction = 1
			walk_direction = new_direction
			animated_sprite.flip_h = walk_direction < 0
			_update_attack_area_direction()

			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")

	# Velocidad según estado
	if state == State.WALK_FORWARD:
		velocity.x = walk_speed * walk_direction
	elif state == State.WALK_BACK:
		velocity.x = -walk_speed * walk_direction
	else:
		velocity.x = 0

	# --- Movimiento ---
	move_and_slide()

	# --- Chequeo posterior de colisión o rango ---
	if state == State.WALK_FORWARD:
		var target = _get_target_with_priority()
		if target:
			if global_position.distance_to(target.global_position) <= attack_range \
			or (target.is_in_group("Muralla") and is_on_wall()) \
			or (target.is_in_group("Base") and (_is_touching_base() or is_on_wall())):
				set_state(State.PRE_ATTACK)

# -------------------- DETECTAR COLISIÓN CON BASE --------------------
func _is_touching_base() -> bool:
	var count := get_slide_collision_count()
	for i in range(count):
		var col = get_slide_collision(i)
		if col and col.get_collider() and col.get_collider().is_in_group("Base"):
			return true
	return false

# -------------------- ESTADOS --------------------
func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state

	match state:
		State.WALK_FORWARD:
			var target = _get_target_with_priority()
			if target:
				var new_direction = sign(target.global_position.x - global_position.x)
				if new_direction == 0:
					new_direction = 1
				walk_direction = new_direction
				animated_sprite.flip_h = walk_direction < 0
				_update_attack_area_direction()

				animated_sprite.play("walk")
				$Steps.volume_db = steps_volume_db
				$Steps.play()

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
			$Steps.play()
			_start_walk_back_timer()

		State.IDLE:
			velocity = Vector2.ZERO
			$Steps.stop()
			attack_area.monitoring = false
			animated_sprite.play("idle")
			
				# --- Pequeño desplazamiento lateral ---
			var offset = 10.0
			global_position.x += offset * walk_direction

			var target = _get_target_with_priority()
			if target:
				var dir = sign(target.global_position.x - global_position.x)
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
			is_dead = true
			velocity = Vector2.ZERO
			animated_sprite.play("death")
			$CollisionShape2D.disabled = true
			$Steps.stop()
			attack_area.monitoring = false
			remove_from_group("Enemy")
			
			var tween := create_tween()
			tween.tween_interval(5.0)
			tween.tween_property(animated_sprite, "modulate:a", 0.0, 2.5)
			tween.tween_callback(Callable(self, "_on_fade_out_finished"))
			
func _on_fade_out_finished() -> void:
	queue_free()

# -------------------- PRE ATTACK --------------------
func _pre_attack_timer() -> void:
	await get_tree().create_timer(pre_attack_delay).timeout
	if state == State.PRE_ATTACK:
		set_state(State.ATTACK)

# -------------------- ATAQUE --------------------
func _on_frame_changed() -> void:
	if state == State.ATTACK and animated_sprite.frame == 2:
		var bodies = attack_area.get_overlapping_bodies()
		var areas = attack_area.get_overlapping_areas()
		for body in bodies + areas:
			if not is_instance_valid(body):
				continue

			if body.has_method("take_damage"):
				if body.is_in_group("Player"):
					var dir = Vector2(sign(body.global_position.x - global_position.x), 0) * (attack_knockback / 2)
					var hit_from_right = body.global_position.x < global_position.x
					body.take_damage(dir, hit_from_right)

				elif body.is_in_group("Muralla"):
					body.take_damage(10)

				elif body.is_in_group("Base"):
					body.take_damage(10)


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
	if not is_dead and state == State.IDLE:
		set_state(State.WALK_FORWARD)

# -------------------- DAMAGE --------------------
func take_damage(amount: int, knockback_dir: Vector2, is_arrow_attack: bool = false) -> void:
	if health <= 0 or is_dead or hurt_cooldown:
		return
	health -= amount
	hurt_cooldown = true
	set_state(State.HURT)
	velocity = knockback_dir
	flash_white()
	await get_tree().create_timer(0.3).timeout
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
