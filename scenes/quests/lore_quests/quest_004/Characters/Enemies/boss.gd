extends CharacterBody2D

@export var max_health: float = 35000
var health: float

var player: Node2D
var bullet_scene: PackedScene = preload("res://scenes/quests/lore_quests/quest_004/Characters/player/Bossbullet.tscn")

var base_attack_cooldown: float = 0.6
var time_since_last_shot: float = 0.0

var teleport_cooldown: float = 6.0
var time_since_teleport: float = 0.0
var damage_threshold_teleport: float = 0.0

var is_dying := false

@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var percent_label: Label = get_node_or_null("HealthBar/PercentLabel")
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	health = max_health
	
	add_to_group("enemies")
	
	if has_node("HitboxArea"):
		$HitboxArea.add_to_group("enemies")
		$HitboxArea.body_entered.connect(_on_player_touched)
	
	player = get_tree().get_first_node_in_group("player")
	velocity = Vector2.ZERO
	
	damage_threshold_teleport = max_health * 0.10
	update_health_ui()
	
	if sprite:
		sprite.play("default")
		sprite.animation_finished.connect(_on_sprite_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dying:
		return

	if not player:
		return
	
	run_attack_logic(delta)
	run_anti_cheese_teleport(delta)


func take_damage(amount: float) -> void:
	if is_dying:
		return

	health -= amount
	damage_threshold_teleport -= amount
	update_health_ui()
	
	if sprite:
		sprite.play("hit")
	
	if health <= 0:
		die_and_go_to_outro()
		return
	
	if damage_threshold_teleport <= 0:
		teleport_to_safety()


func die_and_go_to_outro() -> void:
	is_dying = true
	set_physics_process(false)

	hide()

	if has_node("HitboxArea"):
		$HitboxArea.set_deferred("monitoring", false)
		$HitboxArea.set_deferred("monitorable", false)

	await play_death_fog_transition()

	get_tree().change_scene_to_file("res://scenes/quests/lore_quests/quest_004/3_Outro/3_Outro.tscn")


func play_death_fog_transition() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)

	var fog := ColorRect.new()
	fog.color = Color(0.78, 0.82, 0.82, 0.0)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(fog)

	fog.offset_left = 0
	fog.offset_top = 0
	fog.offset_right = 0
	fog.offset_bottom = 0

	var tween := create_tween()
	tween.tween_property(fog, "color", Color(0.78, 0.82, 0.82, 1.0), 3.5)
	tween.tween_interval(1.0)

	await tween.finished


func run_attack_logic(delta: float) -> void:
	var current_cooldown = base_attack_cooldown
	var spread_amount = 0.2
	var health_ratio = health / max_health
	
	if health_ratio <= 0.75:
		current_cooldown = base_attack_cooldown * (health_ratio / 0.75)
		current_cooldown = clamp(current_cooldown, 0.04, base_attack_cooldown)
		spread_amount = 0.2 + (1.0 - (health_ratio / 0.75)) * 1.8
		
	time_since_last_shot += delta

	if time_since_last_shot >= current_cooldown:
		time_since_last_shot = 0.0
		
		if health_ratio <= 0.50 and randf() < 0.30:
			fire_predictive_attack()
		else:
			fire_random_burst(spread_amount)


func fire_random_burst(spread: float) -> void:
	var base_directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2(1, 1).normalized(),
		Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(-1, -1).normalized()
	]
	
	for base_dir in base_directions:
		spawn_bullet(base_dir, spread)


func fire_predictive_attack() -> void:
	if not player:
		return

	var dir_to_player = (player.global_position - global_position).normalized()
	
	spawn_bullet(dir_to_player, 0.0)
	spawn_bullet(dir_to_player.rotated(deg_to_rad(15)), 0.0)
	spawn_bullet(dir_to_player.rotated(deg_to_rad(-15)), 0.0)


func spawn_bullet(base_dir: Vector2, spread: float) -> void:
	if is_dying:
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position

	var random_offset = Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	var final_direction = (base_dir + random_offset).normalized()

	bullet.set("direction", final_direction)
	get_tree().current_scene.call_deferred("add_child", bullet)


func run_anti_cheese_teleport(delta: float) -> void:
	time_since_teleport += delta

	if time_since_teleport >= teleport_cooldown:
		teleport_to_safety()


func teleport_to_safety() -> void:
	if not player or is_dying:
		return

	time_since_teleport = 0.0
	damage_threshold_teleport = max_health * 0.10
	
	var random_angle = randf() * PI * 2.0
	var random_radius = randf_range(250.0, 450.0)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_radius
	
	global_position = player.global_position + offset


func update_health_ui() -> void:
	var health_percent = (health / max_health) * 100.0

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

	if percent_label:
		percent_label.text = "%d%%" % clampi(int(health_percent), 0, 100)


func _on_player_touched(body: Node) -> void:
	if is_dying:
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(999999.0)

func _on_sprite_animation_finished() -> void:
	if sprite and sprite.animation == "hit" and not is_dying:
		sprite.play("default")
