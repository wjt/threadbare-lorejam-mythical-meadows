#juego2.gd
extends Node2D

const DIALOGUE_RESOURCE = preload("res://scenes/quests/lore_quests/quest_004/Juego2/juego2.dialogue")

var butterfly_scene: PackedScene

@onready var player = $PlayerLight

func _ready():
	butterfly_scene = load("res://scenes/quests/lore_quests/quest_004/Juego2/butterfly.tscn")
	
	# Congelar TODO
	_congelar_todo(true)
	
	await get_tree().create_timer(0.5).timeout
	_mostrar_dialogos()

func _congelar_todo(congelar: bool):
	# Congelar/Descongelar jugador
	if player:
		player.set_physics_process(not congelar)
		if congelar:
			player.velocity = Vector2.ZERO
	
	# Congelar/Descongelar mariposas
	for butterfly in get_tree().get_nodes_in_group("butterflies"):
		butterfly.set_physics_process(not congelar)
	
	# Congelar/Descongelar murciélagos
	for bat in get_tree().get_nodes_in_group("predators"):
		bat.set_physics_process(not congelar)

func _mostrar_dialogos():
	DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "inicio_personaje")
	await DialogueManager.dialogue_ended
	
	DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "inicio_juego")
	await DialogueManager.dialogue_ended
	
	# Descongelar TODO
	_congelar_todo(false)
	
