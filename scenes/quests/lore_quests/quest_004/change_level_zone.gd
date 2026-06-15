extends Area2D

@export_file("*.tscn") var next_level: String
@export var required_group: String = "player"
@export var delay_before_change: float = 0.15

@export var use_transition: bool = true
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
@export var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE

var changing_scene: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if changing_scene:
		return

	if not body.is_in_group(required_group):
		return

	if next_level == "":
		push_warning("No hay nivel asignado en el Inspector.")
		return

	changing_scene = true

	await get_tree().create_timer(delay_before_change).timeout

	if use_transition:
		SceneSwitcher.change_to_file_with_transition.call_deferred(
			next_level,
			^"",
			enter_transition,
			exit_transition
		)
	else:
		get_tree().change_scene_to_file(next_level)
