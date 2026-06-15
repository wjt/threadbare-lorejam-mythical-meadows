

extends Area2D

@export var damage: float = 20.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# EFECTO VISUAL
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE
		
		# DAÑO
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		
		
