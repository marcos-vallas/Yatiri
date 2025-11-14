extends Area2D



@export_category("Stats")
@export var damage_unidades: int = 10
@export var damage_edificios: int = damage_unidades/5

@export_category("Trayectoria")
var calculation_gravity_multiplier: float = 1.5
@export var fall_gravity: float = 1200.0
# Ajustes de la trayectoria
@export var min_time_to_hit: float = 0.3
@export var max_time_to_hit_Close: float = 1.0
@export var max_time_to_hit_Far: float = 2.0
@export var x_offset_random: float = 30.0
@export var y_offset_random: float = 10.0
@export var correccion_altura : float = 0.5

@export var self_sprite : Sprite2D

var elevation_boost : float = 150.0
var elevation_scale: float = 1.5 # Ajusta este valor para controlar la intensidad del arco.



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
	if \
	(area.is_in_group("Muralla") or area.is_in_group("Base")):
		
		if $Spear_Impact:
			$Spear_Impact.play()
		if self_sprite != null : self_sprite.visible = false
		if $CPUParticles2D:
			$CPUParticles2D.visible = false
		if area.has_method("take_damage"):
			area.take_damage(damage_edificios)
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(0.2).timeout
		queue_free()
		#
	#if (area.is_in_group("Player_Body") \
	#or area.is_in_group("Aliado_1")  \
	#or area.is_in_group("Aliado_2")  \
	#or area.is_in_group("Tank"))  \
	#and area.has_method("take_damage"):
		#$CollisionShape2D.set_deferred("disabled",true)
		#if $Spear_Impact: $Spear_Impact.play()
		#if self_sprite != null : self_sprite.visible = false
		#if $CPUParticles2D: $CPUParticles2D.visible = false
#
		#var knockback_dir = Vector2(sign(area.global_position.x - global_position.x), 0)
		#area.take_damage(damage_unidades, knockback_dir, true)
#
		#await get_tree().create_timer(0.2).timeout
		#queue_free()
		
	elif area.is_in_group("Ground"):
		
		if self_sprite != null : self_sprite.visible = false
		$CPUParticles2D.one_shot = true
		$CPUParticles2D.emitting = false
		$CPUParticles2D.speed_scale = 0
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(0.3).timeout
		queue_free()


func _on_body_entered(body: Node) -> void:
	if \
	(body.is_in_group("Muralla") or body.is_in_group("Base")):
		
		if $Spear_Impact:
			$Spear_Impact.play()
		if self_sprite != null : self_sprite.visible = false
		if $CPUParticles2D:
			$CPUParticles2D.visible = false
		if body.has_method("take_damage"):
			body.take_damage(damage_edificios)
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(0.2).timeout
		queue_free()
#		PARA LOS NPC Y PLAYER SON BODIES
	elif (body.is_in_group("Player_Body")\
	 or body.is_in_group("Aliado_1")\
	 or body.is_in_group("Aliado_2")\
	 or body.is_in_group("Tank")):
		
		if $Spear_Impact: $Spear_Impact.play()
		if self_sprite != null : self_sprite.visible = false
		if $CPUParticles2D: $CPUParticles2D.visible = false
		
		if body.has_method("take_damage"):
			var knockback_dir = Vector2(sign(body.global_position.x - global_position.x), 0)
			body.take_damage(damage_unidades, knockback_dir, true)
		$CollisionShape2D.set_deferred("disabled",true)
		await get_tree().create_timer(0.2).timeout
		queue_free()
		
	elif body.is_in_group("Ground"):
		
		if self_sprite != null : self_sprite.visible = false
		$CPUParticles2D.one_shot = true
		$CPUParticles2D.emitting = false
		$CPUParticles2D.speed_scale = 0
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(0.3).timeout
		queue_free()

func launch_towards_wall(objetivo: Node2D, time_to_hit: float = -1.0) -> void:
	if not objetivo or not objetivo.is_inside_tree():
		return
	if time_to_hit <= 0:
		time_to_hit =  randf_range(min_time_to_hit, max_time_to_hit_Close)
		
	#if objetivo.is_in_group("Aliado_1"):
		#elevation_boost = 150
		#fall_gravity = 2200
	#else: 
		#elevation_boost = 0
		#fall_gravity = 1500
	_prepare_and_launch(objetivo.global_position, time_to_hit)

func launch_towards_muralla(muralla: Node2D, time_to_hit: float = -1.0) -> void:
	launch_towards_wall(muralla, time_to_hit)

func launch_towards_enemy(enemy: Node2D, time_to_hit: float = -1.0) -> void:
	launch_towards_wall(enemy, time_to_hit)


# ----------------------------
# Cálculo de trayectoria
# ----------------------------
func _prepare_and_launch(target_global_pos: Vector2, time_to_hit: float) -> void:
	var target_pos = target_global_pos
	# Usa las variables exportadas para la dispersión
	target_pos.x += randf_range(-x_offset_random, x_offset_random)
	target_pos.y += randf_range(-y_offset_random, y_offset_random)

	var distance = target_pos - global_position
	
	if (distance.x < -450) or (distance.x > 450):
		#print(distance.x)
		time_to_hit += (max_time_to_hit_Far - time_to_hit)/2

	# Cálculo de la velocidad inicial (como estaba antes)
	# vel.x para llegar en 'time_to_hit'
	vel.x = distance.x / time_to_hit
	# vel.y para compensar la gravedad y llegar a distance.y
	vel.y = (distance.y - 0.5 * fall_gravity * time_to_hit * time_to_hit) / time_to_hit
	vel.y -= correccion_altura
	# --- MODIFICACIÓN CLAVE ---
	# Restar (empujar hacia arriba) el 'elevation_boost' a la velocidad inicial vertical.
	# Esto aumenta la altura máxima sin cambiar el tiempo de vuelo o el destino.
	#vel.y -= elevation_boost 


# ----------------------------
# Cálculo de trayectoria
# ----------------------------
func _prepare_and_launch2(target_global_pos: Vector2, time_to_hit: float) -> void:
	var target_pos = target_global_pos
	# Añadir dispersión (usando variables exportadas)
	target_pos.x += randf_range(-x_offset_random, x_offset_random)
	target_pos.y += randf_range(-y_offset_random, y_offset_random)

	var distance = target_pos - global_position

	# --- MODIFICACIÓN CLAVE: Gravedad de CÁLCULO ---
	# Usamos la gravedad multiplicada solo para el cálculo, no para la simulación
	var g_calc = fall_gravity * calculation_gravity_multiplier
	
	# Cálculo dinámico del Elevation Boost (basado en la distancia X)
	var horizontal_distance: float = abs(distance.x)
	var calculated_elevation_boost: float = horizontal_distance * elevation_scale
	
	# ---------------------------------------------
	
	# Cálculo de la velocidad inicial (Horizontal)
	vel.x = distance.x / time_to_hit
	
	# Cálculo de la velocidad inicial (Vertical)
	# Reemplazamos 'fall_gravity' por 'g_calc' en la fórmula.
	vel.y = (distance.y - 0.5 * g_calc * time_to_hit * time_to_hit) / time_to_hit
	
	# Aplicar el boost dinámico adicional (después del cálculo base):
	vel.y -= calculated_elevation_boost 
