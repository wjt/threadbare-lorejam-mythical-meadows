extends Node2D

@onready var static_body: StaticBody2D = $StaticBody2D
@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _ready() -> void:
	for child in get_children():
		if child is AnimatedSprite2D:
			child.play()

func open() -> void:
	visible = false
	collision.set_deferred("disabled", true)
	static_body.set_collision_layer_value(1, false)
	static_body.set_collision_mask_value(1, false)
	print("Puerta abierta")
