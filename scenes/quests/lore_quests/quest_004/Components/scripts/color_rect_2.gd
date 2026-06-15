extends ColorRect

@export var max_force: float = 0.05
@export var duration: float = 0.4
@export var player_path: NodePath

var _tween: Tween
var _material: ShaderMaterial
var _player: Node2D
var _is_playing: bool = false  

@export var wave_frequency: float = 20.0
@export var chroma_split: float = 0.008

func _ready() -> void:
	_material = material as ShaderMaterial
	_player = get_node(player_path)


func _process(_delta: float) -> void:
	if _player:
		_update_center()
	
	if Input.is_action_just_pressed("repel") and not _is_playing:
		_play_distortion()


func _update_center() -> void:
	var player_screen: Vector2 = _player.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport_rect().size
	var uv_pos: Vector2 = player_screen / viewport_size
	_material.set_shader_parameter("center", uv_pos)



func _play_distortion() -> void:
	_is_playing = true
	_material.set_shader_parameter("wave_frequency", wave_frequency)
	_material.set_shader_parameter("chroma_split", chroma_split)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(
		func(v): _material.set_shader_parameter("force", v),
		0.0, max_force, duration * 0.2
	)
	_tween.tween_method(
		func(v): _material.set_shader_parameter("force", v),
		max_force, 0.0, duration * 0.8
	)
	_tween.tween_callback(func(): _is_playing = false)
