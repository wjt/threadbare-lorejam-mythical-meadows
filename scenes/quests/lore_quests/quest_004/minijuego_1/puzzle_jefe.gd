extends Node2D

@onready var cliff = $"../TileMapLayers/Cliffs"

var detecto_golem := false

func _process(_delta):

	var golems = get_tree().get_nodes_in_group("golem")

	if not detecto_golem and golems.size() > 0:
		detecto_golem = true

	if detecto_golem and golems.is_empty():

		cliff.queue_free()
		queue_free()
