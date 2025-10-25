# GameManager.gd
extends Node

@export_category("Tiempo")
# --- Exportar variables de Tiempo ---
@export var tiempo_dia: float = 300.0 # Duración del DÍA en segundos
@export var tiempo_noche: float = 180.0 # Duración de la NOCHE en segundos

# --- Referencias a los Nodos Spawner ---
# Asegúrate de conectar estos nodos en el Inspector o en _ready()
@export_category("Aliados")
@export var allied_spawner :Node # = $AlliedSpawner
#-- variables de configuracion
@export var cantidad_base_aliados :int =1
@export var cantidad_incremento_aliados :int =1
@export_category("Enemigos")
@export var enemy_spawner :Node # = $EnemySpawner
@export var cantidad_base_enemigos :int =1
@export var cantidad_incremento_enemigos :int =1



# --- Variables de Estado ---
var es_de_noche: bool = false
var ciclo_actual: int = 1 # Para controlar la progresión de la dificultad/cantidad
var tiempo_restante: float = 0.0



func _ready():
	tiempo_restante = tiempo_dia
	es_de_noche = false
	# Inicializamos el ciclo
	iniciar_dia()

func _process(delta):
	tiempo_restante -= delta

	if tiempo_restante <= 0:
		if es_de_noche:
			# Transición: NOCHE -> DÍA
			ciclo_actual += 1 # Preparamos la progresión
			iniciar_dia()
		else:
			# Transición: DÍA -> NOCHE
			iniciar_noche()

# --- Funciones de Transición de Ciclo ---

func iniciar_dia():
	es_de_noche = false
	tiempo_restante = tiempo_dia
	print("Transición a DÍA ☀️ - Ciclo #%d" % ciclo_actual)
	
	# 1. Detener el spawn de Enemigos
	enemy_spawner.detener_spawn()
	
	# 2. Iniciar el spawn de Aliados (ej: 5 aliados base + 2 por ciclo)
	var aliados_a_spawnear = cantidad_base_aliados + (ciclo_actual - 1) * cantidad_incremento_aliados
	allied_spawner.iniciar_spawn(aliados_a_spawnear)
	

func iniciar_noche():
	es_de_noche = true
	tiempo_restante = tiempo_noche
	print("Transición a NOCHE 🌑 - Ciclo #%d" % ciclo_actual)
	
	# 1. Detener el spawn de Aliados
	allied_spawner.detener_spawn()
	
	# 2. Iniciar el spawn de Enemigos (ej: 10 enemigos base + 5 por ciclo)
	var enemigos_a_spawnear = cantidad_base_enemigos + (ciclo_actual - 1) * cantidad_incremento_enemigos
	enemy_spawner.iniciar_spawn(enemigos_a_spawnear)
