extends Node2D

@export var enemies: Array[Node2D] = []

@export_group("Tiempos de teletransporte")
@export var interval_min: float = 3.0
@export var interval_max: float = 6.0

@export_group("Efecto (opcional)")
@export var fade_duration: float = 0.15

var points: Array[Marker2D] = []
var timers: Array[float] = []
var occupied_points: Array = []

func _ready() -> void:
	for child in get_children():
		if child is Marker2D:
			points.append(child)

	occupied_points.resize(enemies.size())
	timers.resize(enemies.size())

	for i in range(enemies.size()):
		occupied_points[i] = null
		timers[i] = randf_range(0.0, interval_max)

func _process(delta: float) -> void:
	if points.is_empty():
		return

	for i in range(enemies.size()):
		var enemy = enemies[i]

		# Enemigo muerto/eliminado: libera su punto y no hace nada más
		if not is_instance_valid(enemy):
			occupied_points[i] = null
			continue

		timers[i] -= delta
		if timers[i] <= 0.0:
			_teleport_enemy(i)
			timers[i] = randf_range(interval_min, interval_max)

func _teleport_enemy(index: int) -> void:
	var enemy = enemies[index]
	if not is_instance_valid(enemy):
		return

	var point := _pick_point(index)
	occupied_points[index] = point

	if fade_duration > 0.0:
		var tween := create_tween()
		tween.tween_property(enemy, "modulate:a", 0.0, fade_duration)
		tween.tween_callback(func():
			if is_instance_valid(enemy):
				enemy.global_position = point.global_position
		)
		tween.tween_property(enemy, "modulate:a", 1.0, fade_duration)
	else:
		enemy.global_position = point.global_position

func _pick_point(index: int) -> Marker2D:
	var blocked: Array = []
	for i in range(occupied_points.size()):
		if i != index and occupied_points[i] != null:
			blocked.append(occupied_points[i])

	var available: Array[Marker2D] = []
	for p in points:
		if not blocked.has(p) and p != occupied_points[index]:
			available.append(p)

	if available.is_empty():
		for p in points:
			if not blocked.has(p):
				available.append(p)
	if available.is_empty():
		available = points

	return available[randi() % available.size()]
