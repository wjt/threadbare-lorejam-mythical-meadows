# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cinematic
extends Node2D
## Shows a dialogue, then transitions to another scene.
##
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest.
## It can also be used as an easy way to display dialogue at the beginning of a level.

## Emitted when the cinematic has finished. Use it if not passing [member next_scene]
## when you need to do something else after the cinematic.
signal cinematic_finished

## Dialogue for cinematic scene.
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")

## Optional animation player, to be used from [member dialogue] (if needed).
@export var animation_player: AnimationPlayer

## Optional scene to switch to once [member dialogue] is complete.
@export_file("*.tscn") var next_scene: String

## Optional path inside [member next_scene] where the player should appear.
## If blank, player appears at default position in the scene. If in doubt,
## leave this blank.
@export var spawn_point_path: String

## Wether to automatically start the cinematic.
@export var autostart: bool = true


func _ready() -> void:
	if autostart:
		start()


func start() -> void:
	if not GameState.intro_dialogue_shown:
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
		cinematic_finished.emit()
		GameState.intro_dialogue_shown = true

	if next_scene:
		(
			SceneSwitcher
			. change_to_file_with_transition(
				next_scene,
				spawn_point_path,
				Transition.Effect.FADE,
				Transition.Effect.FADE,
			)
		)

func play_fog_and_go_to_credits() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)

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

	# La niebla cubre toda la pantalla suavemente
	tween.tween_property(
		fog,
		"color",
		Color(0.78, 0.82, 0.82, 1.0),
		3.5
	)

	# Se queda nublado un momento antes de ir a créditos
	tween.tween_interval(1.0)

	await tween.finished

	get_tree().change_scene_to_file("res://scenes/quests/lore_quests/quest_004/3_Outro/credits.tscn")
