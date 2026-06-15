# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var target_scene: PackedScene
@export var player_group: String = "player"
@export var one_shot: bool = true

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered and one_shot:
		return

	if not body.is_in_group(player_group):
		return

	if target_scene == null:
		push_warning("TeleportArea: no se asignó 'target_scene' en el inspector")
		return

	_triggered = true
	get_tree().change_scene_to_packed(target_scene)
