extends Node2D

@export var float_speed: float = 2.0
@export var float_height: float = 8.0

var start_y: float
var time_passed: float = 0.0


func _ready() -> void:
	start_y = position.y


func _process(delta: float) -> void:
	time_passed += delta
	position.y = start_y + sin(time_passed * float_speed) * float_height
