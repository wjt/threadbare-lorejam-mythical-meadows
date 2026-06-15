extends Node2D

var tiempo := randf() * 10.0

func _process(delta: float) -> void:
	tiempo += delta
	rotation = sin(tiempo * 1.8) * 0.08
