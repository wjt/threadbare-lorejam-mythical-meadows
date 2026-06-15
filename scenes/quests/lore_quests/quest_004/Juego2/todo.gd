extends Node2D

# MARIPOSAS
var butterfly_scene: PackedScene
var respawn_timer: float = 0.0

func _ready():
	butterfly_scene = load("res://scenes/quests/lore_quests/quest_004/Juego2/butterfly.tscn")
	await get_tree().create_timer(1.0).timeout
	_spawn_butterflies(5)

func _process(delta):
	respawn_timer += delta
	if respawn_timer >= 4.0:
		respawn_timer = 0
		if get_tree().get_nodes_in_group("butterflies").size() < 3:
			_spawn_butterflies(1)

func _spawn_butterflies(amount: int):
	var player = $PlayerLight
	for i in range(amount):
		var angle = randf() * TAU
		var pos = player.global_position + Vector2(cos(angle), sin(angle)) * 250
		var b = butterfly_scene.instantiate()
		b.global_position = pos
		add_child(b)
