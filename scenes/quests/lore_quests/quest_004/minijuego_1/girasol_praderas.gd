# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

@tool
extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var hide_player: AudioStreamPlayer2D = $HideSound
@onready var reveal_player: AudioStreamPlayer2D = $RevealSound

var player_near := false


func _ready() -> void:
	animated_sprite_2d.play(&"idle_sad")


func _reveal() -> void:
	if player_near:
		return

	player_near = true

	animated_sprite_2d.visible = true
	animated_sprite_2d.play(&"reveal")
	reveal_player.play()

	await animated_sprite_2d.animation_finished

	# si el jugador sigue cerca, pasa a feliz
	if player_near:
		animated_sprite_2d.play(&"idle_happy")


func _hide() -> void:
	if not player_near:
		return

	player_near = false

	animated_sprite_2d.play(&"hide")
	hide_player.play()

	await animated_sprite_2d.animation_finished

	# si el jugador ya no está, vuelve a triste
	if not player_near:
		animated_sprite_2d.play(&"idle_sad")


func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_reveal()


func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_hide()
