# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var slime_jefe: Node2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if is_instance_valid(slime_jefe) and slime_jefe.has_method("desactivar_ataques"):
			slime_jefe.desactivar_ataques()
			
		queue_free()
