class_name CarryableAnimal
extends Node2D

@export var interact_area: InteractArea
@export var carry_offset := Vector2(0, -24)

var carried := false
var carrier: Node2D = null


func _ready() -> void:

	if interact_area:
		interact_area.interaction_started.connect(
			_on_interaction_started
		)


func _process(_delta: float) -> void:

	if carried and carrier:
		global_position = carrier.global_position + carry_offset


func _on_interaction_started(player, _from_right) -> void:

	if carried:
		_drop()
	else:
		_pickup(player)

	interact_area.end_interaction()


func _pickup(player) -> void:

	carried = true
	carrier = player


func _drop() -> void:

	carried = false
	carrier = null
