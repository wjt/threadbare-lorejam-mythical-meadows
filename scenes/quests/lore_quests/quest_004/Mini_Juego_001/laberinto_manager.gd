extends Node

var llaves: int = 0

@export var puerta_1: Node
@export var puerta_2: Node
@export var puerta_3: Node

func recoger_llave() -> void:
	llaves += 1
	print("Llaves:", llaves)

	if llaves >= 1 and puerta_1:
		puerta_1.queue_free()

	if llaves >= 2 and puerta_2:
		puerta_2.queue_free()

	if llaves >= 3 and puerta_3:
		puerta_3.queue_free()
