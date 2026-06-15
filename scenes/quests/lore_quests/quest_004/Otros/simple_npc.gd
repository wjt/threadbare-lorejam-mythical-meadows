extends Node2D

@export var npc_name: String = "NPC"

@export_multiline var dialogue_text: String = """

Hola viajero.
Bienvenido a la aldea.
Ten cuidado más adelante.
"""

@export var sprite_frames: SpriteFrames
@export var talk_sound: AudioStream

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label

var player_near: bool = false
var dialogue_lines: PackedStringArray
var dialogue_index: int = 0
var talking: bool = false


func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false

	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames

	if talk_sound:
		audio.stream = talk_sound

	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

	dialogue_lines = dialogue_text.split("\n", false)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("ui_accept"):
		show_next_dialogue()


func show_next_dialogue() -> void:
	if dialogue_lines.is_empty():
		return

	if dialogue_index >= dialogue_lines.size():
		close_dialogue()
		return

	get_tree().paused = true
	talking = true
	panel.visible = true

	var line := dialogue_lines[dialogue_index].strip_edges()
	label.text = npc_name + ": " + line

	if audio.stream:
		audio.play()

	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("talk"):
		animated_sprite.play("talk")

	dialogue_index += 1


func close_dialogue() -> void:
	panel.visible = false
	talking = false
	dialogue_index = 0
	get_tree().paused = false

	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_near = true


func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_near = false
		close_dialogue()
