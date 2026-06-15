# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		
		var nivel = get_tree().current_scene
		
		var slime_encontrado = nivel.find_child("Slime", true, false)
		
		if is_instance_valid(slime_encontrado) and slime_encontrado.has_method("activar_furia"):
			slime_encontrado.activar_furia()
			queue_free()
		else:
			print("¡ERROR: El radar de la zona no encontró al Slime")
