extends CharacterBody2D
# Exports
@export var patrol_path: Path2D
@export var move_speed: float = 80.0
@export var chase_speed: float = 140.0
@export var max_health: int = 4

# Estado
enum State {PATROLLING, CHASING, ATTACKING, HURT, DEFEATED}
var state: State = State.PATROLLING

# variables internas
var health: int = max_health
var player: CharacterBody2D = null
var can_attack: bool = true
# conteo de ataques al player
var player_hit_count: int = 0 

# Patrulla por puntos del Path2D
var current_patrol_point_idx: int = 0
var previous_patrol_point_idx: int = -1

#Nodos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $VisionArea
@onready var hit_box: Area2D = $HitBox

func _ready() -> void:
	#posicionar al golem en el primer punto del path
	if patrol_path:
		global_position = _get_patrol_point(0)
	# señales de visión
	$VisionArea.body_entered.connect(_on_vision_entered)
	$VisionArea.body_exited.connect(_on_vision_exited)
	
	# Señal de golpe al player
	$HitBox.body_entered.connect(_on_hit_entered)

func _physics_process(_delta: float) -> void:
	match state:
		State.PATROLLING:
			_do_patrol()
		State.CHASING:
			_do_chase()
		State.ATTACKING:
			pass 
		State.HURT, State.DEFEATED:
			velocity = Vector2.ZERO
	move_and_slide()

# Patrullando por puntos del Path2D
func _do_patrol() -> void:
	if not patrol_path:
		_play_anim(&"Golem_Idle")
		return
	
	var target: Vector2 = _get_patrol_point(current_patrol_point_idx)
	var direction: Vector2 = global_position.direction_to(target)
	var distance: float = global_position.distance_to(target)
	
	if distance < 8.0:
		_advance_patrol_point()
		velocity = Vector2.ZERO
		_play_anim(&"Golem_Idle")
		return
	
	velocity = direction * move_speed
	_face(direction.x)
	_play_anim(&"Golem_Move")

func _advance_patrol_point() -> void:
	if not patrol_path or patrol_path.curve.point_count < 2:
		return
	
	var total: int = patrol_path.curve.point_count
	var at_last: bool = current_patrol_point_idx == total - 1
	var at_first: bool = current_patrol_point_idx == 0
	var going_back: bool = previous_patrol_point_idx > current_patrol_point_idx
	
	var next_idx: int
	if at_last:
		next_idx = current_patrol_point_idx - 1
	elif at_first:
		next_idx = current_patrol_point_idx + 1
	elif going_back:
		next_idx = current_patrol_point_idx - 1
	else:
		next_idx = current_patrol_point_idx + 1
	
	previous_patrol_point_idx = current_patrol_point_idx
	current_patrol_point_idx = next_idx

func _get_patrol_point(idx: int) -> Vector2:
	var local_pos: Vector2 = patrol_path.curve.get_point_position(idx)
	return patrol_path.to_global(local_pos)

# Persecucion
func _do_chase() -> void:
	if not is_instance_valid(player):
		state = State.PATROLLING
		return
	
	var distance: float = global_position.distance_to(player.global_position)
	# Si está cerca ataca directamente sin esperar el HitBox
	if distance < 60.0 and can_attack:
		_do_attack(player)
		return
	
	var direction: Vector2 = global_position.direction_to(player.global_position)
	velocity = direction * chase_speed
	_face(direction.x)
	_play_anim(&"Golem_Move")

#VISION DETECTA AL PLAYER
func _on_vision_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state != State.DEFEATED:
		player = body
		state = State.CHASING

func _on_vision_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		if state != State.DEFEATED:
			state = State.PATROLLING

# Hitbox - golpea al player cuando esta cerca
func _on_hit_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_attack and state == State.CHASING:
		_do_attack(body)

func _do_attack(target: CharacterBody2D) -> void:
	if not can_attack or state == State.DEFEATED:
		return
	
	can_attack = false
	state = State.ATTACKING
	velocity = Vector2.ZERO
	_play_anim(&"Golem_Attack")
	
	await sprite.animation_finished
	
	#solo empuja al player por ahora
	if is_instance_valid(target):
		player_hit_count += 1
		var direction := global_position.direction_to(target.global_position)
		target.velocity = direction * 300.0
		# A los 3 golpes el player muere
		if player_hit_count >= 3 and target.has_method("defeat"):
			target.defeat()
	await get_tree().create_timer(0.1).timeout
	can_attack = true
	state = State.CHASING if is_instance_valid(player) else State.PATROLLING

# Recibi Daño (llamado desde el player)
func take_damage() -> void:
	if state == State.DEFEATED or state == State.ATTACKING or state == State.HURT:
		return
	
	health -= 1
	
	if health <= 0:
		_die()
		return
	
	state = State.HURT
	can_attack = false
	velocity = Vector2.ZERO
	_play_anim(&"Golem_Hurt")
	
	await sprite.animation_finished
	
	can_attack = true
	# despues de hurt siempre intenta atacar si el player está cerca
	if is_instance_valid(player):
		state = State.CHASING
		var distance: float = global_position.distance_to(player.global_position)
		if distance < 60.0 and can_attack:
			_do_attack(player)
	else:
		state = State.PATROLLING

func _die() -> void:
	state = State.DEFEATED
	velocity = Vector2.ZERO
	can_attack = false
	_play_anim(&"Golem_Defeat")
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(2.0).timeout
	queue_free()
	
# Helpers
func _face(dir_x: float) -> void:
	if dir_x > 0.0:
		sprite.flip_h = false
	elif dir_x < 0.0:
		sprite.flip_h = true

func _play_anim(anim: StringName) -> void:
	if sprite.animation != anim:
		sprite.play(anim)

# ataque al golem desde el player
func got_repelled(direction: Vector2) -> void:
	if state == State.DEFEATED or state == State.ATTACKING:
		return
	velocity = direction * 200.0
	take_damage()
