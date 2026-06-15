# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D




var boss_lives := 3

func _ready():

	GameState.current_lives = boss_lives

func player_dead() -> void:

	GameState.current_lives -= 1

	print("Intentos restantes: ", GameState.current_lives)

	if GameState.current_lives <= 0:

		print("PERDISTE")

		# Aquí muestras derrota,
		# vuelves al mapa,
		# reinicias el jefe, etc.
