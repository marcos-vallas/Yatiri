extends Node2D

func _ready() -> void:
	$CanvasLayer/TransitionControl.visible = true	
	$CanvasLayer/TransitionControl/AnimationPlayer.play("screen_transition")
	await $CanvasLayer/TransitionControl/AnimationPlayer.animation_finished
	await get_tree().create_timer(2.0).timeout
	$CanvasLayer/TransitionControl/AnimationPlayer.play_backwards("screen_transition")
	await $CanvasLayer/TransitionControl/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	$CanvasLayer/TransitionControl.visible = false
