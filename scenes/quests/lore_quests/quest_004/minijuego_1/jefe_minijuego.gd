extends CharacterBody2D
var pending_shot := false
@onready var audio_ataque: AudioStreamPlayer2D = $AudioStreamPlayer2D
enum State {
	IDLE,
	ATTACK,
	FIGHT,
	DEAD
}
enum ShootPattern {
	SPIRAL,
	CROSS,
	X_CROSS,
	BURST,
	DOUBLE_SPIRAL
}

var current_pattern := ShootPattern.SPIRAL
@export var hp := 25
@export var speed := 80.0
@export var bullet_scene: PackedScene
@export var chase_speed := 120.0
var arena: Area2D
var player: Node2D
var is_chasing := false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var move_timer: Timer = $MoveTimer
@onready var state_timer: Timer = $StateTimer
@onready var shoot_point: Marker2D = $Marker2D

var state: State = State.IDLE

var move_dir := Vector2.ZERO
var can_move := false

var spiral_angle := 0.0


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	add_to_group("golem")
	print("Arena encontrada: ", arena)

	if arena:
		var collision = arena.get_node_or_null("CollisionShape2D")
		print("Collision: ", collision)

		if collision:
			print("Shape: ", collision.shape)
	await get_tree().process_frame

	arena = get_tree().get_first_node_in_group("arena_controller")

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

	sprite.play("emerger")
	sprite.animation_finished.connect(_on_emerge_finished)
func _on_emerge_finished() -> void:

	if sprite.animation != "emerger":
		return

	start_fight()
func _physics_process(_delta: float) -> void:

	if state == State.DEAD:
		return

	if state != State.FIGHT:
		return

	if not can_move:
		velocity = Vector2.ZERO

	elif is_chasing and player != null:

		var dir = (
			player.global_position - global_position
		).normalized()

		velocity = dir * chase_speed

	else:
		var siguiente_pos = global_position + move_dir * 40.0

		if esta_dentro(siguiente_pos):
			velocity = move_dir * speed
		else:
			move_dir = random_direction()
			velocity = move_dir * speed
	if abs(velocity.x) > 10:

		if velocity.x > 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	move_and_slide()
	mantener_dentro_arena()
func _on_state_timer_timeout() -> void:

	match state:

		State.IDLE:

			state = State.ATTACK

			sprite.play("attack")

			state_timer.wait_time = 1.0
			state_timer.start()

		State.ATTACK:

			start_fight()

func esta_dentro(pos: Vector2) -> bool:

	if arena == null:
		return true

	var collision := arena.get_node("CollisionShape2D")

	if collision == null:
		return true

	var shape = collision.shape

	if shape is RectangleShape2D:

		var rect := Rect2(
			arena.global_position - shape.size / 2.0,
			shape.size
		)

		return rect.has_point(pos)

	return true

func start_fight() -> void:

	state = State.FIGHT

	move_dir = random_direction()

	if move_dir == Vector2.ZERO:
		move_dir = Vector2.RIGHT

	pending_shot = true

	audio_ataque.play() # <- agregar

	sprite.play("attack")

	move_timer.wait_time = randf_range(8.0, 13.0)
	move_timer.start()

	shoot_timer.wait_time = 1.0
func _on_move_timer_timeout() -> void:

	if state != State.FIGHT:
		return

	if can_move:

		current_pattern = randi() % 5
		can_move = false
		is_chasing = false

		shoot_timer.stop()
		sprite.play("idle")

		move_timer.wait_time = randf_range(0.3, 1.0)

	else:

		pending_shot = true

		audio_ataque.stop()
		audio_ataque.play()

		sprite.play("attack")

		move_timer.wait_time = randf_range(4.0, 6.0)

	move_timer.start()


func random_direction() -> Vector2:

	for i in range(30):

		var dir := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		var destino := global_position + dir * 250.0

		if esta_dentro(destino):
			return dir

	return Vector2.ZERO

func _on_shoot_timer_timeout() -> void:

	if state != State.FIGHT:
		return

	match current_pattern:

		ShootPattern.SPIRAL:
			shoot_spiral()

		ShootPattern.CROSS:
			shoot_cross()

		ShootPattern.X_CROSS:
			shoot_x_cross()

		ShootPattern.BURST:
			shoot_burst()

		ShootPattern.DOUBLE_SPIRAL:
			shoot_double_spiral()

func shoot_spiral() -> void:

	for angle_offset in [0, 90, 180, 270]:
		spawn_bullet(spiral_angle + angle_offset)

	spiral_angle += 6.0

func flash_damage() -> void:

	sprite.modulate = Color(1, 0.2, 0.2) # rojo

	await get_tree().create_timer(0.15).timeout

	if state != State.DEAD:
		sprite.modulate = Color.WHITE
func take_damage(amount: int) -> void:

	if state == State.DEAD:
		return

	flash_damage()

	hp -= amount

	if hp <= 0:
		die()

func die() -> void:

	state = State.DEAD

	shoot_timer.stop()
	move_timer.stop()
	state_timer.stop()

	velocity = Vector2.ZERO

	sprite.play("death")

	await sprite.animation_finished

	queue_free()
func spawn_bullet(angle: float) -> void:

	var bullet = bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = shoot_point.global_position

	var dir = Vector2.RIGHT.rotated(
		deg_to_rad(angle)
	)

	bullet.direction = dir

func shoot_cross() -> void:

	spawn_bullet(0)
	spawn_bullet(90)
	spawn_bullet(180)
	spawn_bullet(270)
func shoot_x_cross() -> void:

	spawn_bullet(45)
	spawn_bullet(135)
	spawn_bullet(225)
	spawn_bullet(315)
func shoot_burst() -> void:

	for i in range(8):

		spawn_bullet(i * 45)
func shoot_double_spiral() -> void:

	for angle_offset in [0, 180]:

		spawn_bullet(spiral_angle + angle_offset)

	for angle_offset in [90, 270]:

		spawn_bullet(-spiral_angle + angle_offset)

	spiral_angle += 8.0
func _on_animation_finished() -> void:

	if state == State.DEAD:
		return

	# Cuando termina el ataque empieza a caminar y disparar
	if sprite.animation == "attack" and pending_shot:

		pending_shot = false

		can_move = true

		if randf() < 0.3 and player != null:
			is_chasing = true
		else:
			is_chasing = false
			move_dir = random_direction()

		sprite.play("walk")

		_on_shoot_timer_timeout() # dispara inmediatamente

		if shoot_timer.is_stopped():
			shoot_timer.start()

		return
func mantener_dentro_arena() -> void:

	if arena == null:
		return

	var collision: CollisionShape2D = arena.get_node("CollisionShape2D")

	if collision == null:
		return

	var shape: RectangleShape2D = collision.shape as RectangleShape2D

	if shape == null:
		return

	var half: Vector2 = shape.size * 0.5

	var min_x: float = collision.global_position.x - half.x
	var max_x: float = collision.global_position.x + half.x
	var min_y: float = collision.global_position.y - half.y
	var max_y: float = collision.global_position.y + half.y

	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)
