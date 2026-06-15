# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

signal mode_changed(mode: Mode)

signal xp_changed(current_xp: int, xp_needed: int)
signal leveled_up(new_level: int)

## The possible player states.
enum Mode {
	USER_CONTROLLED,
	SYSTEM_CONTROLLED,
	DEFEATED,
}

const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10,
	&"walk": 6,
	&"attack_01": 4,
	&"attack_02": 4,
	&"defeated": 11,
}

const OPTIONAL_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"run": 6,
}

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp")

@export var player_name: String = "Player Name"

@export var mode: Mode = Mode.USER_CONTROLLED:
	set = _set_mode

@export var speeds: CharacterSpeeds:
	set = _set_speeds

@export_range(10, 100000, 10) var aiming_speed: float = 100.0

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_group("Sounds")
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"):
	set = _set_walk_sound_stream

@export_group("RPG Stats")
@export var max_health: float = 100.0
@export var bullet_scene: PackedScene = preload("res://scenes/quests/lore_quests/quest_004/Characters/player/Bullet.tscn")

var health: float
var level: int = 1
var xp: int = 0
var xp_needed: int = 5
var magnet_radius: float = 90.0

var bullet_damage_bonus: float = 0.0
var bullet_amount: int = 1
var bullet_spread: float = 15.0
var piercing_count: int = 1
var bullet_speed_bonus: float = 0.0

var _initial_speeds: CharacterSpeeds

@onready var input_walk_behavior: InputWalkBehavior = %InputWalkBehavior
@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_repel: Node2D = %PlayerRepel
@onready var player_hook: PlayerHook = %PlayerHook
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound
@onready var health_bar: ProgressBar = get_node_or_null("PlayerHealthBar")


func _ready() -> void:
	health = max_health
	if not Engine.is_editor_hint() and not is_in_group("player"):
		add_to_group("player")
	update_health_bar()
	_set_speeds(speeds)
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)
	if not Engine.is_editor_hint():
		GameState.abilities_changed.connect(_on_abilities_changed)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if mode != Mode.USER_CONTROLLED: return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot(false)
	elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_SHOULDER and event.pressed:
		shoot(true)

func shoot(is_gamepad: bool) -> void:
	if not bullet_scene:
		return
		
	var target_direction = Vector2.RIGHT
	
	if is_gamepad:
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_enemy: Node2D = null
		var min_distance = INF
		
		for enemy in enemies:
			if enemy is Node2D and enemy.visible:
				var dist = global_position.distance_to(enemy.global_position)
				if dist < min_distance:
					min_distance = dist
					closest_enemy = enemy
					
		if closest_enemy:
			target_direction = (closest_enemy.global_position - global_position).normalized()
		else:
			target_direction = velocity.normalized() if velocity != Vector2.ZERO else Vector2.RIGHT
	else:
		target_direction = (get_global_mouse_position() - global_position).normalized()
	
	for i in range(bullet_amount):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		
		var final_direction = target_direction
		if bullet_amount > 1:
			var offset_angle = (i - (bullet_amount - 1) / 2.0) * bullet_spread
			final_direction = target_direction.rotated(deg_to_rad(offset_angle))
			
		bullet.set("direction", final_direction)
		
		if "damage" in bullet:
			bullet.set("damage", bullet.get("damage") + bullet_damage_bonus)
		if "speed" in bullet:
			bullet.set("speed", bullet.get("speed") + bullet_speed_bonus)
		if "pierce_limit" in bullet:
			bullet.set("pierce_limit", piercing_count)
			
		get_tree().current_scene.call_deferred("add_child", bullet)

func take_damage(amount: float) -> void:
	if mode == Mode.DEFEATED: return
	
	health -= amount
	update_health_bar()
	if health <= 0:
		defeat(true)

func update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func heal_to_full() -> void:
	if mode == Mode.DEFEATED:
		return
	health = max_health
	update_health_bar()

func gain_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp, xp_needed)
	if xp >= xp_needed:
		trigger_level_up()

func trigger_level_up() -> void:
	xp -= xp_needed
	level += 1
	xp_needed = level * 5 
	leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed)
	show_upgrade_options()

func show_upgrade_options() -> void:
	var upgrade_menu = get_tree().current_scene.find_child("UpgradeMenu", true, false)
	if upgrade_menu:
		get_tree().paused = true
		var options = ["speed", "max_health", "bullet_damage", "bullet_amount", "bullet_pierce", "bullet_speed", "magnet"]
		options.shuffle()
		var chosen_options = [options[0], options[1]]
		if not upgrade_menu.option_selected.is_connected(apply_upgrade):
			upgrade_menu.option_selected.connect(apply_upgrade)
		upgrade_menu.setup_options(chosen_options)
		upgrade_menu.show()

