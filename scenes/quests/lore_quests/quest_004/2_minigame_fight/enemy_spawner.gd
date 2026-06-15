extends Node2D

@export var enemy_scene: PackedScene

@onready var spawn_points_container: Node2D = $SpawnPoints
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_spawn_enemy)

func _spawn_enemy() -> void:
	if not enemy_scene:
		return
		
	var markers = spawn_points_container.get_children()
	if markers.is_empty():
		return
		
	var random_marker = markers.pick_random()
	var new_enemy = enemy_scene.instantiate()
	new_enemy.global_position = random_marker.global_position
	get_tree().current_scene.add_child(new_enemy)
