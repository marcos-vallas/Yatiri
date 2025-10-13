extends Area2D

@export var fall_gravity: float = 1200.0
@export var damage: int = 10

# Ajustes de la trayectoria
@export var min_time_to_hit: float = 0.2
@export var max_time_to_hit: float = 0.8
@export var x_offset_random: float = 30.0
@export var y_offset_random: float = 10.0
@export var downward_bias: float = 100.0  # empuje extra hacia abajo

var vel: Vector2 = Vector2.ZERO

func _ready() -> void:
	monitoring = true
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _physics_process(delta: float) -> void:
	vel.y += fall_gravity * delta
	global_position += vel * delta

	if vel.length() > 0.1:
		rotation = vel.angle()

func _on_area_entered(area: Area2D) -> void:
	if (area.is_in_group("Muralla") or area.is_in_group("Base")) and area.has_method("take_damage"):
		if $Spear_Impact:
			$Spear_Impact.play()
		if $Spear:
			$Spear.visible = false
		if $CPUParticles2D:
			$CPUParticles2D.visible = false

		area.take_damage(damage)
		await get_tree().create_timer(0.2).timeout
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("take_damage"):
		if $Spear_Impact: $Spear_Impact.play()
		if $Spear: $Spear.visible = false
		if $CPUParticles2D: $CPUParticles2D.visible = false

		var knockback_dir = Vector2(sign(body.global_position.x - global_position.x), 0)
		body.take_damage(knockback_dir, true)

		await get_tree().create_timer(0.2).timeout
		queue_free()
		
	elif body.is_in_group("Ground"):
		$Spear.visible = false
		$CPUParticles2D.one_shot = true
		$CPUParticles2D.emitting = false
		$CPUParticles2D.speed_scale = 0
		await get_tree().create_timer(0.3).timeout
		queue_free()

func launch_towards_wall(wall: Node2D, time_to_hit: float = -1.0) -> void:
	if not wall or not wall.is_inside_tree():
		return
	if time_to_hit <= 0:
		time_to_hit = randf_range(min_time_to_hit, max_time_to_hit)
	_prepare_and_launch(wall.global_position, time_to_hit)

func launch_towards_muralla(muralla: Node2D, time_to_hit: float = -1.0) -> void:
	launch_towards_wall(muralla, time_to_hit)

func launch_towards_enemy(enemy: Node2D, time_to_hit: float = -1.0) -> void:
	launch_towards_wall(enemy, time_to_hit)

# ----------------------------
# Cálculo de trayectoria
# ----------------------------
func _prepare_and_launch(target_global_pos: Vector2, time_to_hit: float) -> void:
	var target_pos = target_global_pos
	target_pos.x += randf_range(-30.0, 30.0)   # dispersión horizontal
	target_pos.y += randf_range(-10.0, 10.0)   # dispersión vertical mínima

	var distance = target_pos - global_position

	# velocidad inicial para llegar en 'time_to_hit' segundos (g = fall_gravity)
	vel.x = distance.x / time_to_hit
	vel.y = (distance.y - 0.5 * fall_gravity * time_to_hit * time_to_hit) / time_to_hit
