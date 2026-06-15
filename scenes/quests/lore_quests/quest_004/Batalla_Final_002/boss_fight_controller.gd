extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies_alive: int = 5
var spawning_enabled: bool = true
@onready var spawn_points = [
	$"../SpawnPoint",
	$"../SpawnPoint2",
	$"../SpawnPoint3"
]

var boss: Node = null
var boss_defeated: bool = false


func _ready() -> void:
	boss = get_tree().get_first_node_in_group("boss")
	spawn_loop()


func spawn_loop() -> void:
	while spawning_enabled:
		await get_tree().create_timer(spawn_interval).timeout

		if not spawning_enabled:
			return
		
		if boss_defeated:
			return
		
		if not is_instance_valid(boss):
			stop_spawning()
			return
		
		var enemies_alive := get_tree().get_nodes_in_group("boss_spawn_enemy").size()
		
		if enemies_alive < max_enemies_alive:
			spawn_enemy()


func spawn_enemy() -> void:
	if not spawning_enabled:
		return

	if enemy_scene == null:
		print("No hay escena de enemigo asignada")
		return
	
	for point in spawn_points:
		if not spawning_enabled:
			return

		var enemy = enemy_scene.instantiate()
		enemy.global_position = point.global_position
		enemy.add_to_group("boss_spawn_enemy")
		enemy.add_to_group("enemy")
		
		get_tree().current_scene.add_child(enemy)


func clear_spawned_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("boss_spawn_enemy")
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
			
func stop_spawning() -> void:
	spawning_enabled = false
	boss_defeated = true
	clear_spawned_enemies()
	print("Spawner detenido")
