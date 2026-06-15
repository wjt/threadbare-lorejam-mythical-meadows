#Butterfly_manager
extends Node

@export var butterfly_scene: PackedScene
@export var min_butterflies: int = 3
@export var check_interval: float = 3.0
@export var respawn_radius: float = 400

var _timer: float = 0.0
var _active: bool = true
var Global

func set_global_reference(global_ref):
	Global = global_ref

func _ready():
	add_to_group("butterfly_manager")

	
func stop_respawn():
	_active = false

func _process(delta):
	if not _active:
		return
	
	_timer += delta
	if _timer >= check_interval:
		_timer = 0
		_check_respawn()

func _check_respawn():
	if not Global:
		return
	
	var alive = get_tree().get_nodes_in_group("butterflies").size()
	
	if alive < min_butterflies:
		var needed = min_butterflies - alive
		_respawn_butterflies(needed)

func _respawn_butterflies(amount: int):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var flower = get_tree().get_first_node_in_group("sacred_flower")
	
	for i in range(amount):
		var spawn_pos = _get_spawn_position(player, flower)
		var butterfly = butterfly_scene.instantiate()
		butterfly.global_position = spawn_pos
		butterfly.set("Global", Global)
		get_tree().current_scene.add_child(butterfly)
		Global.total_butterflies_spawned += 1
		Global.butterflies_alive += 1
		await get_tree().create_timer(0.3).timeout

func _get_spawn_position(player, flower):
	var angle = randf() * TAU
	var radius = randf_range(200, respawn_radius)
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * radius
	
	if flower:
		var dist_to_flower = pos.distance_to(flower.global_position)
		if dist_to_flower < 300:
			angle = fmod(angle + PI, TAU)
			pos = player.global_position + Vector2(cos(angle), sin(angle)) * radius
	
	return pos	
