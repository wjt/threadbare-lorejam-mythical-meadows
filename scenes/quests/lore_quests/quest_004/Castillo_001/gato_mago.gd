extends Node2D

@export var altura: float = 6.0
@export var velocidad: float = 2.0

var posicion_inicial: Vector2
var tiempo: float = 0.0

func _ready() -> void:
	posicion_inicial = position

func _process(delta: float) -> void:
	tiempo += delta
	position.y = posicion_inicial.y + sin(tiempo * velocidad) * altura
