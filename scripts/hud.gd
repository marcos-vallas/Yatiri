extends Control

@onready var coins_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Coins
@onready var potions_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/Potions
#@onready var tribe_label: Label = $MarginContainer/HBoxContainer2/TribuNumber
@onready var tribe_label: Label = $MarginContainer/VBoxContainer2/TribuContainer/TribuNumber
@onready var base_health_bar: ProgressBar = $MarginContainer/VBoxContainer2/BaseContainer/BaseHealthBar


func _ready() -> void:
	# Conectar señales del Global
	Global.coins_changed.connect(_on_coins_changed)
	Global.potions_changed.connect(_on_potions_changed)
	Global.tribe_changed.connect(_on_tribe_changed)
	Global.base_health_changed.connect(_on_base_health_changed)

	# Inicializar visuales
	_on_coins_changed(Global.coins)
	_on_potions_changed(Global.potions)
	_on_tribe_changed(Global.tribe_count)
	_on_base_health_changed(Global.base_health)
	
		# Configurar barra
	base_health_bar.max_value = Global.base_max_health
	
func _on_base_health_changed(new_value: int) -> void:
	base_health_bar.value = new_value
	
func _on_coins_changed(new_value: int) -> void:
	coins_label.text = str(new_value).pad_zeros(2)

func _on_potions_changed(new_value: int) -> void:
	potions_label.text = str(new_value).pad_zeros(2)

func _on_tribe_changed(new_value: int) -> void:
	tribe_label.text = str(new_value).pad_zeros(2)
