extends Node2D

func _ready() -> void:
	$Fuego1.play()
	$Fuego2.play()
	$Fuego3.play()

func abrir() -> void:
	queue_free()
