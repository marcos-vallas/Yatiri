extends CharacterBody2D
class_name Player

@export var attack_knockback: float = 25.0
@export var health: int = 100
@export var flash_duration: float = 0.4
@export var knockback_friction: float = 500.0
@export var attack_offset: float = 50.0   # offset para izquierda

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var steps: AudioStreamPlayer2D = $Steps
@onready var attack_sound: AudioStreamPlayer = $Attack
@onready var camera: Camera2D = $Camera2D
@onready var exhala: AnimatedSprite2D = $Exhala
@onready var coin_scene: PackedScene = preload("res://scenes/dropped_coin.tscn")
@export var lightning_scene: PackedScene = preload("res://scenes/lightning.tscn")

@export var run_speed: float = 200.0   # velocidad corriendo
@export var walk_speed: float = 100.0  # velocidad caminando normal
@export var run_duration: float = 5.0  # máximo tiempo corriendo
@export var rest_duration: float = 6.0 # tiempo mínimo caminando antes de poder volver a correr

var run_timer: float = 0.0
var rest_timer: float = 0.0
var is_running: bool = false

var base_attack_area_position: Vector2
var direction: Vector2 = Vector2.ZERO
var facing_direction: int = 1  # 1 = derecha, -1 = izquierda

var is_attacking: bool = false
var is_magic_attacking: bool = false   # ⚡ nuevo
var is_hurt: bool = false
var flashing: bool = false
var is_dead := false

var knockback_timer: float = 0.0
var knockback_duration: float = 0.2

var can_play_hit_sound := true

func _ready() -> void:

	add_to_group("Player")

	var grupos = ["Muralla", "Muralla Enemiga", "Hut Enemigo", "Base"]
	for grupo in grupos:
		for nodo in get_tree().get_nodes_in_group(grupo):
			if nodo.has_signal("muralla_destruida"):
				nodo.muralla_destruida.connect(_on_muralla_destruida)

	base_attack_area_position = attack_area.position
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	attack_shape.disabled = true
	_update_attack_area_direction()
	$Exhala.hide()
	
func _on_muralla_destruida():
	camera_shake(2.0, 1.5)
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# --- Movimiento ---
	direction.x = Input.get_axis("left", "right")

	# Actualizar facing_direction si se mueve
	if direction.x != 0:
		facing_direction = sign(direction.x)

	# Actualizar attack_area según dirección
	_update_attack_area_direction()

	# --- Lógica correr / caminar ---
	if Input.is_action_pressed("run") and rest_timer <= 0.0 and direction.x != 0 and not is_attacking and not is_magic_attacking and not is_hurt:
		# Correr
		is_running = true
		run_timer += delta
		if run_timer >= run_duration:
			# se cansa
			is_running = false
			rest_timer = rest_duration
			run_timer = 0.0
			$Exhala.show()  # mostrar exhala solo al cansarse
			await get_tree().create_timer(3).timeout
			$Exhala.hide()  # mostrar exhala solo al cansarse
			
	else:
		# caminar o descansar
		is_running = false
		if rest_timer > 0.0:
			rest_timer -= delta
			if rest_timer <= 0.0:
				$Exhala.hide()  # ocultar exhala cuando terminó de descansar

	# Determinar velocidad actual
	var current_speed = walk_speed
	if is_running:
		current_speed = run_speed

	# Aplicar movimiento horizontal
	if not is_attacking and not is_magic_attacking and not is_hurt:
		velocity.x = direction.x * current_speed
	elif is_hurt:
		# aplicar freno durante knockback
		if knockback_timer > 0:
			knockback_timer -= delta
			velocity.x = move_toward(velocity.x, 0, knockback_friction * delta)
		else:
			is_hurt = false

	# --- Animaciones y ataque ---
	if is_attacking:
		if animated_sprite.animation == "attack" and animated_sprite.frame == 2:
			attack_shape.disabled = false
		else:
			attack_shape.disabled = true

	elif is_magic_attacking:
		pass  # no hacer nada extra durante magia

	elif not is_hurt:
		if Input.is_action_just_pressed("attack") and not is_attacking:
			_start_attack()
		elif Input.is_action_just_pressed("magic") and not is_magic_attacking:
			_start_magic_attack()
		elif direction.x != 0:
			if animated_sprite.animation != "run":
				steps.pitch_scale = randf_range(0.8, 1.0)
				steps.play()
				animated_sprite.play("run")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
			if steps.playing:
				steps.stop()

	move_and_slide()


