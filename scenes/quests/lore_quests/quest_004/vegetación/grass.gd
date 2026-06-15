extends Node2D

var tiempo := randf() * 10.0
var fuerza := randf_range(0.003, 0.012)
var velocidad := randf_range(0.8, 1.4)

func _ready() -> void:
	
	var escala := randf_range(0.95, 1.05)
	scale = Vector2(escala, escala)

func _process(delta: float) -> void:
	tiempo += delta
	rotation = sin(tiempo * velocidad) * fuerza
