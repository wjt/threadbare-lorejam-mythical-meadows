extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var _posicion_anterior: Vector2

func _ready() -> void:
	_posicion_anterior = global_position
	
	animated_sprite_2d.play("walk")

func _physics_process(_delta: float) -> void:
	# Medimos la distancia real recorrida
	var distancia_recorrida: float = global_position.distance_to(_posicion_anterior)
	
	if distancia_recorrida > 0.1:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("idle")
		
	# Actualizamos la posición para el siguiente fotograma
	_posicion_anterior = global_position
