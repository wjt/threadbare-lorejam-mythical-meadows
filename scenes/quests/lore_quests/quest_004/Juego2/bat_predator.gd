#bat_predator

extends CharacterBody2D

var speed: float = 80.0
var attack_cooldown: float = 0.0

func _ready():
	add_to_group("predators")

func _physics_process(delta):
	attack_cooldown -= delta
	
	var target = null
	var min_dist = 999999
	
	for butterfly in get_tree().get_nodes_in_group("butterflies"):
		if not is_instance_valid(butterfly):
			continue
		if not butterfly.has_method("die"):
			continue
		var dist = global_position.distance_to(butterfly.global_position)
		if dist < min_dist:
			min_dist = dist
			target = butterfly
	
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		
		if min_dist < 80 and attack_cooldown <= 0 and is_instance_valid(target):
			# EFECTO VISUAL
			modulate = Color.RED
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(self):
				modulate = Color.WHITE
			
			# MATAR
			if is_instance_valid(target) and target.has_method("die"):
				target.die()
				attack_cooldown = 5.0  
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
