# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CharacterRandomizer

## Dialogue to play when the player interacts with this NPC.
@export var dialogue: DialogueResource:
	set(new_value):
		dialogue = new_value
		if talk_behavior:
			talk_behavior.dialogue = new_value

## Title of [member dialogue] to play when the player interacts with this NPC.
@export var dialogue_title: StringName = &"start":
	set(new_value):
		dialogue_title = new_value
		if talk_behavior:
			talk_behavior.title = dialogue_title


# --- EFECTO DE FLOTAR ---
@export_group("Ghost Float")
@export var float_height: float = 5.0
@export var float_speed: float = 2.0

@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: TalkBehavior = %TalkBehavior
@onready var sprite: Sprite2D = $Sprite2D

var sprite_start_y: float = 0.0
var float_time: float = 0.0


func _ready() -> void:
	dialogue = dialogue
	dialogue_title = dialogue_title
	
	if sprite:
		sprite_start_y = sprite.position.y


func _process(delta: float) -> void:
	if not sprite:
		return
	
	float_time += delta * float_speed
	sprite.position.y = sprite_start_y + sin(float_time) * float_height
