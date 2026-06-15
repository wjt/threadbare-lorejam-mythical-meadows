extends Node

@export var dialogue: DialogueResource
@export var title: String = "start"

@export_file("*.tscn") var next_level: String

@export var use_transition: bool = true
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
@export var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE


func _ready() -> void:
	await get_tree().create_timer(0.5).timeout

	DialogueManager.show_dialogue_balloon(dialogue, title, [self])
	await DialogueManager.dialogue_ended

	if next_level != "":
		if use_transition:
			SceneSwitcher.change_to_file_with_transition.call_deferred(
				next_level,
				^"",
				enter_transition,
				exit_transition
			)
		else:
			get_tree().call_deferred("change_scene_to_file", next_level)
