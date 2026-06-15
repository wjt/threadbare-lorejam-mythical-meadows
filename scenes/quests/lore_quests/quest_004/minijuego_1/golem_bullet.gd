extends Node2D

@export var speed := 250.0

var direction := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _process(delta: float) -> void:

	global_position += direction * speed * delta




func _on_visible_on_screen_notifier_2d_screen_exited() -> void:

	queue_free()





func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):

		if body.has_method("defeat"):
			body.defeat()

		queue_free()
