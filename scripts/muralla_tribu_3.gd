# muralla_tribu.gd
extends Area2D

class_name Muralla_Tribu

# Señal original
signal muralla_destruida

# --- MÁQUINA DE ESTADOS ---
enum State { NORMAL, DESTRUIDA, DAMAGED }
var current_state: int = State.NORMAL

# --- PROPIEDADES ---
@export var max_health: int

var current_health: int = max_health
@export var costo_reparacion: int  # Monedas necesarias para la reparación
# @export var reparacion_por_moneda: int = 2 # Ya no es necesaria, repararemos al 100%

# --- NODOS (Renombrados para claridad) ---
@export var sprite_normal: Sprite2D #= $Muralla
@export var sprite_destruido: Sprite2D# = $Muralla2 # Asumimos que es el sprite de la muralla rota
@export var muralla_area_collision: CollisionShape2D #= $MurallaCollision # Colisión del Area2D (para DETECCIÓN del jugador)
@export var static_body: StaticBody2D #= $StaticBody2D
@export var static_collision: CollisionShape2D #= $StaticBody2D/CollisionShape2D # Colisión del StaticBody2D (para BLOQUEO de paso)
@export var texto_vida : Label #= $VidaMuralla
@export var repair_label: Label #= $RepairLabel # Etiqueta de texto para reparación

# --- LÓGICA DE DAÑO Y FLASH (Mantenemos la lógica original) ---
var damage_flash_count: int = 2
var damage_flash_duration: float = 0.1
var flash_counter: int = 0
var flash_timer: Timer
var is_flashing := false
var is_player_in_area: bool = false # Rastrea si el jugador está en el área de detección

func _ready() -> void:
	add_to_group("Muralla")
	
	# Setup de la detección del Area2D
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	# Inicialización del Timer de flash
	flash_timer = Timer.new()
	flash_timer.one_shot = false
	add_child(flash_timer)
	flash_timer.timeout.connect(_on_flash_timer_timeout)

	current_health = max_health
	# Inicialización del estado
	set_state(State.NORMAL)
	#texto_vida.text = str(current_health)
	update_health_display()
	
func _init() -> void:
	#set_state(State.NORMAL)
	#update_health_display()
	pass

# ¡NUEVO! Lógica de INPUT con Polling en _process
func _process(_delta: float) -> void:
	## Solo chequeamos el input si:
	## 1. La muralla está destruida.
	## 2. El jugador está en el área de detección.
	#if current_state == State.DESTRUIDA and is_player_in_area:
		#
		## Usamos polling para detectar si la acción "reparar" fue pulsada
		#if Input.is_action_pressed("down"):   
			## --- Lógica de Reparación ---
			#if Engine.has_singleton("Global"):
					## Asumimos que Global es tu singleton y tiene current_coins
				#var Global = Engine.get_singleton("Global")
					#
				#if Global.current_coins >= costo_reparacion: 
					#Global.current_coins -= costo_reparacion 
					#current_health = max_health 
					#set_state(State.NORMAL) # Volver a NORMAL
					#print("¡Muralla reparada con éxito!")
				#else:
						## Opcional: Podrías mostrar un mensaje de "No hay monedas" en repair_label
					#print("Reparación fallida: Monedas insuficientes. Necesitas %d" % costo_reparacion)
	pass









# --- GESTIÓN DE ESTADOS Y VISUALES ---

func set_state(new_state: int) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	print("Muralla: Transición al estado: ", State.keys()[new_state])
	
	match current_state:
		State.NORMAL:
			remove_from_group("Destroyed_Muralla")
			add_to_group("Muralla")
			# Sprite Normal
			sprite_normal.visible = true
			sprite_destruido.visible = false
			
			# Colisiones: Bloquea el paso (StaticBody ON) y mantiene detección (Area2D ON)
			static_collision.disabled = false 
			static_body.visible = true
			
			# Oculta el texto de reparación
			repair_label.visible = false 
			
			# Actualiza el texto de vida
			update_health_display()
			
		State.DAMAGED:
			remove_from_group("Destroyed_Muralla")
			add_to_group("Muralla")
			# Sprite Normal
			sprite_normal.visible = true
			sprite_destruido.visible = false
			
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
			remove_from_group("Muralla")
			add_to_group("Destroyed_Muralla")
			
			
			
			# Sprite Destruido
			sprite_normal.visible = false
			sprite_destruido.visible = true
			
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
			repair_label.visible = true
			
# Detección de salida del Area2D de la muralla
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("SalePlayer")
		is_player_in_area = false
		repair_label.visible = false

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
				
		# Necesitamos la referencia al Singleton Global (donde guardas las monedas)
		#if Engine.has_singleton("Global"):
			#var Global = Engine.get_singleton("Global")
			#
			#if Global.current_coins >= costo_reparacion: 
				## Repara: 1. Paga, 2. Repara, 3. Cambia de estado
				#Global.current_coins -= costo_reparacion 
				#current_health = max_health # Reparación al 100%
				#set_state(State.NORMAL)
				#
				#print("¡Muralla reparada con éxito!")
				#get_viewport().set_input_as_handled() # Consumimos el evento
			#else:
				#print("Reparación fallida: Monedas insuficientes. Necesitas %d" % costo_reparacion)

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
