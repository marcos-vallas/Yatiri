extends Node2D

@export var enemy_hut: NodePath
@export var spawn_y: float = 333.0
@export var spawn_y_range: float = 5.0
@export var initial_delay: float = 15.0

@export var max_enemies_per_wave: int = 5
@export var spawn_interval: float = 3.0
@export var wave_interval: float = 10.0
@export var enemy2_y_offset: float = -20.0

@export var enemy_scenes: Array = [
	preload("res://scenes/enemy_1.tscn"),
	preload("res://scenes/enemy_1.tscn"),
	preload("res://scenes/enemy_2.tscn")
]

@export var idle_enemies_min: int = 3
@export var idle_enemies_max: int = 6

@export var activacion:bool=true

# -------------------- VARIABLES INTERNAS --------------------
var _hut_ref: Node2D
var _current_wave_enemies: int = 0
var _spawn_timer: Timer
var _is_wave_active: bool = false

# -------------------- READY --------------------
func _ready() -> void:
	if activacion:
		if enemy_hut != NodePath(""):
			_hut_ref = get_node(enemy_hut) as Node2D

		_spawn_timer = Timer.new()
		_spawn_timer.one_shot = true
		add_child(_spawn_timer)
		_spawn_timer.timeout.connect(_on_spawn_timer_timeout)

		_spawn_idle_enemies()
		_spawn_timer.start(initial_delay)

# -------------------- OLEADAS --------------------
func _on_spawn_timer_timeout() -> void:
	if _hut_ref == null or enemy_scenes.is_empty():
		push_warning("No hay referencia a enemy_hut o no hay enemigos cargados.")
		return

	if not _is_wave_active:
		_current_wave_enemies = randi() % max_enemies_per_wave + 1
		_is_wave_active = true

	if _current_wave_enemies > 0:
		var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = scene.instantiate()
		add_child(enemy)

		var spawn_x: float = _hut_ref.global_position.x
		var spawn_y_random: float = spawn_y + randf_range(-spawn_y_range, spawn_y_range)
		enemy.global_position = Vector2(spawn_x, spawn_y_random)

		_current_wave_enemies -= 1

		if _current_wave_enemies > 0:
			_spawn_timer.start(spawn_interval)
		else:
			_is_wave_active = false
			_spawn_timer.start(wave_interval)

# -------------------- ENEMIGOS INICIALES --------------------
func _spawn_idle_enemies() -> void:
	if _hut_ref == null:
		return

	var count := randi() % (idle_enemies_max - idle_enemies_min + 1) + idle_enemies_min
	var base_x: float = _hut_ref.global_position.x - 100.0

	await get_tree().process_frame

	for i in count:
		var enemy_scene: PackedScene = preload("res://scenes/enemy_2.tscn")
		var enemy = enemy_scene.instantiate()
		add_child(enemy)

		var offset_between := randf_range(60.0, 80.0)
		var spawn_x: float = base_x - (i * offset_between)
		var spawn_y_random: float = spawn_y + randf_range(-spawn_y_range, spawn_y_range)

		if enemy_scene.resource_path.ends_with("enemy_2.tscn"):
			spawn_y_random += enemy2_y_offset

		enemy.global_position = Vector2(spawn_x, spawn_y_random)

		# 🔄 Que miren hacia el Player (a la derecha, si la hut está a la izquierda)
		if "facing_right" in enemy:
			enemy.facing_right = true
			if enemy.has_node("AnimatedSprite2D"):
				var sprite = enemy.get_node("AnimatedSprite2D")
				sprite.flip_h = false

		# ⚙️ Estado inicial en IDLE
		if enemy.has_method("set_state"):
			enemy.set_state(enemy.State.IDLE)
		elif "state" in enemy:
			enemy.state = enemy.State.IDLE

		# ⏱️ Activarlos de forma escalonada (10 a 20 s)
		var delay = 10.0 + randf_range(5.0, 15.0)
		_start_enemy_after_delay(enemy, delay)

		await get_tree().create_timer(randf_range(1.0, 5.0)).timeout

# -------------------- ACTIVACIÓN ESCALONADA --------------------
func _start_enemy_after_delay(enemy: Node2D, delay: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = delay
	add_child(t)

	t.timeout.connect(func ():
		if not is_instance_valid(enemy):
			return
		if enemy.has_method("set_state"):
			enemy.set_state(enemy.State.WALK_FORWARD)
		elif "state" in enemy:
			enemy.state = enemy.State.WALK_FORWARD
	)
	t.start()
