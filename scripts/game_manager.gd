
# GameManager.gd
extends Node

# --- Exportar variables para fácil configuración en el Inspector ---
@export var tiempo_dia: float = 300.0 # Duración del ciclo DÍA en segundos (5 minutos)
@export var tiempo_noche: float = 180.0 # Duración del ciclo NOCHE en segundos (3 minutos)
@export var cantidad_base_enemigos: int = 5 # Cantidad base de enemigos en la primera noche
@export var incremento_por_noche: int = 3 # Incremento de enemigos por cada noche
@export var spawn_intervalo_base: float = 1.5 # Intervalo base entre spawns (segundos)
@export var spawn_punto: Marker2D # Punto donde se van a spawnear los enemigos (asigna en el Inspector)
@export var enemigo_escena: PackedScene # La escena del enemigo que ya tienes (asigna en el Inspector)

# --- Variables de estado ---
var es_de_noche: bool = false
var noche_actual: int = 0
var enemigos_a_spawnear: int = 0
var enemigos_spawneados: int = 0
var tiempo_restante: float = 0.0

# --- Nodos Auxiliares ---
# Usa un Timer para controlar el intervalo de spawn
@onready var spawn_timer: Timer = $SpawnTimer # Asegúrate de añadir un nodo Timer como hijo


# --- Setup Inicial ---
func _ready():
	tiempo_restante = tiempo_dia
	es_de_noche = false
	# Conecta la señal del Timer para saber cuándo spawnear
	spawn_timer.connect("timeout", _on_SpawnTimer_timeout)
	# Inicialmente, el Timer de spawn está detenido
	spawn_timer.stop()
	print("Iniciando ciclo: DÍA ☀️")

# --- Bucle Principal del Tiempo ---
func _process(delta):
	tiempo_restante -= delta

	if tiempo_restante <= 0:
		if es_de_noche:
			# Transición: NOCHE -> DÍA
			iniciar_dia()
		else:
			# Transición: DÍA -> NOCHE
			iniciar_noche()

# --- Funciones de Transición de Ciclo ---

func iniciar_dia():
	es_de_noche = false
	tiempo_restante = tiempo_dia
	# Detenemos el spawn de enemigos
	spawn_timer.stop()
	enemigos_spawneados = 0
	print("Transición a DÍA ☀️")
	# Aquí puedes añadir código para cambiar iluminación, música, etc.

func iniciar_noche():
	es_de_noche = true
	noche_actual += 1
	tiempo_restante = tiempo_noche
	
	# 1. Calcular la cantidad de enemigos para esta oleada
	enemigos_a_spawnear = calcular_oleada(noche_actual)
	
	# 2. Configurar el Timer para el spawn
	var intervalo = calcular_intervalo_spawn(enemigos_a_spawnear)
	spawn_timer.wait_time = intervalo
	spawn_timer.start() # Iniciamos el Timer de spawn
	
	print("Transición a NOCHE 🌑 - Oleada #%d. Total Enemigos: %d" % [noche_actual, enemigos_a_spawnear])
	# Aquí puedes añadir código para cambiar iluminación, música de terror, etc.

# --- Lógica de la Oleada ---

func calcular_oleada(noche: int) -> int:
	# Fórmula simple: Base + (Noche_Actual - 1) * Incremento
	# La Noche 1 usará la cantidad_base_enemigos
	return cantidad_base_enemigos + (noche - 1) * incremento_por_noche

func calcular_intervalo_spawn(cantidad_enemigos: int) -> float:
	# Mantenemos el intervalo base, pero puedes hacer una lógica más compleja
	# Por ejemplo, para que los enemigos salgan más rápido en oleadas grandes:
	# return max(0.5, spawn_intervalo_base - (cantidad_enemigos * 0.05))
	return spawn_intervalo_base

# --- Función de Spawn ---

func _on_SpawnTimer_timeout():
	if enemigos_spawneados < enemigos_a_spawnear:
		spawn_enemigo()
		enemigos_spawneados += 1
		
		# Si se spawneó el último enemigo de la oleada, detenemos el Timer
		if enemigos_spawneados == enemigos_a_spawnear:
			spawn_timer.stop()
			print("¡Todos los enemigos de la oleada han sido spawneados!")
	
# --- Función para instanciar y añadir el enemigo ---
func spawn_enemigo():
	if not enemigo_escena:
		print("ERROR: La escena del enemigo no está asignada.")
		return
		
	var nuevo_enemigo = enemigo_escena.instantiate()
	
	# Asigna la posición de spawn
	if spawn_punto:
		nuevo_enemigo.global_transform.origin = spawn_punto.global_transform.origin
	else:
		print("ADVERTENCIA: Punto de spawn no asignado. Spawneando en (0,0,0).")
		
	# Añade el nuevo enemigo a la escena (quizás como hijo del GameManager o de otro nodo de juego)
	get_parent().add_child(nuevo_enemigo)
