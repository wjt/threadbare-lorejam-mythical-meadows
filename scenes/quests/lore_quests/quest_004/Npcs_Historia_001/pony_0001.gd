extends Node2D

@export var dialogue: DialogueResource
@export var title: String = "start"
@export var restart_delay: float = 0.5

@export_file("*.tscn") var next_level: String
@export var change_level_after_dialogue: bool = true

@export var use_transition: bool = true
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
@export var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE

var player_inside: Node2D = null
var talking: bool = false
var can_talk: bool = true

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var area: Area2D = $InteractArea
@onready var label: Label = $InteractLabel


func _ready() -> void:
	sprite.play("Idle")
	label.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside == null:
		return

	if talking:
		return

	if not can_talk:
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
		can_talk = true


func start_dialogue() -> void:
	if dialogue == null:
		print("No hay diálogo asignado")
		return

	talking = true
	can_talk = false
	label.visible = false

	DialogueManager.show_dialogue_balloon(
		dialogue,
		title,
		[self, player_inside]
	)

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

	await get_tree().create_timer(restart_delay).timeout

	if player_inside != null:
		label.visible = true

	can_talk = true
