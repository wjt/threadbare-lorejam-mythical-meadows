extends Node

@onready var title_image: TextureRect = $"../CanvasLayer/TitleImage"
@onready var boat: AnimatedSprite2D = $"../OnTheGround/Boat"
@onready var start_point: Marker2D = $"../StartPoint"
@onready var dialogue_point: Marker2D = $"../DialoguePoint"
@onready var exit_point: Marker2D = $"../ExitPoint"

@export var speed: float = 60.0
@export_file("*.tscn") var next_scene: String

var phase: int = 1


func _ready() -> void:
	title_image.visible = false
	boat.global_position = start_point.global_position
	boat.play("move")


func _process(delta: float) -> void:
	if phase == 1:
		boat.global_position = boat.global_position.move_toward(
			dialogue_point.global_position,
			speed * delta
		)

		if boat.global_position.distance_to(dialogue_point.global_position) < 5:
			phase = 2
			show_title_and_wait()

	elif phase == 3:
		boat.global_position = boat.global_position.move_toward(
			exit_point.global_position,
			speed * delta
		)

		if boat.global_position.distance_to(exit_point.global_position) < 5:
			get_tree().change_scene_to_file(next_scene)


func show_title_and_wait() -> void:
	boat.play("idle")
	title_image.visible = true

	await get_tree().create_timer(3.0).timeout

	boat.play("move")
	phase = 3

	await get_tree().create_timer(5.0).timeout

	title_image.visible = false
