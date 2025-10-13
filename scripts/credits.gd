extends Node2D

@onready var button: Button = $CanvasLayer/Button

func _ready() -> void:
	get_tree().paused = false
	
	if has_node("CanvasLayer2/TransitionControl"):
		var transition = $CanvasLayer2/TransitionControl
		transition.visible = true
		var anim_player = transition.get_node("AnimationPlayer")
		anim_player.play("screen_transition")
		await anim_player.animation_finished
		transition.visible = false

func _on_button_pressed() -> void:
	$CanvasLayer2/TransitionControl.visible = true
	$CanvasLayer2/TransitionControl/AnimationPlayer.play_backwards("screen_transition")
	await $CanvasLayer2/TransitionControl/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	$CanvasLayer2/TransitionControl.visible = false
