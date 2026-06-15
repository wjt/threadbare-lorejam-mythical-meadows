extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var follow_distance: float = 120.0
@export var follow_speed: float = 150.0
@export var light_min_energy: float = 0.8
@export var light_max_energy: float = 2.0
@export var light_speed: float = 1.5

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var point_light: PointLight2D = $PointLight2D

var player: CharacterBody2D = null
var is_following: bool = false

func _ready() -> void:
	animated_sprite_2d.play("Hada")
	$Area2D.body_entered.connect(_on_area_2d_body_entered)

func _physics_process(delta: float) -> void:
	point_light.energy = lerp(light_min_energy, light_max_energy,
		0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * light_speed))

	if not is_following or player == null:
		return

	var target_pos: Vector2 = player.global_position + Vector2(-follow_distance, -40.0)
	var distance: float = global_position.distance_to(target_pos)

	if distance > 10.0:
		var direction: Vector2 = (target_pos - global_position).normalized()
		velocity = direction * follow_speed
	else:
		velocity = Vector2.ZERO

	if velocity.x < 0:
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = false

	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_following:
		return
	if body is CharacterBody2D and body.name == "Player":
		player = body
		is_following = true
