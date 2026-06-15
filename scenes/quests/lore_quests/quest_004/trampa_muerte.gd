# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var slime_jefe: Node2D
@export var agujero: Marker2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": 
		if is_instance_valid(slime_jefe) and slime_jefe.has_method("iniciar_muerte"):
			slime_jefe.iniciar_muerte(agujero.global_position)
			queue_free()
