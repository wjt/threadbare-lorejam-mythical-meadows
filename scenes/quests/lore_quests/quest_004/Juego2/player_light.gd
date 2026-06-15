#player_light

extends CharacterBody2D

@export var speed: float = 200.0
@export var run_speed: float = 350.0
@export var energy_drain_rate: float = 5.0

var lantern_energy: float = 100.0
var max_energy: float = 100.0
var is_lantern_on: bool = true
var _is_knocked_back: bool = false
var _knockback_timer: float = 0.0
var _light_offset: Vector2 = Vector2(25, -10)

@onready var animate_sprite = $SpritePersonaje
@onready var light_pos = $LightPosition
@onready var point_light = $LightPosition/Luz
@onready var energy_bar = $EnergyBar

func _ready():
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# CONSUMIR ENERGÍA
	if is_lantern_on:
		lantern_energy -= energy_drain_rate * delta
		if lantern_energy <= 0:
			lantern_energy = 0
			is_lantern_on = false
			if point_light:
				point_light.energy = 0
			print("🔋 Linterna apagada")
	
	# ACTUALIZAR LUZ
	if point_light:
		if is_lantern_on:
			point_light.enabled = true
			var intensity = lantern_energy / max_energy
			point_light.energy = 0.5 + (intensity * 1.0)
		else:
			point_light.enabled = false
	
	# KNOCKBACK
	if _is_knocked_back:
		_knockback_timer -= delta
		if _knockback_timer <= 0:
			_is_knocked_back = false
		move_and_slide()
		return
	
	# INPUT
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir == Vector2.ZERO:
		input_dir = Vector2(
			int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
			int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
		)
	
	# MOVIMIENTO
	var current_speed := run_speed if Input.is_key_pressed(KEY_SHIFT) else speed
	velocity = input_dir * current_speed
	move_and_slide()
	
	# ANIMACIÓN
	if input_dir.x != 0:
		animate_sprite.flip_h = input_dir.x < 0
	
	# LUZ POSITION
	var target_offset = _light_offset
	if input_dir.x < 0:
		target_offset.x = -abs(_light_offset.x)
	elif input_dir.x > 0:
		target_offset.x = abs(_light_offset.x)
	light_pos.position = light_pos.position.lerp(target_offset, 0.2)

func recharge(amount: float):
	lantern_energy = min(max_energy, lantern_energy + amount)
	if not is_lantern_on and lantern_energy > 0:
		is_lantern_on = true
	print("🔋 Energía: ", lantern_energy)

func take_damage(amount: float, from_position: Vector2):
	lantern_energy = max(0, lantern_energy - amount)
	knockback(from_position, 300)
	print("💔 Daño! Energía: ", lantern_energy)

func knockback(from_position: Vector2, force: float = 300.0):
	var dir := (global_position - from_position).normalized()
	velocity = dir * force
	_is_knocked_back = true
	_knockback_timer = 0.3
	animate_sprite.modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(animate_sprite):
		animate_sprite.modulate = Color.WHITE


func _process(delta):
	if energy_bar:
		energy_bar.value = lantern_energy	

func is_lantern_on_func() -> bool:
	return is_lantern_on

func freeze():
	set_physics_process(false)
	velocity = Vector2.ZERO

func unfreeze():
	set_physics_process(true)
