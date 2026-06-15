extends CharacterBody2D

const WANDER_RADIUS = 200.0

@export_group("Velocidad")
@export var speed: float = 60.0

@export_group("Tiempos Idle")
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

@export_group("Tiempos Down")
@export var down_time_min: float = 4.0
@export var down_time_max: float = 9.0

@export_group("Probabilidades")
@export_range(0.0, 1.0, 0.05) var prob_walk: float = 0.40
@export_range(0.0, 1.0, 0.05) var prob_down: float = 0.30

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

enum State { IDLE, WALK, DOWN }

var state: State = State.IDLE
var state_timer: float = 0.0
var origin_pos: Vector2

func _ready() -> void:
	origin_pos = global_position
	state_timer = randf_range(0.5, 2.5)
	_enter_idle()

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta)
		State.DOWN:
			_process_down(delta)

# ── IDLE ──────────────────────────────────────────────────────────────────────

func _enter_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	animated_sprite.play("Idle")
	state_timer = randf_range(idle_time_min, idle_time_max)

func _process_idle(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		var roll := randf()
		if roll < prob_walk:
			_enter_walk()
		elif roll < prob_walk + prob_down:
			_enter_down()
		else:
			state_timer = randf_range(idle_time_min, idle_time_max)

# ── WALK ──────────────────────────────────────────────────────────────────────

func _enter_walk() -> void:
	state = State.WALK
	animated_sprite.play("Walk")
	var angle := randf() * TAU
	var dist  := randf_range(40.0, WANDER_RADIUS)
	var target := origin_pos + Vector2(cos(angle), sin(angle)) * dist
	nav_agent.target_position = target

func _process_walk(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_enter_idle()
		return

	var next := nav_agent.get_next_path_position()
	var dir  := (next - global_position).normalized()

	velocity = dir * speed
	move_and_slide()

	if dir.x != 0.0:
		animated_sprite.flip_h = dir.x > 0.0

# ── DOWN ──────────────────────────────────────────────────────────────────────

func _enter_down() -> void:
	state = State.DOWN
	velocity = Vector2.ZERO
	animated_sprite.play("Down")
	state_timer = randf_range(down_time_min, down_time_max)

func _process_down(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_idle()
