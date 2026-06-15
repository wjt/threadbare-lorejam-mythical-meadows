extends Node2D

@export var float_height: float = 5.0
@export var float_speed: float = 2.0

var start_position: Vector2
var time: float = 0.0


func _ready() -> void:
	start_position = position


func _process(delta: float) -> void:
	time += delta * float_speed
	position.y = start_position.y + sin(time) * float_height
