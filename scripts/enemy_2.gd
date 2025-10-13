extends CharacterBody2D
class_name Enemy2

enum State { WALK_FORWARD, ATTACK, WALK_BACK, IDLE, HURT, DEAD }

@export var health: int = 100
@export var walk_speed: float = 170.0
@export var walk_duration: float = 1.6
@export var attack_knockback: float = 400.0
@export var steps_volume_db: float = -23.0
@export var attack_range: float = 200.0
@export var idle_duration: float = 5.0
@export var knockback_force: float = 250.0
@export var hurt_knockback_duration: float = 0.18

@onready var animated_sprite: AnimatedSprite2D = $Enemy2
@onready var attack_area: Area2D = $AttackArea
@onready var spear_position: Node2D = $SpearPosition

var base_attack_area_position: Vector2
var state: State = State.WALK_FORWARD
var walk_direction: int = 1
var can_attack_sound := true
var is_dead := false
var flashing := false
var hurt_cooldown := false
var idle_timer_active := false
var walk_back_variation: float
var current_target: Node2D = null
var preloadSpear = preload("res://scenes/spear.tscn")

func _ready() -> void:
	base_attack_area_position = attack_area.position
	attack_area.monitoring = false
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	walk_back_variation = randf_range(0.5, 5.0)
	
		# Conectamos la señal de todas las murallas existentes
	for m in get_tree().get_nodes_in_group("Muralla"):
		if m.has_signal("muralla_destruida"):
			m.connect("muralla_destruida", Callable(self, "_on_muralla_destruida"))

	# 👉 Orientación inicial
	var target = _get_target()
	if target:
		walk_direction = sign(target.global_position.x - global_position.x)
		if walk_direction == 0:
			walk_direction = -1  # por defecto mirar a la izquierda
	else:
		walk_direction = -1  # si no hay target, mirar a la izquierda

	_update_sprite_flip()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# si está en HURT, dejamos que el knockback actúe libremente
	if state == State.HURT:
		move_and_slide()
		return

	# buscamos muralla o player como objetivo
	var target = _get_target()
	if target == null:
		if state != State.IDLE:
			set_state(State.IDLE)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match state:
		State.WALK_FORWARD:
			var new_direction = sign(target.global_position.x - global_position.x)
			if new_direction == 0:
				new_direction = 1
			walk_direction = new_direction
			_update_sprite_flip()
			_update_attack_area_direction()

			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
				$Steps.volume_db = -30.0  
				if not $Steps.playing:
					$Steps.play()

			if global_position.distance_to(target.global_position) <= attack_range:
				set_state(State.ATTACK)

			velocity.x = walk_speed * walk_direction

		State.WALK_BACK:
			velocity.x = -walk_speed * walk_direction

		State.IDLE, State.ATTACK, State.DEAD:
			velocity.x = 0

	move_and_slide()


# -------------------- ESTADOS --------------------
func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state

	match state:
		State.WALK_FORWARD:
			var target = _get_target()
			if target:
				walk_direction = sign(target.global_position.x - global_position.x)
				if walk_direction == 0:
					walk_direction = 1
				_update_sprite_flip()
				_update_attack_area_direction()
			animated_sprite.play("walk")
			$Steps.volume_db = steps_volume_db
			$Steps.play()

		State.ATTACK:
			velocity = Vector2.ZERO
			$Steps.stop()
			animated_sprite.play("attack")
			if can_attack_sound:
				await get_tree().create_timer(0.3).timeout
				$Attack.play()
				can_attack_sound = false
				_reset_attack_sound_cooldown()

		State.WALK_BACK:
			velocity.x = -walk_speed * walk_direction
			_update_sprite_flip()
			_update_attack_area_direction()
			animated_sprite.play("walk")
			$Steps.volume_db = steps_volume_db
			$Steps.play()
			_start_walk_back_timer()

		State.IDLE:
			velocity = Vector2.ZERO
			$Steps.stop()
			animated_sprite.play("idle")
			_update_sprite_flip()
			_update_attack_area_direction()

		State.HURT:
			$Steps.stop()
			animated_sprite.play("hurt")
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
			tween.tween_interval(6.0)  
			tween.tween_property(animated_sprite, "modulate:a", 0.0, 3.0)  
			tween.tween_callback(Callable(self, "_on_fade_out_finished"))
			