func _update_attack_area_direction() -> void:
	if facing_direction > 0:
		animated_sprite.flip_h = false
		exhala.flip_h = false
		exhala.rotation_degrees = 90
		exhala.position.x = abs(exhala.position.x)
		attack_area.position = base_attack_area_position
	else:
		animated_sprite.flip_h = true
		exhala.flip_h = true
		exhala.rotation_degrees = -90
		exhala.position.x = -abs(exhala.position.x)
		attack_area.position = base_attack_area_position + Vector2(-attack_offset, 0)
		
		
# --- ATAQUE FÍSICO ---
func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("attack")
	if steps.playing:
		steps.stop()
	attack_sound.play()

	await animated_sprite.animation_finished
	is_attacking = false
	attack_shape.disabled = true

# --- ATAQUE MÁGICO ---
func _start_magic_attack() -> void:
	if Global.potions <= 0:
		return
	
	is_magic_attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("magic")
	_spawn_lightning()
	$Magic.play()
	camera_shake(1.0, 1.5)
	Global.remove_potions(1)
	if steps.playing:
		steps.stop()


	await animated_sprite.animation_finished
	is_magic_attacking = false

func _spawn_lightning() -> void:
	var lightning = lightning_scene.instantiate()
	get_tree().current_scene.add_child(lightning)

	var horizontal_offset = 70  
	var offset = Vector2(horizontal_offset, -100)

	if facing_direction < 0:
		lightning.anim.flip_h = false
	else:
		lightning.anim.flip_h = true

	lightning.global_position = global_position + Vector2(horizontal_offset * facing_direction, -160)

	lightning.direction = facing_direction

func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		play_hit_sound()
		var dir = Vector2(sign(body.global_position.x - global_position.x), 0) * attack_knockback
		body.take_damage(33, dir)
		camera_shake(0.2, 1.0)  # duración 0.2s, intensidad 3.0

func _on_attack_area_area_entered(area: Area2D) -> void:
	if (area.is_in_group("Muralla Enemiga") or area.is_in_group("Hut Enemigo")) and area.has_method("take_damage"):
		play_hit_sound()
		area.take_damage(10)
		camera_shake(0.2, 2.0)  # duración 0.2s, intensidad 3.0

func play_hit_sound():
	if can_play_hit_sound:
		$AttackHit.play()
		can_play_hit_sound = false
		await get_tree().create_timer(0.15).timeout  # 150 ms de cooldown
		can_play_hit_sound = true

func take_damage(knockback_dir: Vector2, hit_from_right: bool) -> void:
	if is_dead:
		return

	$AttackHit.play()
	flash_white()
	_drop_coin(hit_from_right)

	var knockback_strength = 250
	velocity = knockback_dir.normalized() * knockback_strength
	is_hurt = true
	knockback_timer = knockback_duration
	camera_shake(0.2, 3.0)  # duración 0.2s, intensidad 3.0
	# reproducir animación hurt solo si no estás atacando
	if not is_attacking and not is_magic_attacking: # ⚡ agregado
		animated_sprite.play("hurt")

	await get_tree().create_timer(1.5).timeout

	if direction.x == 0 and not is_attacking and not is_magic_attacking: # ⚡ agregado
		animated_sprite.play("idle")
	elif direction.x != 0 and not is_attacking and not is_magic_attacking: # ⚡ agregado
		animated_sprite.play("run")

	if Global.coins <= 0:
		die()

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

func die() -> void:
	is_dead = true
	$CollisionShape2D.disabled = true
	animated_sprite.play("death")
	velocity = Vector2.ZERO
	animated_sprite.position.y += 6

	await get_tree().create_timer(3.5).timeout
	Global.game_result_text = "¡Perdiste!\n\n¿Jugar de nuevo?"
	await get_tree().create_timer(0.05).timeout 
	get_tree().change_scene_to_file("res://scenes/game_over_screen.tscn")

func camera_shake(duration: float, amount: float) -> void:
	if $Camera2D != null:
		$Camera2D.start_shake(duration, amount)

func _drop_coin(hit_from_right: bool):
	if Global.coins <= 0:
		return

	Global.remove_coins(1)
	var coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)
	coin.global_position = global_position + Vector2(0, -10)

	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() == 0:
		return

	var enemy_node = enemies[randi() % enemies.size()]
	coin.launch(hit_from_right, enemy_node)
