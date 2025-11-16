extends Control

#class_name HUDcito

@onready var QuestBox: CanvasLayer = $QuestBox
@onready var QuestTitle: RichTextLabel = $QuestBox/QuestTitle
@onready var QuestDesc: RichTextLabel = $QuestBox/QuestDescription


@onready var coins_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Coins
@onready var potions_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/Potions
#@onready var tribe_label: Label = $MarginContainer/HBoxContainer2/TribuNumber
@onready var tribe_label: Label = $MarginContainer/VBoxContainer2/TribuContainer/TribuNumber
@onready var base_health_bar: ProgressBar = $MarginContainer/VBoxContainer2/BaseContainer/BaseHealthBar

@onready var actual_cycle_marker : Label = $MarginContainer/DayLabel

@onready var tiempo :String = "Dia "

func _ready() -> void:
	# Conectar señales del Global
	Global.coins_changed.connect(_on_coins_changed)
	Global.potions_changed.connect(_on_potions_changed)
	Global.tribe_changed.connect(_on_tribe_changed)
	Global.base_health_changed.connect(_on_base_health_changed)
	Global.cycle_changed.connect(_on_cicle_changed)
	Global.time_changed.connect(_on_time_changed)
	
	Global.quest_update.connect(_on_quest_update)
	Global.quest_visible.connect(_on_quest_visible)

	# Inicializar visuales
	_on_coins_changed(Global.coins)
	_on_potions_changed(Global.potions)
	_on_tribe_changed(Global.tribe_count)
	_on_base_health_changed(Global.base_health)
	
	_on_time_changed(Global.tiempo_actual)
	_on_cicle_changed(Global.ciclo_actual)


		# Configurar barra
	base_health_bar.max_value = Global.base_max_health
	
func _on_time_changed(time :String) -> void:
	tiempo = time
	
func _on_cicle_changed(new_value :int) -> void:
	actual_cycle_marker.text = "Dia " + str(new_value)
		
func es_par(numero: int) -> bool:
	return numero % 2 == 0
	
func _on_base_health_changed(new_value: int) -> void:
	base_health_bar.value = new_value
	
func _on_coins_changed(new_value: int) -> void:
	coins_label.text = str(new_value).pad_zeros(2)

func _on_potions_changed(new_value: int) -> void:
	potions_label.text = str(new_value).pad_zeros(2)

func _on_tribe_changed(new_value: int) -> void:
	tribe_label.text = str(new_value).pad_zeros(2)
	
func _process(delta: float) -> void:
	tribe_label.text = str(Global.tribe_count) #.pad_zeros(2)

func _on_quest_update(title,desc):
	QuestTitle.text = title
	QuestDesc.text = desc
	pass
func _on_quest_visible(value):
	if value:
		QuestBox.visible = true
	else :
		QuestBox.visible = false
	pass
