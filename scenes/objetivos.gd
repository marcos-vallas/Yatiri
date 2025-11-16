extends Node2D

@export var objetivo_1 : Quest 
@export var objetivo_2 : Quest 
@export var objetivo_3 : Quest 
@export var objetivo_4 : Quest 
@export var objetivo_5 : Quest 
@export var objetivo_6 : Quest 


func _ready() -> void:
	Global.objetivo_cumplido.connect(_on_objetivo_cumplido)
	#objetivo_1.iniciar_quest()
	pass
	
func _on_objetivo_cumplido(numero:int)->void:
	match numero:
		1:
			objetivo_1.objetivo_completado()
			objetivo_1.finalizar_quest()
			objetivo_2.iniciar_quest()
		2:
			objetivo_2.objetivo_completado()
			objetivo_2.finalizar_quest()
			objetivo_3.iniciar_quest()
		3:
			objetivo_3.objetivo_completado()
			objetivo_3.finalizar_quest()
			objetivo_4.iniciar_quest()
		4:
			objetivo_4.objetivo_completado()
			objetivo_4.finalizar_quest()
			objetivo_5.iniciar_quest()
		5:
			objetivo_5.objetivo_completado()
			objetivo_5.finalizar_quest()
			objetivo_6.iniciar_quest()
		6:
			objetivo_5.objetivo_completado()
			objetivo_5.finalizar_quest()
			#objetivo_6.iniciar_quest()
		_:
			pass
	pass
