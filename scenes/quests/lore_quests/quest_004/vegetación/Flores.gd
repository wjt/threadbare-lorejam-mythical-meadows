extends Node2D

var tiempo := randf() * 10.0
var fuerza := randf_range(0.02, 0.05)
var velocidad := randf_range(2.0, 4.0)

func _ready() -> void:
	
	var escala := randf_range(0.95, 1.05)
	scale = Vector2(escala, escala)

func _process(delta: float) -> void:
	tiempo += delta
	rotation = sin(tiempo * velocidad) * fuerza
