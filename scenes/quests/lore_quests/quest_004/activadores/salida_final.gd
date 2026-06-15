# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D


func _ready() -> void:
	# Al ser la salida final directa, nos aseguramos de que empiece activa y escuchando físicas
	monitoring = true
	monitorable = true

	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false

	print("[SISTEMA] Hilo de Salida Final listo y activo desde el inicio.")
