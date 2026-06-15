extends ColorRect

@export var max_force: float = 0.05
@export var duration: float = 0.4
@export var wave_frequency: float = 20.0
@export var chroma_split: float = 0.008
@export var player_path: NodePath
@export var normal_nodes: Array[Node2D] = []
@export var hidden_nodes: Array[Node2D] = []

@export_group("Auto Revert")
@export var auto_revert: bool = true
@export var auto_revert_time: float = 3.0
## Fuerza del shader al volver al modo normal
@export var revert_max_force: float = 0.08
## Separacion de colores al volver al modo normal
@export var revert_chroma_split: float = 0.015
## Frecuencia de onda al volver al modo normal
@export var revert_wave_frequency: float = 30.0

var _tween: Tween
var _revert_timer: Timer
var _material: ShaderMaterial
var _player: Node2D
var _is_playing: bool = false
var _vision_active: bool = false


func _ready() -> void:
	_material = material as ShaderMaterial
	_player = get_node(player_path)
	for node in hidden_nodes:
		node.visible = false

	_revert_timer = Timer.new()
	_revert_timer.one_shot = true
	_revert_timer.timeout.connect(_on_revert_timer_timeout)
	add_child(_revert_timer)


func _process(_delta: float) -> void:
	if _player:
		_update_center()

	if Input.is_action_just_pressed("repel") and not _is_playing:
		if _vision_active:
			_revert_timer.stop()
			_toggle_vision()
		else:
			_toggle_vision()


func _update_center() -> void:
	var player_screen: Vector2 = _player.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport_rect().size
	var uv_pos: Vector2 = player_screen / viewport_size
	_material.set_shader_parameter("center", uv_pos)


func _toggle_vision(is_reverting: bool = false) -> void:
	_vision_active = !_vision_active
	for node in normal_nodes:
		node.visible = !_vision_active
	for node in hidden_nodes:
		node.visible = _vision_active
	_play_distortion(is_reverting)

	if _vision_active and auto_revert:
		_revert_timer.start(auto_revert_time)
	else:
		_revert_timer.stop()


func _on_revert_timer_timeout() -> void:
	if not _is_playing:
		_toggle_vision(true)
	else:
		await _tween.finished
		_toggle_vision(true)


func _play_distortion(is_reverting: bool = false) -> void:
	_is_playing = true

	# Usa valores de revert o valores normales segun el caso
	var target_force := revert_max_force if is_reverting else max_force
	var target_chroma := revert_chroma_split if is_reverting else chroma_split
	var target_frequency := revert_wave_frequency if is_reverting else wave_frequency

	_material.set_shader_parameter("wave_frequency", target_frequency)
	_material.set_shader_parameter("chroma_split", target_chroma)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(
		func(v): _material.set_shader_parameter("force", v),
		0.0, target_force, duration * 0.2
	)
	_tween.tween_method(
		func(v): _material.set_shader_parameter("force", v),
		target_force, 0.0, duration * 0.8
	)
	_tween.tween_callback(func(): _is_playing = false)
