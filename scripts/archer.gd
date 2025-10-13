extends CharacterBody2D
class_name Archer

# -------------------- VARIABLES --------------------
var attack_cooldown := false
var preloadArrow = preload("res://scenes/arrow.tscn")

@export var health: int = 30
@export var knockback_force: float = 200.0
@export var knockback_friction: float = 800.0
@export var damage_flash_time: float = 0.2
@export var flash_duration: float = 0.4
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var flashing: bool = false
var is_dead := false
var is_hurt := false

func _ready() -> void:
	# Idle inicial con frame aleatorio
	_play_idle()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Mover con velocity y desacelerar
	if velocity != Vector2.ZERO:
		move_and_slide()
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	# Si terminó hurt, volver a idle
	if is_hurt and animated_sprite.animation != "hurt":
		is_hurt = false
		_play_idle()

func do_attack() -> void:
	if attack_cooldown or is_dead or not is_inside_tree():
		return

	attack_cooldown = true
	animated_sprite.play("attack")

	# Elegir el enemigo más cercano
	var enemies = get_tree().get_nodes_in_group("Enemy")
	enemies = enemies.filter(func(e): return e and e.is_inside_tree())
	if enemies.size() == 0:
		attack_cooldown = false
		_play_idle()
		return

	var closest_enemy = enemies[0]
	var min_dist = global_position.distance_to(closest_enemy.global_position)
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			closest_enemy = e

	animated_sprite.flip_h = closest_enemy.global_position.x < global_position.x

	# Instanciar flecha
	await get_tree().create_timer(0.3).timeout
	var arrow = preloadArrow.instantiate()
	arrow.global_position = $ArrowPosition.global_position
	get_parent().add_child(arrow)
	if closest_enemy.is_inside_tree():
		arrow.launch_towards_enemy(closest_enemy)

	if $Attack:
		$Attack.pitch_scale = randf_range(0.8, 1.0)
		$Attack.play()

	# Esperar que termine la animación para volver a idle
	await animated_sprite.animation_finished
	attack_cooldown = false
	if not is_dead:
		_play_idle()


func take_damage(from_direction: Vector2, _unused: bool = true) -> void:
	if health <= 0 or is_dead:
		return

	var damage = 10
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
	remove_from_group("Player")
	$CollisionShape2D.disabled = true
	attack_cooldown = true
	animated_sprite.play("death")
	if $Steps:
		$Steps.stop()
	Global.remove_tribe_member()
	var tween := create_tween()
	tween.tween_interval(7)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 3.5)
	tween.tween_callback(Callable(self, "_on_fade_out_finished"))

func _on_fade_out_finished() -> void:
	queue_free()

func _play_idle() -> void:
	if is_dead:
		return
	animated_sprite.play("idle")
	animated_sprite.frame = randi() % animated_sprite.sprite_frames.get_frame_count("idle")
