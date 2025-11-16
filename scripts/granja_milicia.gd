# muralla_tribu.gd
extends Area2D

class_name Granja_Milicia


@export_category("Stats")
# --- PROPIEDADES ---
@export var max_health: int
var current_health: int = max_health
@export_category("Costos")
@export var costo_reparacion: int = 1 # Monedas necesarias para la reparación
@export var costo_reclutamiento : int = 2
# @export var reparacion_por_moneda: int = 2 # Ya no es necesaria, repararemos al 100%

@export_category("Collisions")
@export var static_body: StaticBody2D #= $StaticBody2D
@export var static_collision: CollisionShape2D #= $StaticBody2D/CollisionShape2D # Colisión del StaticBody2D (para BLOQUEO de paso)
@export var muralla_area_collision: CollisionShape2D #= $MurallaCollision # Colisión del Area2D (para DETECCIÓN del jugador)
@export_category("Spawner")
@export var Spawner : Base_Spawner 

@export_category("Visuales")
# --- NODOS (Renombrados para claridad) ---
@export var sprite_normal: Sprite2D #= $Muralla
@export var sprite_destruido: Sprite2D# = $Muralla2 # Asumimos que es el sprite de la muralla rota
@export var texto_vida : Label #= $VidaMuralla
@export var repair_label: Label #= $RepairLabel # Etiqueta de texto para reparación
@export var farm_label: Label

# Señal original
signal muralla_destruida

# --- MÁQUINA DE ESTADOS ---
enum State { NORMAL, DESTRUIDA, DAMAGED }
var current_state: int = State.NORMAL

#Tendria que heredar de edificio_aliado

enum State_Farm {DISABLED, READY, FARMING, PRODUCING}
var current_state_farm = State_Farm.READY

# --- LÓGICA DE DAÑO Y FLASH (Mantenemos la lógica original) ---
var damage_flash_count: int = 2
var damage_flash_duration: float = 0.1
var flash_counter: int = 0
var flash_timer: Timer
var farm_timer: Timer
var is_flashing := false
var is_player_in_area: bool = false # Rastrea si el jugador está en el área de detección

func _ready() -> void:
	add_to_group("Granja_bots")
	
	# Setup de la detección del Area2D
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	# Inicialización del Timer de flash
	flash_timer = Timer.new()
	flash_timer.one_shot = false
	add_child(flash_timer)
	flash_timer.timeout.connect(_on_flash_timer_timeout)
	
	# Inicialización del Timer de flash
	farm_timer = Timer.new()
	farm_timer.one_shot = false
	add_child(farm_timer)
	farm_timer.timeout.connect(_on_farm_timer_timeout)


	current_health = max_health
	# Inicialización del estado
	set_state(State.NORMAL)
	set_state_farm(State_Farm.READY)
	set_state(State.DESTRUIDA)
	#texto_vida.text = str(current_health)
	update_health_display()
	
	#Spawner.farm_spawning = true
	
func _init() -> void:
	#set_state(State.DESTRUIDA)
	#update_health_display()
	pass

# ¡NUEVO! Lógica de INPUT con Polling en _process
func _process(_delta: float) -> void:
	if current_state == State.NORMAL:
		if current_state_farm == State_Farm.DISABLED:
			set_state_farm(State_Farm.READY)
	if current_state == State.DESTRUIDA:
		set_state_farm(State_Farm.DISABLED)
	pass

func set_state_farm(new_state: int) -> void:
#	{DISABLED, READY, FARMING, PRODUCING}
	if current_state_farm == new_state:
		return
	current_state_farm = new_state
	
	match current_state_farm:
		State_Farm.DISABLED:
			print("Milica Farm Disabled")
			farm_label.visible = false
			pass
		State_Farm.READY:
			print("Milicia Farm Ready")
			farm_label.text = "Presiona 'S' para reclutar: %d Monedas" % costo_reclutamiento
			farm_label.visible = true
			pass
		State_Farm.FARMING:
			Global.cumplir_objetivo(4)
			print("Farming")
			
			farm_label.text = "Reclutando.."
			farm_label.visible = true
			pass
		State_Farm.PRODUCING:
			print("Milica Farm Producing")
			farm_label.text = "Reclutando.."
			farm_label.visible = true
			pass
	
	pass

# --- GESTIÓN DE ESTADOS Y VISUALES ---

func set_state(new_state: int) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	print("Muralla: Transición al estado: ", State.keys()[new_state])
	
	match current_state:
		State.NORMAL:
			Global.cumplir_objetivo(3)
			remove_from_group("Granja_bots_destroyed")
			add_to_group("Granja_bots")
			# Sprite Normal
			if sprite_normal != null : sprite_normal.visible = true
			if sprite_destruido != null : sprite_destruido.visible = false
			
			# Colisiones: Bloquea el paso (StaticBody ON) y mantiene detección (Area2D ON)
			static_collision.disabled = false 
			static_body.visible = true
			
			# Oculta el texto de reparación
			repair_label.visible = false 
			
			# Actualiza el texto de vida
			update_health_display()
			
			
			
		State.DAMAGED:
			remove_from_group("Granja_bots_destroyed")
			add_to_group("Granja_bots")
			# Sprite Normal
			if sprite_normal != null :sprite_normal.visible = true
			if sprite_destruido != null :sprite_destruido.visible = false
			
			# Colisiones: Bloquea el paso (StaticBody ON) y mantiene detección (Area2D ON)
			static_collision.disabled = false 
			static_body.visible = true
			
			# Muestra el texto de reparación
			repair_label.visible = true 
			
			# Muestra el texto de reparación (si el jugador está cerca)
			repair_label.text = "Presiona 'S' para reparar: %d Monedas" % costo_reparacion
			repair_label.visible = is_player_in_area
			update_health_display()
			pass
			

		State.DESTRUIDA:
			remove_from_group("Granja_bots")
			add_to_group("Granja_bots_destroyed")
			
			set_state_farm(State_Farm.DISABLED)
			
			# Sprite Destruido
			if sprite_normal != null : sprite_normal.visible = false
			if sprite_destruido != null :sprite_destruido.visible = true
			
			# Colisiones: Permite el paso (StaticBody OFF) pero mantiene detección (Area2D ON)
			static_collision.disabled = true 
			static_body.visible = false
			
			# Muestra el texto de reparación (si el jugador está cerca)
			repair_label.text = "Presiona 'S' para reparar: %d Monedas" % costo_reparacion
			repair_label.visible = is_player_in_area
			
			# Emitimos la señal para el resto del juego
			emit_signal("muralla_destruida") 
			update_health_display()
			
			
			

