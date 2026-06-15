extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1

var target: Node2D = null


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	
	var direction := global_position.direction_to(target.global_position)
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body == target and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