func apply_upgrade(type: String) -> void:
	match type:
		"speed":
			if speeds:
				speeds.walk_speed += 25.0
				speeds.run_speed += 25.0
				_set_speeds(speeds)
		"max_health":
			max_health += 20.0
			health += 20.0
			update_health_bar()
		"bullet_damage":
			bullet_damage_bonus += 15.0
		"bullet_amount":
			bullet_amount += 1
		"bullet_pierce":
			piercing_count += 1
		"bullet_speed":
			bullet_speed_bonus += 100.0
		"magnet":
			magnet_radius += 60.0
	get_tree().paused = false


# --- FUNCIONES DEL FRAMEWORK ORIGINAL ---
func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode
	mode = new_mode
	if not is_node_ready():
		return
	match mode:
		Mode.USER_CONTROLLED:
			_toggle_player_behavior(input_walk_behavior, true)
			_toggle_player_behavior(player_interaction, true)
			_toggle_abilities()
		Mode.SYSTEM_CONTROLLED:
			_toggle_player_behavior(input_walk_behavior, false)
			_toggle_player_behavior(player_interaction, true)
			_toggle_abilities()
		Mode.DEFEATED:
			_toggle_player_behavior(input_walk_behavior, false)
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_repel, false)
			_toggle_player_behavior(player_hook, false)

	if mode != previous_mode:
		mode_changed.emit(mode)

func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	player_sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()

func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	behavior_node.visible = is_active
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	for animation: StringName in REQUIRED_ANIMATION_FRAMES:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)

	var animations: Dictionary[StringName, int] = REQUIRED_ANIMATION_FRAMES.merged(
		OPTIONAL_ANIMATION_FRAMES
	)
	for animation: StringName in animations:
		if not sprite_frames.has_animation(animation):
			continue

		var count := sprite_frames.get_frame_count(animation)
		var expected_count := animations[animation]

		if count != expected_count:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [animation, count, expected_count]
				)
			)

	return warnings

func _set_speeds(new_speeds: CharacterSpeeds) -> void:
	speeds = new_speeds
	if speeds:
		_initial_speeds = new_speeds.duplicate()
	if not is_node_ready():
		return
	input_walk_behavior.speeds = speeds

func teleport_to(
	tele_position: Vector2,
	smooth_camera: bool = false,
	look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED
) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()

	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = tele_position
		%PlayerSprite.look_at_side(look_side)
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = tele_position

func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value
	if not is_node_ready():
		await ready
	if _walk_sound:
		_walk_sound.stream = walk_sound_stream

func defeat(falling: bool = false) -> void:
	if mode == Player.Mode.DEFEATED:
		return

	mode = Player.Mode.DEFEATED
	velocity = Vector2.ZERO
	GameState.decrement_lives()

	if falling:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 2.0)

	await get_tree().create_timer(2.0).timeout

	if GameState.current_lives > 0:
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	else:
		_handle_game_over()

func take_control(_controlled_by: Node) -> void:
	mode = Mode.SYSTEM_CONTROLLED

func return_control(_controlled_by: Node) -> void:
	mode = Mode.USER_CONTROLLED

func _toggle_abilities() -> void:
	var can_repel := GameState.has_ability(Enums.PlayerAbilities.ABILITY_A)
	var can_grapple := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B)
	_toggle_player_behavior(player_repel, can_repel)
	_toggle_player_behavior(player_hook, can_grapple)
	if can_grapple:
		var has_longer_hook := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B_MODIFIER_1)
		player_hook.string_throw_length = 400.0 if has_longer_hook else 200.0
		player_hook.string_max_length = 450.0 if has_longer_hook else 250.0

func _on_abilities_changed() -> void:
	if mode != Mode.DEFEATED:
		_toggle_abilities()

func _handle_game_over() -> void:
	GameState.reset_lives()
	var challenge_start_scene: String = GameState.get_challenge_start_scene()

	if challenge_start_scene.is_empty():
		GameState.set_current_spawn_point(^"")
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	else:
		SceneSwitcher.change_to_file_with_transition(
			challenge_start_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)

func _on_player_hook_aiming_changed(is_aiming: bool) -> void:
	if input_walk_behavior and input_walk_behavior.speeds:
		input_walk_behavior.speeds.walk_speed = (
			aiming_speed if is_aiming else _initial_speeds.walk_speed
		)
		input_walk_behavior.speeds.run_speed = aiming_speed if is_aiming else _initial_speeds.run_speed
