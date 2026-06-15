#butterfly_zone


extends Area2D

@export var butterfly_scene: PackedScene
@export var spawn_count: int = 5
@export var spawn_radius: float = 100.0

var _has_spawned: bool = false

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	if not _has_spawned and butterfly_scene:
		_has_spawned = true
		call_deferred("_spawn_butterflies")

func _spawn_butterflies():
	for i in range(spawn_count):
		var angle = randf() * TAU
		var dist = randf_range(50, spawn_radius)
		var pos = global_position + Vector2(cos(angle), sin(angle)) * dist
		var butterfly = butterfly_scene.instantiate()
		butterfly.global_position = pos
		get_parent().call_deferred("add_child", butterfly)
		await get_tree().create_timer(0.15).timeout
