extends Node2D

var Global

@onready var sacred_flower = $SacredFlower
@onready var player_light = $PlayerLight

func _ready():
	var GlobalScript = load("res://scenes/quests/lore_quests/quest_004/Juego2/global.gd")
	Global = GlobalScript.new()
	add_child(Global)
	
	Global.lantern_energy = 100
	Global.is_lantern_active = true
	
	if sacred_flower:
		sacred_flower.set_global_reference(Global)
	if player_light:
		player_light.set_global_reference(Global)
	
	var zones = get_tree().get_nodes_in_group("butterfly_zones")
	for zone in zones:
		if zone.has_method("set_global_reference"):
			zone.set_global_reference(Global)
