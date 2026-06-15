extends Area2D

@export var xp_value: int = 1
@export var magnet_speed: float = 320.0
@export var global_magnet_speed: float = 900.0

@export_enum("xp", "magnet", "heal") var pickup_type: String = "xp"

var player: Node2D = null

var global_magnet_active := false
var global_magnet_target: Node2D = null

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var magnet_texture: Texture2D = preload("res://scenes/quests/lore_quests/quest_004/assets/images/Iman.png")
var heal_texture: Texture2D = preload("res://scenes/quests/lore_quests/quest_004/assets/images/PolloCura.png")

func _ready() -> void:
	add_to_group("gems")
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	update_visual()


func _process(delta: float) -> void:
	if global_magnet_active and global_magnet_target:
		global_position = global_position.move_toward(
			global_magnet_target.global_position,
			global_magnet_speed * delta
		)
		return
	
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	if "magnet_radius" in player:
		var distance_to_player = global_position.distance_to(player.global_position)

		if distance_to_player <= player.magnet_radius:
			global_position = global_position.move_toward(
				player.global_position,
				magnet_speed * delta
			)


func update_visual() -> void:
	if not sprite:
		return
	
	match pickup_type:
		"xp":
			modulate = Color(1, 1, 1, 1)
			scale = Vector2(1, 1)
		
		"magnet":
			sprite.texture = magnet_texture
			modulate = Color(1, 1, 1, 1)
			scale = Vector2(0.35, 0.35)
		
		"heal":
			sprite.texture = heal_texture
			modulate = Color(1, 1, 1, 1)
			scale = Vector2(0.35, 0.35)


func activate_global_magnet(target: Node2D, speed: float) -> void:
	global_magnet_active = true
	global_magnet_target = target
	global_magnet_speed = speed


func activate_all_gems(player_body: Node2D) -> void:
	var gems = get_tree().get_nodes_in_group("gems")
	
	for gem in gems:
		if gem != self and is_instance_valid(gem):
			if gem.has_method("activate_global_magnet"):
				gem.activate_global_magnet(player_body, global_magnet_speed)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	match pickup_type:
		"xp":
			print("Recogiste XP")
			if body.has_method("gain_xp"):
				body.gain_xp(xp_value)
			else:
				print("ERROR: El player no tiene gain_xp()")
		
		"magnet":
			print("Recogiste imán")
			activate_all_gems(body)
		
		"heal":
			print("Recogiste pollo cura")
			print("Tiene heal_to_full?: ", body.has_method("heal_to_full"))

			if body.has_method("heal_to_full"):
				body.heal_to_full()
			else:
				print("ERROR: El player no tiene heal_to_full()")
	
	queue_free()
