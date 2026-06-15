extends CharacterBody2D

signal xp_changed(current_xp: int, xp_needed: int)
signal leveled_up(new_level: int)

@export var speed: float = 250.0
@export var max_health: float = 100.0
var health: float

var level: int = 1
var xp: int = 0
var xp_needed: int = 5
var magnet_radius: float = 90.0

var bullet_scene: PackedScene = preload("res://scenes/quests/lore_quests/quest_004/Characters/player/Bullet.tscn")

var bullet_damage_bonus: float = 0.0
var bullet_amount: int = 1
var bullet_spread: float = 15.0
var piercing_count: int = 1
var bullet_speed_bonus: float = 0.0

@onready var health_bar: ProgressBar = get_node_or_null("PlayerHealthBar")

func _ready() -> void:
	health = max_health
	add_to_group("player")
	update_health_bar()

func _physics_process(_delta: float) -> void:
	var input_direction = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0
	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_direction.y += 1.0
	if Input.is_key_pressed(KEY_W):
		input_direction.y -= 1.0
		
	if input_direction == Vector2.ZERO:
		input_direction.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		input_direction.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		if input_direction.length() < 0.2:
			input_direction = Vector2.ZERO
			
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()
		
	velocity = input_direction * speed
	move_and_slide()

func _input(event: InputEvent) -> void:
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
	health -= amount
	update_health_bar()
	if health <= 0:
		call_deferred("die_and_restart")

func update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func die_and_restart() -> void:
	get_tree().reload_current_scene()

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
			speed += 25.0
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
	
func heal_to_full() -> void:
	health = max_health
	update_health_bar()
