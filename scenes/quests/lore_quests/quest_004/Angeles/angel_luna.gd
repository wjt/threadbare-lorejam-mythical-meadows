extends Node2D

@export var dialogue: DialogueResource
@export var title: String = "start"

@export var float_speed: float = 2.0
@export var float_height: float = 8.0

@export_file("*.tscn") var next_level: String
@export var change_level_after_dialogue: bool = true

@export var use_transition: bool = true
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
@export var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE

var start_y: float
var time_passed: float = 0.0

var player_inside: Node2D = null
var talking: bool = false

@onready var area: Area2D = $InteractArea
@onready var label: Label = $InteractLabel


func _ready() -> void:
	start_y = position.y
	label.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	time_passed += delta
	position.y = start_y + sin(time_passed * float_speed) * float_height

	if player_inside == null:
		return

	if talking:
		return

	if Input.is_action_just_pressed("interact"):
		start_dialogue()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = body
		label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null
		label.visible = false


func start_dialogue() -> void:
	if dialogue == null:
		print("No hay diálogo asignado")
		return

	talking = true
	label.visible = false

	DialogueManager.show_dialogue_balloon(dialogue, title, [self, player_inside])
	await DialogueManager.dialogue_ended

	if change_level_after_dialogue and next_level != "":
		if use_transition:
			SceneSwitcher.change_to_file_with_transition.call_deferred(
				next_level,
				^"",
				enter_transition,
				exit_transition
			)
		else:
			get_tree().call_deferred("change_scene_to_file", next_level)
		return

	talking = false

	if player_inside:
		label.visible = true
