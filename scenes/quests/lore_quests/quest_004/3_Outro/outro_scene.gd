extends Node2D

func go_to_credits() -> void:
	get_tree().change_scene_to_file("res://scenes/quests/lore_quests/quest_004/3_Outro/credits.tscn")

func play_fog_and_go_to_credits() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)

	var fog := ColorRect.new()
	fog.color = Color(0.78, 0.82, 0.82, 0.0)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(fog)

	fog.offset_left = 0
	fog.offset_top = 0
	fog.offset_right = 0
	fog.offset_bottom = 0

	var tween := create_tween()

	tween.tween_property(fog, "color", Color(0.78, 0.82, 0.82, 1.0), 3.5)
	tween.tween_interval(1.0)

	await tween.finished

	get_tree().change_scene_to_file("res://scenes/quests/lore_quests/quest_004/3_Outro/credits.tscn")
