extends Area2D

@export var speed: float = 350.0
@export var damage: float = 25.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
