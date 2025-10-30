# BaseSpawner.gd
extends Node # Usa Node3D si tu juego es 3D

# --- Exportar variables de Spawner ---
@export var unidad_escena: PackedScene # Escena de la unidad a spawnear
@export var spawn_marker: Node2D # El nodo Marker2D (o similar) para la posición

# --- Nodos Auxiliares ---
@export var spawn_timer: Timer #= $SpawnTimer # Asegúrate de tener un Timer llamado "SpawnTimer" como hijo

# --- Variables de Estado de Spawn ---
var unidades_a_spawnear: int = 0
var unidades_spawneadas: int = 0
var intervalo_spawn: float = 1.0 # El intervalo base por defecto




func _ready():
	spawn_timer.autostart = false
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", _on_SpawnTimer_timeout)

# --- Control de Spawn ---

func iniciar_spawn(cantidad: int, intervalo: float = 1.0):
	unidades_a_spawnear = cantidad
	unidades_spawneadas = 0
	intervalo_spawn = intervalo
	
	# Configurar y comenzar el Timer
	spawn_timer.wait_time = intervalo_spawn
	spawn_timer.start()

func detener_spawn():
	spawn_timer.stop()
	unidades_a_spawnear = 0
	unidades_spawneadas = 0
	print("Spawn detenido.")

# --- Lógica de Spawn ---

func _on_SpawnTimer_timeout():
	if unidades_spawneadas < unidades_a_spawnear:
		spawn_unidad()
		unidades_spawneadas += 1
		
		# Si se completó el spawn, detener el Timer
		if unidades_spawneadas == unidades_a_spawnear:
			spawn_timer.stop()
			print("Spawn completado.")

func spawn_unidad():
	if not unidad_escena:
		print("ERROR: Escena de unidad no asignada.")
		return
		
	var nueva_unidad = unidad_escena.instantiate()
	
	# Asigna la posición de spawn
	if spawn_marker:
		nueva_unidad.global_position = spawn_marker.global_position
	
	# Añade la unidad a la escena. Es mejor añadirla como hermana del GameManager.
	get_parent().get_parent().add_child(nueva_unidad)
