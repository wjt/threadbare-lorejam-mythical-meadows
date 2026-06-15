extends Node2D

@export var health: int = 2
@export var broken_texture: Texture2D

@export var hit_sound: AudioStream
@export var break_sound: AudioStream

@export var shake_strength: float = 4.0
@export var shake_time: float = 0.08
@export var remove_after_break: float = 0.35

var broken: bool = false
var original_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var hurt_box: Area2D = $Area2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	add_to_group("repellable")
	add_to_group("brekeable") # ojo: escrito igual que en tu proyecto original

	original_position = position
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	print("Caja lista para detectar")


func _on_hurt_box_area_entered(area: Area2D) -> void:
	print("Caja detectó area:", area.name)
	print("Padre:", area.get_parent().name)

	if area.name == "AirStream" or area.get_parent().name == "AirStream":
		take_damage(1)

func take_damage(amount: int = 1) -> void:
	if broken:
		return

	health -= amount
	print("Vida de la caja:", health)

	if health > 0:
		play_sound(hit_sound)
		shake()
	else:
		break_box()


func break_box() -> void:
	broken = true
	print("Caja destruida")

	if broken_texture:
		sprite.texture = broken_texture

	play_sound(break_sound)
	shake()

	if static_body:
		static_body.process_mode = Node.PROCESS_MODE_DISABLED

	if hurt_box:
		hurt_box.set_deferred("monitoring", false)
		hurt_box.set_deferred("monitorable", false)

	await get_tree().create_timer(remove_after_break).timeout
	queue_free()


func shake() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", original_position + Vector2(shake_strength, 0), shake_time)
	tween.tween_property(self, "position", original_position + Vector2(-shake_strength, 0), shake_time)
	tween.tween_property(self, "position", original_position, shake_time)


func play_sound(sound: AudioStream) -> void:
	if sound == null:
		return

	audio.stream = sound
	audio.play()
