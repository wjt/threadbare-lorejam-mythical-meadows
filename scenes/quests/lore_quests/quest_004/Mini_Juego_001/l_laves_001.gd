extends Area2D

@export var manager: Node

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		manager.recoger_llave()
		queue_free()
