# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var animation=$GemaAzul

# Called when the node enters the scene tree for the first time.
func _ready() :
	animation.play("gema")
