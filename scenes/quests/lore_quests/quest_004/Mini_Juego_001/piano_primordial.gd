extends Area2D

@export var dialogue: DialogueResource
@export var title: String = "start"
@export var required_group: String = "player"

@export var idle_animation: String = "Idle"
@export var collect_animation: String = ""

@export var collect_sound: AudioStream

@export_file("*.tscn") var next_level: String
@export var change_level_after_dialogue: bool = true

@export var use_transition: bool = true
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
@export var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE

var collected: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if sprite.sprite_frames and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)

	if collect_sound:
		audio.stream = collect_sound


func _on_body_entered(body: Node) -> void:
	if collected:
		return

	if not body.is_in_group(required_group):
		return

	collected = true
	collision.set_deferred("disabled", true)
	
	if body.has_method("take_control"):
		body.take_control(self)
	var sprite = body.get_node_or_null("%PlayerSprite")
	if sprite:
		sprite.play("idle")

	if collect_sound:
		audio.play()

	if collect_animation != "":
		sprite.play(collect_animation)

	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, title, [self, body])
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

	queue_free()