func is_destroyed() -> bool:
	var destruida = false
	#print("Muralla no destruida")
	if current_state == State.DESTRUIDA:
		destruida = true
	return destruida
# --- LÓGICA DE DETECCIÓN Y INPUT ---

# Detección de entrada al Area2D de la muralla
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_player_in_area = true
		print("EntraPlayer")
		if current_state == State.DESTRUIDA or current_state == State.DAMAGED:
			print("DESTRUIDA or DAMAGED")
			repair_label.visible = true
		if (current_state_farm == State_Farm.READY) or (current_state_farm == State_Farm.FARMING):
			farm_label.visible = true
			print("READY or FARMING")
			
# Detección de salida del Area2D de la muralla
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("SalePlayer")
		is_player_in_area = false
		repair_label.visible = false
		farm_label.visible = false

# Manejo de Input: La forma más limpia de manejar la reparación
func _unhandled_input(event: InputEvent) -> void:
	# Solo procesamos si está destruida, el jugador está en el área, y pulsa 'S'
	# ASUMIMOS que tienes una acción en el Input Map llamada "reparar" asignada a la tecla 'S'
	if (current_state == State.DESTRUIDA or current_state == State.DAMAGED) and is_player_in_area and event.is_action_pressed("down"): 
		print("Reparo con S")
		# --- Lógica de Reparación ---
		# 1. Verificar si el jugador tiene suficientes monedas (asumo un singleton 'Global')
		if Global.coins >= costo_reparacion: 
			Global.remove_coins(costo_reparacion) # Restamos el costo
			repair_wall(costo_reparacion) # Reparamos
		else:
			print("No hay suficientes monedas para reparar.")
			# Opcional: mostrar un mensaje de error al jugador
	if (current_state_farm == State_Farm.READY) and (current_state == State.NORMAL) and is_player_in_area and event.is_action_pressed("down"):
		
		if Global.coins >= costo_reclutamiento: 
			set_state_farm(State_Farm.FARMING)
			Global.remove_coins(costo_reclutamiento) # Restamos el costo
			reclutar(costo_reclutamiento) # Reparamos
		else:
			print("No hay suficientes monedas para reclutar.")
			# Opcional: mostrar un mensaje de error al jugador
				
	
func reclutar(amount_paid: int):
	set_state_farm(State_Farm.PRODUCING)
	farm_timer.start(1.5)
	Spawner.iniciar_spawn(Spawner.unidades_a_spawnear_lista)
	
	pass
	
	
func repair_wall(amount_paid: int):
	# La cantidad de health recuperada depende de la cantidad de monedas
	var recovered_health = amount_paid * 5#reparacion_por_moneda
	current_health += recovered_health
	
	if current_health >= max_health:
		current_health = max_health
		set_state(State.NORMAL)
	
	if (current_health > (max_health / 5) and current_health < max_health):
		set_state(State.DAMAGED)
		
	update_health_display()
	
	print("Muralla reparada. Salud actual: ", current_health)
# --- LÓGICA DE DAÑO ---

func take_damage(amount: int, kb= Vector2(0,0)) -> void:
	if current_state == State.DESTRUIDA:
		update_health_display()
		return
	
	$Hit.play()
	current_health -= amount
	
	if current_health < max_health:
		set_state(State.DAMAGED)
		
	if current_health <= 0:
		current_health = 0
		set_state(State.DESTRUIDA) # Transición a estado DESTRUIDA
	else:
		_start_flash()
	
	update_health_display()

func update_health_display() -> void:
	texto_vida.text = str(current_health)

# --- LÓGICA DE FLASH (Original) ---
func _start_flash() -> void:
	if is_flashing: return
	is_flashing = true
	flash_counter = 0
	flash_timer.start(damage_flash_duration)

func _stop_flash():
	flash_timer.stop()
	is_flashing = false
	if sprite_normal.visible and sprite_normal.material:
		sprite_normal.material.set_shader_parameter("effect_enabled", false)

func _on_farm_timer_timeout() -> void:
	set_state_farm(State_Farm.READY)
	
	pass
func _on_flash_timer_timeout() -> void:
	if flash_counter < damage_flash_count * 2:
		var active = flash_counter % 2 == 0
		if sprite_normal.material:
			sprite_normal.material.set_shader_parameter("effect_enabled", active)
		if sprite_destruido.material:
			# Solo si está en NORMAL debería flashear sprite_normal
			# Si está en destruida, probablemente no necesite flashear a menos que se repare.
			pass
		flash_counter += 1
	else:
		_stop_flash()
