extends Node2D

@export var move_speed: float = 20.0
@export var walk_distance: float = 35.0

@export var min_idle_time: float = 0.8
@export var max_idle_time: float = 2.5
@export var min_walk_time: float = 0.6
@export var max_walk_time: float = 1.8

@export var bob_height: float = 2.0
@export var bob_speed: float = 4.0
@export var wiggle_rotation: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D

var start_position: Vector2
var direction: int = 1
var timer: float = 0.0
var is_walking: bool = false
var anim_time: float = 0.0


func _ready() -> void:
	randomize()
	start_position = global_position
	_choose_random_state()


func _process(delta: float) -> void:
	anim_time += delta
	timer -= delta

	_simulate_animation()

	if timer <= 0:
		_choose_random_state()

	if is_walking:
		global_position.x += direction * move_speed * delta

	if abs(global_position.x - start_position.x) >= walk_distance:
		direction *= -1
		sprite.flip_h = direction < 0


func _choose_random_state() -> void:
	is_walking = randf() < 0.6

	if is_walking:
		direction = [-1, 1].pick_random()
		sprite.flip_h = direction < 0
		timer = randf_range(min_walk_time, max_walk_time)
	else:
		timer = randf_range(min_idle_time, max_idle_time)


func _simulate_animation() -> void:
	sprite.position.y = sin(anim_time * bob_speed) * bob_height

	if is_walking:
		sprite.rotation_degrees = sin(anim_time * bob_speed) * wiggle_rotation
	else:
		sprite.rotation_degrees = sin(anim_time * 2.0) * 1.0
