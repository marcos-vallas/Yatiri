extends Node
# BaseSpawner.gd

# ... (Mantén las variables: unidad_escena, spawn_marker, spawn_timer) ...
# --- Exportar variables de Spawner ---
#@export var unidad_escena: PackedScene # Escena de la unidad a spawnear
@export var spawn_marker: Node2D # El nodo Marker2D (o similar) para la posición

# --- Nodos Auxiliares ---
@export var spawn_timer: Timer #= $SpawnTimer # Asegúrate de tener un Timer llamado "SpawnTimer" como hijo

# --- Variables de Estado de Spawn ---
var unidades_a_spawnear: int = 0
var unidades_spawneadas: int = 0
var intervalo_spawn: float = 1.0 # El intervalo base por defecto

# NO necesitamos 'unidad_escena' aquí, la recibiremos en la función iniciar_spawn

# --- Variables de Estado de Spawn ---
var unidades_a_spawnear_lista: Array = [] # Nuevo: Almacenará las PackedScene de la oleada
var indice_spawn_actual: int = 0


func _ready():
	spawn_timer.autostart = false
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", _on_SpawnTimer_timeout)

# --- Control de Spawn (Función modificada) ---

# Ahora, recibe una lista (Array) de escenas a spawnear
func iniciar_spawn(lista_unidades: Array, intervalo: float = 1.0):
	unidades_a_spawnear_lista = lista_unidades
	indice_spawn_actual = 0
	intervalo_spawn = intervalo
	
	# Si la lista está vacía, no hacemos nada
	if unidades_a_spawnear_lista.is_empty():
		print("ADVERTENCIA: Lista de unidades a spawnear vacía.")
		return
	
	# Configurar y comenzar el Timer
	spawn_timer.wait_time = intervalo_spawn
	spawn_timer.start()
	print("Iniciando spawn. Total de unidades: %d" % unidades_a_spawnear_lista.size())

func detener_spawn():
	spawn_timer.stop()
	unidades_a_spawnear_lista.clear()
	indice_spawn_actual = 0
	print("Spawn detenido.")

# --- Lógica de Spawn (Función modificada) ---

func _on_SpawnTimer_timeout():
	# Comprobamos si hemos spawneado todas las unidades de la lista
	if indice_spawn_actual < unidades_a_spawnear_lista.size():
		# Pasamos la escena específica a la función spawn_unidad
		var escena_a_spawnear = unidades_a_spawnear_lista[indice_spawn_actual]
		spawn_unidad(escena_a_spawnear)
		
		indice_spawn_actual += 1
		
		# Si se completó el spawn, detener el Timer
		if indice_spawn_actual == unidades_a_spawnear_lista.size():
			spawn_timer.stop()
			print("Spawn completado.")

# --- Función para instanciar y añadir la unidad (Función modificada) ---
# Ahora recibe la escena como argumento
func spawn_unidad(escena: PackedScene):
	if not escena:
		print("ERROR: La escena es nula.")
		return
		
	var nueva_unidad = escena.instantiate()
	
	# Asigna la posición de spawn (utilizando global_position o global_transform.origin)
	if spawn_marker:
		#if nueva_unidad is Node2D:
			nueva_unidad.global_position = spawn_marker.global_position
		#elif nueva_unidad is Node3D:
			#nueva_unidad.global_transform.origin = spawn_marker.global_transform.origin
	
	# Añade la unidad a la escena principal
	get_parent().get_parent().add_child(nueva_unidad)
