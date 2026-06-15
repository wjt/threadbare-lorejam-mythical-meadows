# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Node2D

class_name CarryableRock
@export var despawn_time := 5.0
@export var interact_area: InteractArea
@export var carry_offset := Vector2(0, -24)
@export var throw_speed := 500.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var carried := false
var thrown := false
var destroying := false

var carrier: Node2D = null
var direction := Vector2.ZERO


func _ready() -> void:
	add_to_group("rock")

	if sprite != null:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

	if interact_area:
		interact_area.interaction_started.connect(_on_interaction_started)


func _process(delta: float) -> void:

	if destroying:
		return

	if carried and carrier:
		global_position = carrier.global_position + carry_offset

	elif thrown:
		global_position += direction * throw_speed * delta


func _input(event) -> void:

	if not carried:
		return

	# CLICK IZQUIERDO
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			throw()


func _on_interaction_started(player, _from_right) -> void:
	if carried:
		return

	_pickup(player)
	interact_area.end_interaction()


func _pickup(player) -> void:
	carried = true
	carrier = player

	if sprite != null:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")


func throw() -> void:
	if carrier == null:
		return

	carried = false
	thrown = true

	# dirección hacia el mouse
	var mouse_pos := get_global_mouse_position()
	direction = (mouse_pos - global_position).normalized()

	carrier = null

	# destruir después de 5 segundos si no golpeó nada
	_start_despawn_timer()

func _on_area_2d_body_entered(body) -> void:
	_hit(body)
func _start_despawn_timer() -> void:
	await get_tree().create_timer(despawn_time).timeout

	if destroying:
		return

	if thrown:
		_destroy()


func _on_area_2d_area_entered(area) -> void:
	_hit(area.get_parent())


func _destroy() -> void:
	destroying = true
	thrown = false

	if sprite != null:
		if sprite.sprite_frames.has_animation("destroy"):
			sprite.play("destroy")
			await sprite.animation_finished

	queue_free()
func _hit(target) -> void:

	if not thrown:
		return

	if destroying:
		return

	if target == null:
		return

	if target.has_method("take_damage"):
		target.take_damage(5)

	_destroy()
