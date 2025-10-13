extends Control

func _ready() -> void:
	get_tree().paused = false
	$CanvasLayer/TransitionControl.visible = true	
	$CanvasLayer/TransitionControl/AnimationPlayer.play("screen_transition")
	await $CanvasLayer/TransitionControl/AnimationPlayer.animation_finished
	$CanvasLayer/TransitionControl.visible = false

func _on_play_button_pressed() -> void:
	$CanvasLayer/TransitionControl.visible = true
	$CanvasLayer/TransitionControl/AnimationPlayer.play_backwards("screen_transition")
	await $CanvasLayer/TransitionControl/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	$CanvasLayer/TransitionControl.visible = false


func _on_credits_button_pressed() -> void:
	$CanvasLayer/TransitionControl.visible = true
	$CanvasLayer/TransitionControl/AnimationPlayer.play_backwards("screen_transition")
	await $CanvasLayer/TransitionControl/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
	$CanvasLayer/TransitionControl.visible = false



func _on_quit_button_pressed() -> void:
	$CanvasLayer/TransitionControl.visible = true
	$CanvasLayer/TransitionControl/AnimationPlayer.play_backwards("screen_transition")
	await $CanvasLayer/TransitionControl/AnimationPlayer.animation_finished
	get_tree().quit()
