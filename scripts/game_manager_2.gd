# GameManager.gd
extends Node

@export_category("Tiempo")
# --- Exportar variables de Tiempo ---
@export var tiempo_dia: float = 300.0 # Duración del DÍA en segundos
@export var tiempo_noche: float = 180.0 # Duración de la NOCHE en segundos
@export var SpriteCielo: Sprite2D

# --- Referencias a los Nodos Spawner ---
# Asegúrate de conectar estos nodos en el Inspector o en _ready()
@export_category("Aliados")
@export var allied_spawner :Node # = $AlliedSpawner
@export var base_aliada : PackedScene
@export var muralla_aliada : PackedScene
#-- variables de configuracion
@export_group("Escenas")
@export var aliado_1_escena: PackedScene
@export var cant_Aliado_1_dia :float =1
@export var aliado_2_escena: PackedScene
@export var cant_Aliado_2_dia :float =1
@export_category("Enemigos")
@export var enemy_spawner :Node # = $EnemySpawner
@export var base_enemiga : Base_Enemiga
@export var muralla_enemiga : Muralla_Enemiga
@export_group("Escenas")
@export var enemigo_1_escena: PackedScene
@export var cant_Enemigo_1_noche :float =1
@export var enemigo_2_escena: PackedScene
@export var cant_Enemigo_2_noche :float =1
@export var enemigo_3_escena: PackedScene
@export var cant_Enemigo_3_noche :float =1



@export_category("Unidades")
# --- Referencias a Escenas de Unidades ---



# --- Variables de Estado ---
var es_de_noche: bool = false
var ciclo_actual: int = 1 # Para controlar la progresión de la dificultad/cantidad
var tiempo_restante: float = 0.0



func _ready():
	tiempo_restante = tiempo_dia
	es_de_noche = false
	# Inicializamos el ciclo
	#iniciar_dia()

func _process(delta):
	tiempo_restante -= delta

	if !Global.paused:
		if tiempo_restante <= 0:
			if es_de_noche:
				# Transición: NOCHE -> DÍA
				ciclo_actual += 1 # Preparamos la progresión
				Global.change_time("Dia")
				Global.change_cycle(ciclo_actual)
				iniciar_dia()

			else:
			# Transición: DÍA -> NOCHE
				Global.change_time("Noche")
				iniciar_noche()
				
			#base_enemiga.health += 10
			#muralla_enemiga.health += 10


# --- Funciones de Transición de Ciclo ---

func iniciar_dia():
	es_de_noche = false
	tiempo_restante = tiempo_dia
	print("Transición a DÍA ☀️ - Ciclo #%d" % ciclo_actual)
	
	# 1. Detener el spawn de Enemigos
	enemy_spawner.detener_spawn()
	
	# 2. Iniciar el spawn de Aliados (ej: 5 aliados base + 2 por ciclo)
	#var aliados_a_spawnear = cantidad_base_aliados + (ciclo_actual - 1) * cantidad_incremento_aliados
	#allied_spawner.iniciar_spawn(aliados_a_spawnear)
	# Llama a la nueva función para obtener la lista de aliados
	var lista_aliados = generar_oleada_aliados(ciclo_actual)
	allied_spawner.iniciar_spawn(lista_aliados, 0.75) # Intervalo más rápido (0.75s)

func iniciar_noche():
	es_de_noche = true
	tiempo_restante = tiempo_noche
	print("Transición a NOCHE 🌑 - Ciclo #%d" % ciclo_actual)
	
	
	
	# 1. Detener el spawn de Aliados
	allied_spawner.detener_spawn()
	
	# 2. Iniciar el spawn de Enemigos (ej: 10 enemigos base + 5 por ciclo)
	#var enemigos_a_spawnear = cantidad_base_enemigos + (ciclo_actual - 1) * cantidad_incremento_enemigos
	#enemy_spawner.iniciar_spawn(enemigos_a_spawnear)
	
	# Llama a la nueva función para obtener la lista de enemigos
	var lista_enemigos = generar_oleada_enemigos(ciclo_actual)
	enemy_spawner.iniciar_spawn(lista_enemigos, 1.2) # Intervalo más lento (1.2s)
	


# --- Lógica de Composición de la Oleada ---
func generar_oleada_enemigos(noche: int) -> Array:
	var lista_oleada: Array = []
	
	# Ejemplo de progresión:
	# Noche 1: 5 básicos, 0 tanques
	# Noche 2: 7 básicos, 1 tanque
	# Noche 5: 15 básicos, 3 tanques

	var num_Enemigo_1: int = (noche * cant_Enemigo_1_noche)
	var num_Enemigo_2: int = (noche * cant_Enemigo_2_noche) # Un tanque cada dos noches
	var num_Enemigo_3: int = (noche * cant_Enemigo_3_noche)
	
	# Rellenar la lista con enemigos básicos
	for i in range(num_Enemigo_1):
		lista_oleada.append(enemigo_1_escena)
		
	# Rellenar la lista con enemigos tanque
	for i in range(num_Enemigo_2):
		lista_oleada.append(enemigo_2_escena)
		
	for i in range(num_Enemigo_3):
		lista_oleada.append(enemigo_3_escena)
		
	# Opcional: Mezclar la lista para que no salgan todos los básicos primero
	#lista_oleada.shuffle()
	
	return lista_oleada

func generar_oleada_aliados(dia: int) -> Array:
	var lista_oleada: Array = []
	
	# Generación más dinámica: más guerreros al inicio, más arqueros después
	var num_Aliado_1: int = dia * cant_Aliado_1_dia
	var num_Aliado_2: int = dia * cant_Aliado_2_dia
	
	# Rellenar la lista con unidades
	for i in range(num_Aliado_1):
		lista_oleada.append(aliado_1_escena)
		
	for i in range(num_Aliado_2):
		lista_oleada.append(aliado_2_escena)
		
	#lista_oleada.shuffle()
	
	return lista_oleada