func _on_fade_out_finished() -> void:
	queue_free()

# -------------------- ATAQUE --------------------
func _on_frame_changed() -> void:
	if state == State.ATTACK and animated_sprite.frame == 3:
		_throw_spear()

func _throw_spear() -> void:
	var target = _get_target()
	if target == null:
		return
	var spear = preloadSpear.instantiate()
	spear.global_position = spear_position.global_position
	get_parent().add_child(spear)
	spear.launch_towards_wall(target)


# -------------------- ANIMACIONES --------------------
func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack" and state == State.ATTACK:
		set_state(State.WALK_BACK)
	elif animated_sprite.animation == "hurt" and state == State.HURT:
		if health <= 0:
			set_state(State.DEAD)
		else:
			set_state(State.WALK_FORWARD)
	elif animated_sprite.animation == "death" and state == State.DEAD:
		pass


# -------------------- WALK BACK --------------------
func _start_walk_back_timer() -> void:
	await get_tree().create_timer(walk_duration + walk_back_variation).timeout
	if not is_dead:
		set_state(State.IDLE)
		await get_tree().create_timer(2.0).timeout
		if not is_dead and state == State.IDLE:
			set_state(State.WALK_FORWARD)


# -------------------- DAMAGE --------------------
func take_damage(amount: int, knockback_dir: Vector2, is_arrow_attack: bool = false) -> void:
	if health <= 0 or is_dead or hurt_cooldown:
		return

	hurt_cooldown = true
	#if not is_arrow_attack:
		#$AttackHit.play()
	flash_white()

	health -= amount

	set_state(State.HURT)

	velocity = knockback_dir.normalized() * knockback_force
	await get_tree().create_timer(hurt_knockback_duration).timeout
	velocity = Vector2.ZERO

	if health <= 0:
		set_state(State.DEAD)

	hurt_cooldown = false


# -------------------- EFECTOS --------------------
func flash_white() -> void:
	if flashing:
		return
	flashing = true
	var original = animated_sprite.modulate
	animated_sprite.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.4).timeout
	animated_sprite.modulate = original
	flashing = false

func _reset_attack_sound_cooldown() -> void:
	await get_tree().create_timer(3.0).timeout
	can_attack_sound = true


# -------------------- SPRITE & ATTACK AREA --------------------
func _update_sprite_flip() -> void:
	match state:
		State.WALK_FORWARD, State.IDLE, State.HURT:
			animated_sprite.flip_h = walk_direction > 0
		State.WALK_BACK:
			animated_sprite.flip_h = walk_direction < 0

func _update_attack_area_direction() -> void:
	var offset = 50.0
	attack_area.position = base_attack_area_position + Vector2(offset * walk_direction, 0)



# -------------------- NUEVO: OBTENER TARGET --------------------
func _get_target() -> Node2D:
	# Si ya hay un target válido, lo seguimos usando
	if current_target and is_instance_valid(current_target) and current_target.is_inside_tree():
		# 🚫 Si es una muralla destruida, la descartamos
		if "destroyed" in current_target and current_target.destroyed:
			current_target = null
		else:
			return current_target

	var closest_target: Node2D = null
	var closest_distance := INF

	# --- Buscar murallas ---
	var walls = get_tree().get_nodes_in_group("Muralla")
	for w in walls:
		if not is_instance_valid(w):
			continue
		if not (w is Node2D):
			continue
		if "destroyed" in w and w.destroyed:
			continue
		var dist = global_position.distance_to(w.global_position)
		if dist < closest_distance:
			closest_distance = dist
			closest_target = w

	# --- Si no hay murallas válidas, buscar player o base ---
	if closest_target == null:
		var candidates: Array[Node2D] = []
		candidates.append_array(get_tree().get_nodes_in_group("Player"))
		candidates.append_array(get_tree().get_nodes_in_group("Base"))

		for c in candidates:
			if not is_instance_valid(c):
				continue
			if not (c is Node2D):
				continue
			var dist = global_position.distance_to(c.global_position)
			if dist < closest_distance:
				closest_distance = dist
				closest_target = c

	current_target = closest_target
	return closest_target
