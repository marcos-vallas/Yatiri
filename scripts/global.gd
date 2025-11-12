extends Node

var coins: int = 15
var potions: int = 15
var tribe_count: int = 0   
var base_health: int = 40
var base_max_health: int = 100
var game_result_text = ""

var ciclo_actual : int =1 
var tiempo_actual : String = "Dia "


signal coins_changed(new_value)
signal potions_changed(new_value)
signal tribe_changed(new_value)
signal base_health_changed(new_value)  # 🔥 Nueva señal

signal cycle_changed(new_value)
signal time_changed(new_value)


func change_cycle(ciclo:int) -> void:
	ciclo_actual = ciclo
	emit_signal("cycle_changed", ciclo_actual)

func change_time(time) -> void:
	tiempo_actual = time
	print(tiempo_actual)
	emit_signal("time_changed", tiempo_actual)

# --- MONEDAS ---
func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)

func remove_coins(amount: int) -> void:
	coins = max(0, coins - amount)
	emit_signal("coins_changed", coins)

func set_coins(value: int) -> void:
	coins = max(0, value)
	emit_signal("coins_changed", coins)

# --- POCIONES ---
func add_potions(amount: int) -> void:
	potions += amount
	emit_signal("potions_changed", potions)

func remove_potions(amount: int) -> void:
	potions = max(0, potions - amount)
	emit_signal("potions_changed", potions)

func set_potions(value: int) -> void:
	potions = max(0, value)
	emit_signal("potions_changed", potions)

# --- TRIBU ---
func add_tribe_member(cant:int =1) -> void:
	tribe_count += cant
	emit_signal("tribe_changed", tribe_count)

func remove_tribe_member() -> void:
	tribe_count = max(0, tribe_count - 1)
	emit_signal("tribe_changed", tribe_count)

func set_tribe_count(value: int) -> void:
	tribe_count = max(0, value)
	emit_signal("tribe_changed", tribe_count)

# --- BASE ---
func damage_base(amount: int) -> void:
	base_health = max(0, base_health - amount)
	emit_signal("base_health_changed", base_health)
	
	if base_health == 0:
		_on_base_destroyed()

func health_base(amount: int) -> void:
	base_health = amount 
	emit_signal("base_health_changed", base_health)
	
func update_base_health() -> void:
	emit_signal("base_health_changed", base_health)

func reset_base_health() -> void:
	base_health = base_max_health
	emit_signal("base_health_changed", base_health)

func _on_base_destroyed() -> void:
	print("💥 Base destruida")
	game_result_text = "¡La base ha caído!"
