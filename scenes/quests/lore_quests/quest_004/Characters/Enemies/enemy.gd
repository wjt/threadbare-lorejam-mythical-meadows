extends CharacterBody2D

@export var speed: float = 240.0
@export var damage: float = 10.0
@export var max_health: float = 50.0
var health: float

var player: Node2D
var gem_scene: PackedScene = preload("res://scenes/quests/lore_quests/quest_004/Characters/player/Gem.tscn")

@export_range(0.0, 1.0, 0.01) var magnet_drop_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var heal_drop_chance: float = 0.03

@onready var sprite: Node = get_node_or_null("Sprite2D")


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	$Area2D.body_entered.connect(_on_hurtbox_entered)

	# Si tu sprite no se llama Sprite2D, intenta encontrar AnimatedSprite2D
	if sprite == null:
		sprite = get_node_or_null("AnimatedSprite2D")


func _physics_process(_delta: float) -> void:
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

		update_facing_direction(direction)

		move_and_slide()


func update_facing_direction(direction: Vector2) -> void:
	if sprite == null:
		return

	# Solo cambia dirección si se mueve horizontalmente
	if abs(direction.x) > 0.05:
		sprite.flip_h = direction.x < 0


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	set_physics_process(false)
	$Area2D.set_deferred("monitoring", false)
	$Area2D.set_deferred("monitorable", false)
	
	drop_gem()
	queue_free()


func drop_gem() -> void:
	var gem = gem_scene.instantiate()
	gem.global_position = global_position
	
	var roll = randf()
	
	if roll < heal_drop_chance:
		gem.pickup_type = "heal"
	elif roll < heal_drop_chance + magnet_drop_chance:
		gem.pickup_type = "magnet"
	else:
		gem.pickup_type = "xp"
	
	get_tree().current_scene.call_deferred("add_child", gem)


func _on_hurtbox_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			die()
