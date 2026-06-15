extends CharacterBody2D

@export var speed: float = 80.0
@export var flee_sound: AudioStream
@export var return_after_flee: bool = true
@export var return_speed: float = 50.0
@export var fake_walk_enabled: bool = true
@export var fake_walk_rotation: float = 4.0
@export var fake_walk_speed: float = 10.0

var walk_time: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var end_point: Marker2D = $EndPoint

var fleeing: bool = false
var returning: bool = false
var start_position: Vector2
var end_position: Vector2


func _ready() -> void:
	start_position = global_position
	end_position = end_point.global_position

	if flee_sound:
		audio.stream = flee_sound

	area.body_entered.connect(_on_body_entered)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if fleeing:
		move_to_point(end_position, speed)

		if global_position.distance_to(end_position) < 8:
			fleeing = false
			velocity = Vector2.ZERO
			sprite.rotation_degrees = 0
			sprite.play("idle")

			if return_after_flee:
				await get_tree().create_timer(1.0).timeout
				returning = true

	elif returning:
		move_to_point(start_position, return_speed)

		if global_position.distance_to(start_position) < 8:
			returning = false
			velocity = Vector2.ZERO
			sprite.rotation_degrees = 0
			sprite.play("idle")


func move_to_point(target_position: Vector2, move_speed: float) -> void:
	var direction: Vector2 = global_position.direction_to(target_position)
	velocity = direction * move_speed
	move_and_slide()
	sprite.play("walk")
	if fake_walk_enabled:
		walk_time += get_physics_process_delta_time() * fake_walk_speed
		sprite.rotation_degrees = sin(walk_time) * fake_walk_rotation

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not fleeing and not returning:
		fleeing = true

		if audio.stream:
			audio.play()
