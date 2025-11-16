extends Node
class_name Quest
	
	
@export_group('Quest Settings')
@export var quest_name: String
@export var quest_desc: String
@export var completed_text : String

enum QuestStatus {
	disponible,
	iniciado,
	completado,
	finalizado
}

@export var quest_status : QuestStatus = QuestStatus.disponible

@export_group('Recompensas')
@export var reward_monedas:int=0
@export var reward_pociones:int=0

func _ready() -> void:
	pass
	
func iniciar_quest()->void:
	if quest_status == QuestStatus.disponible:
		quest_status = QuestStatus.iniciado
		Global.show_quest(true)
		Global.update_quest(quest_name,quest_desc)
			
func objetivo_completado()->void:
	if quest_status == QuestStatus.iniciado:
		quest_status = QuestStatus.completado
		Global.update_quest(quest_name,completed_text)
	pass

func finalizar_quest() -> void:
	if quest_status == QuestStatus.completado:
		quest_status = QuestStatus.finalizado
		Global.show_quest(false)
		Global.add_coins(reward_monedas)
		Global.add_potions(reward_pociones)
	pass
