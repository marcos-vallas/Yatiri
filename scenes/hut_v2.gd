# hut.gd
extends Area2D

@export_category("Variables")
# --- PROPIEDADES DE LA MURALLA ---
@export var max_health: int = 40     # Salud máxima inicial
var current_health: int = max_health # Salud actual
@export var costo_reparacion: int = 5 # Monedas necesarias para reparar
@export var reparacion_por_moneda: int = 2 # Health que se recupera por moneda
@export var radio_deteccion: float = 50.0 # Radio para detectar al jugador (si se usa un CircleShape2D)

@export_category("Sprites")
# --- ESCENAS Y NODOS ---
@export var sprite_normal: Sprite2D #= $SpriteNormal # Nodo Sprite 1 (Normal)
@export var sprite_destruido: Sprite2D # = $SpriteDestruido # Nodo Sprite 2 (Destruido)
@export var repair_label: Label #= $RepairLabel # Nodo Label para el texto de reparación
@export var health_label: Label
@export_category("Colisiones")
@export var muralla_collision : CollisionShape2D #= $CollisionShape2D
@export var static_collision : CollisionShape2D
@export var repair_collision : CollisionShape2D

# --- MÁQUINA DE ESTADOS ---
enum State { NORMAL, DESTRUIDA }
var current_state: int = State.NORMAL

# --- REFERENCIA AL JUGADOR ---
var is_player_in_area: bool = false

func _ready():
	add_to_group("Muralla")
	# Asegúrate de que los nodos Sprite estén configurados correctamente en la escena
	update_visuals()
	
	# Conexión para detectar entrada/salida del jugador (asumiendo que es un Area2D)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	# Aseguramos que el texto de reparación esté oculto al inicio
	repair_label.visible = false
#	Mostramos label de vida
	health_label.text =str(current_health) 
	health_label.visible = true

		# Asegurar que el StaticBody2D bloquee, pero esta Area2D reciba daño
	monitorable = true
	monitoring = true
	
	
func is_destroyed() -> bool:
	return State.DESTRUIDA
	
# Lógica para cambiar de estado
func set_state(new_state: int):
	current_state = new_state
	print("Muralla: Transición al estado: ", State.keys()[new_state])
	update_visuals()

# Actualiza qué sprite y colisión están activos
func update_visuals():
	match current_state:
		State.NORMAL:
			sprite_normal.visible = true
			sprite_destruido.visible = false
			# Ocultamos el texto de reparación
			repair_label.visible = false 
			# Si el juego es 2D, tal vez quieras cambiar la colisión si la muralla rota permite pasar
			muralla_collision.disabled = false 
			static_collision.disabled = false
			
		State.DESTRUIDA:
			sprite_normal.visible = false
			sprite_destruido.visible = true
			# Mostrará el texto de reparación si el jugador está cerca (ver _on_body_entered/exited)
			repair_label.visible = is_player_in_area 
			muralla_collision.disabled = true # Muralla Destruida = se puede pasar
			static_collision.disabled = true
			
			emit_signal("muralla_destruida")
			
			
			
			# Función llamada cuando la salud llega a cero
func take_damage(amount: int):
	current_health -= amount
	health_label.text =str(current_health) 
	
	if current_health <= 0:
		current_health = 0
		health_label.text =str(current_health) 
		if current_state != State.DESTRUIDA:
			set_state(State.DESTRUIDA)
	
	print("Salud Muralla: ", current_health)

# Función para reparar la muralla
func repair_wall(amount_paid: int):
	# La cantidad de health recuperada depende de la cantidad de monedas
	var recovered_health = amount_paid * reparacion_por_moneda
	current_health += recovered_health
	
	if current_health >= max_health:
		current_health = max_health
		set_state(State.NORMAL)
	
	print("Muralla reparada. Salud actual: ", current_health)

# --- ENTRADAS Y DETECCIÓN ---

# El GameManager u otro script puede llamar a esta función cuando el jugador presiona 'S'
func handle_player_input(event: InputEvent):
	if is_player_in_area and current_state == State.DESTRUIDA:
		if event.is_action_pressed("down"): # Asumiendo "ui_accept" es 'Enter' o similar (puedes cambiarlo a "reparar" si lo tienes en el Input Map)
			
			# --- Lógica de Reparación ---
			# 1. Verificar si el jugador tiene suficientes monedas (asumo un singleton 'Global')
			if Global.coins >= costo_reparacion: 
				Global.remove_coins(costo_reparacion) # Restamos el costo
				repair_wall(costo_reparacion) # Reparamos
			else:
				print("No hay suficientes monedas para reparar.")
				# Opcional: mostrar un mensaje de error al jugador
			
		
# Detección de entrada al Area2D de la muralla
func _on_body_entered(body):
	# Asume que el nodo del jugador tiene un script 'Player.gd'
	if body.is_in_group("Player"): 
		is_player_in_area = true
		print("Player entra al area")
		# Si está destruida, mostramos el mensaje de reparación
		if current_state == State.DESTRUIDA:
			repair_label.text = "Presiona 'S' para reparar: %d Monedas" % costo_reparacion
			repair_label.visible = true
		# Conectamos la entrada del jugador para la reparación
		# Nota: Es mejor que el jugador tenga una señal para notificar la pulsación de tecla, 
		# o que el GameManager maneje la entrada, pero por simplicidad, lo conectamos directamente.
		# body.connect("reparar_pressed", handle_repair_attempt) # Mejor con señal
		
# Detección de salida del Area2D de la muralla
func _on_body_exited(body):
	
	if body.is_in_group("Player"):
		is_player_in_area = false
		repair_label.visible = false
		# Desconectamos la entrada del jugador si ya no está cerca
		# body.disconnect("reparar_pressed", handle_repair_attempt)
