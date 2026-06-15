# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var dialogo_final: DialogueResource
@export var npc_1: Node2D
@export var npc_2: Node2D
@export var npc_3: Node2D
@export var npc_4: Node2D

@export var pos_1: Marker2D
@export var pos_2: Marker2D
@export var pos_3: Marker2D
@export var pos_4: Marker2D

var cinematica_jugada: bool = false
var jugador_guardado: CharacterBody2D = null 

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not cinematica_jugada:
		cinematica_jugada = true
		
		jugador_guardado = body as CharacterBody2D
		if jugador_guardado:
			jugador_guardado.velocity = Vector2.ZERO
			
			var sprite = jugador_guardado.get_node_or_null("AnimatedSprite2D")
			if sprite:
				sprite.play("idle")
				sprite.frame = 0
				
			var anim_player = jugador_guardado.get_node_or_null("AnimationPlayer")
			if anim_player and anim_player.has_animation("idle"):
				anim_player.play("idle")
				anim_player.seek(0.0, true)
				
			jugador_guardado.process_mode = Node.PROCESS_MODE_DISABLED
		
		if is_instance_valid(npc_1): npc_1.global_position = pos_1.global_position
		if is_instance_valid(npc_2): npc_2.global_position = pos_2.global_position
		if is_instance_valid(npc_3): npc_3.global_position = pos_3.global_position
		if is_instance_valid(npc_4): npc_4.global_position = pos_4.global_position

		if is_instance_valid(dialogo_final):
			DialogueManager.show_dialogue_balloon(dialogo_final, "start", [self])

func desaparecer_npcs() -> void:
	if is_instance_valid(jugador_guardado):
		jugador_guardado.process_mode = Node.PROCESS_MODE_INHERIT
		
	if is_instance_valid(npc_1): npc_1.queue_free()
	if is_instance_valid(npc_2): npc_2.queue_free()
	if is_instance_valid(npc_3): npc_3.queue_free()
	if is_instance_valid(npc_4): npc_4.queue_free()
	
	queue_free() 
