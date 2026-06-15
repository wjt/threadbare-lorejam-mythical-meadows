extends Node2D

@onready var spawn_timer: Timer = $Timer2
@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = $CanvasLayer/XPBar
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var spawn_points: Node2D = $SpawnPoints

var enemy_scene: PackedScene = preload("res://scenes/quests/lore_quests/quest_004/Characters/Enemies/Enemy.tscn")
var game_time_left: int = 175
var boss_spawned: bool = false

func _ready() -> void:
	player.add_to_group("player")
	if spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.disconnect(_on_spawn_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	spawn_timer.start()
	
	xp_bar.max_value = player.xp_needed
	xp_bar.value = player.xp
	
	player.xp_changed.connect(_on_player_xp_changed)
	
	var upgrade_menu = get_tree().current_scene.find_child("UpgradeMenu", true, false)
	if upgrade_menu:
		upgrade_menu.hide()
		
	update_timer_display()

func _on_spawn_timer_timeout() -> void:
	if boss_spawned or not player:
		return
		
	process_game_timer()
	
	if game_time_left <= 0:
		return
		
	var spawn_count: int = 1
	var current_level: int = player.level
	
	if current_level >= 30:
		spawn_count = int(pow(1.15, current_level - 30)) + 5
	else:
		spawn_count = int(current_level / 5) + 1
		
	var time_passed: int = 175 - game_time_left
	var time_bonus: int = int(time_passed / 15) 
	
	spawn_count += time_bonus
		
	for i in range(spawn_count):
		spawn_enemy()

func spawn_enemy() -> void:
	if boss_spawned or not spawn_points:
		return
		
	var markers = spawn_points.get_children()
	if markers.is_empty():
		return
		
	var random_marker = markers.pick_random()
	var enemy = enemy_scene.instantiate()
	enemy.global_position = random_marker.global_position
	add_child(enemy)

func process_game_timer() -> void:
	if game_time_left > 0:
		game_time_left -= 1
		update_timer_display()
		if game_time_left <= 0:
			win_game()

func update_timer_display() -> void:

	var minutes: int = max(0, game_time_left / 60)
	var seconds: int = max(0, game_time_left % 60)
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func win_game() -> void:
	boss_spawned = true 
	spawn_timer.stop()
	
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	for e in active_enemies:
		if is_instance_valid(e):
			e.queue_free()
			
	spawn_final_boss()

func spawn_final_boss() -> void:
	var boss_scene = preload("res://scenes/quests/lore_quests/quest_004/Characters/Enemies/Boss.tscn")
	var boss = boss_scene.instantiate()
	
	if player:
		var spawn_direction = Vector2.UP
		boss.global_position = player.global_position + (spawn_direction * 400.0)
		
	add_child(boss)

func _on_player_xp_changed(current_xp: int, xp_needed: int) -> void:
	xp_bar.max_value = xp_needed
	xp_bar.value = current_xp
