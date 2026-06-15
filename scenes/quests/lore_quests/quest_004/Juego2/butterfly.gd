#butterfly

extends CharacterBody2D

@export var speed: float = 80.0  
@export var follow_range: float = 300.0 
@export var idle_range: float = 150.0 

var panic_speed: float = 200.0
var separation_radius: float = 60.0
var is_alive: bool = true
var in_panic: bool = false
var panic_direction: Vector2 = Vector2.ZERO
var velocity_random: Vector2 = Vector2.ZERO
var idle_timer: float = 0.0

func _ready():
	add_to_group("butterflies")
	# Velocidad aleatoria entre 60 y 120
	speed = randf_range(60, 120)
	# Dirección inicial aleatoria
	velocity_random = Vector2(randf_range(-50, 50), randf_range(-50, 50))

func _physics_process(delta):
	if not is_alive:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var dist_to_player = global_position.distance_to(player.global_position)
	
	# 1. MODO PÁNICO 
	var linterna_apagada = false
	if player.has_method("is_lantern_on_func"):
		linterna_apagada = not player.is_lantern_on_func()
	
	if linterna_apagada and not in_panic:
		in_panic = true
		panic_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		modulate = Color(0.5, 0.5, 0.7)
	elif not linterna_apagada and in_panic:
		in_panic = false
		modulate = Color.WHITE
	
	if in_panic:
		panic_direction += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		panic_direction = panic_direction.normalized()
		velocity = panic_direction * panic_speed
		move_and_slide()
		return
	
	#  COMPORTAMIENTO NORMAL
	if dist_to_player < follow_range:
		# La mariposa sigue al jugador
		var dir = (player.global_position - global_position).normalized()
		var target_velocity = dir * speed
		
		# Separación 
		var separation = Vector2.ZERO
		var nearby = 0
		for other in get_tree().get_nodes_in_group("butterflies"):
			if other != self and other.is_alive:
				var dist = global_position.distance_to(other.global_position)
				if dist < separation_radius:
					separation += (global_position - other.global_position) / dist
					nearby += 1
		
		if nearby > 0:
			separation = separation.normalized() * 40
		
		velocity = (target_velocity + separation).limit_length(speed * 1.2)
		
		# Movimiento aleatorio 
		velocity_random += Vector2(randf_range(-20, 20), randf_range(-20, 20)) * delta
		velocity_random = velocity_random.limit_length(30)
		velocity += velocity_random
		
	else:
		# Mariposa quieta/
		idle_timer += delta
		if idle_timer > 1.0:
			idle_timer = 0
			velocity_random = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		velocity = velocity_random
		velocity = velocity.limit_length(30)
	
	move_and_slide()
	
	if velocity.length() > 10:
		rotation = velocity.angle()

func die():
	if not is_alive:
		return
	is_alive = false
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.parallel().tween_property(self, "scale", Vector2(0.1, 0.1), 0.3)
	await tween.finished
	queue_free()
