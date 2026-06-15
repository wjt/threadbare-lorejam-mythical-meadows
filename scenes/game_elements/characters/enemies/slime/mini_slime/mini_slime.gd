extends CharacterBody2D

var _player = null
var speed: float = 120.0 
var hp: int = 2 
var recibiendo_dano: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO 

var weight: float = 0.0
var hook_control = null
var controlled_entity = self

@onready var anim = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	add_to_group("hook_listener")
	add_to_group("Enemigos")
	add_to_group("Interactable")
	
	var jefe = get_parent().get_node_or_null("SlimeGrunon") 
	if jefe:
		add_collision_exception_with(jefe)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		if anim: anim.play("idle")
		return
		
	if knockback_velocity.length() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800.0 * delta)
	else:
		var direction = global_position.direction_to(_player.global_position)
		velocity = direction * speed
		
		if anim:
			if direction.x > 0:
				anim.flip_h = true 
			elif direction.x < 0:
				anim.flip_h = false 
				
		if not recibiendo_dano and anim:
			anim.play("walk")

		
	move_and_slide()

	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider() == _player:
			var push_dir = _player.global_position.direction_to(global_position)
			knockback_velocity = push_dir * 150.0

func got_repelled(direction) -> void:
	knockback_velocity = direction * 600.0
	_procesar_dano_total(direction * 600.0)

func hooked(_new_hooked_to, _is_loop: bool) -> void:
	if is_instance_valid(_player):
		var dir_hacia_jugador = global_position.direction_to(_player.global_position)
		knockback_velocity = dir_hacia_jugador * 800.0
		_procesar_dano_total(dir_hacia_jugador * 800.0)

func get_anchor_position() -> Vector2:
	return global_position

func _procesar_dano_total(fuerza_fisica: Vector2) -> void:
	if recibiendo_dano: 
		return 
		
	hp -= 1
	
	if hp <= 0:
		queue_free() 
	else:
		recibiendo_dano = true
		
		if anim: 
			anim.play("hurt") 
			anim.modulate = Color.RED 
			
		knockback_velocity = fuerza_fisica 

		await get_tree().create_timer(0.3).timeout 

		if anim:
			anim.modulate = Color.WHITE 
			
		recibiendo_dano = false

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var nombre_area = area.name.to_lower()
	var padre = null
	var nombre_padre = ""
	
	if area.get_parent(): 
		padre = area.get_parent()
		nombre_padre = padre.name.to_lower()
	
	if "slime" in nombre_padre or "slime" in nombre_area:
		if padre and "velocity" in padre and padre.velocity.length() > 800:
			queue_free() 

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if "slime" in body.name.to_lower():
		if "velocity" in body and body.velocity.length() > 800:
			queue_free()
