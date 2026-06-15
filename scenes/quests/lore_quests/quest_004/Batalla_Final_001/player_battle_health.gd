extends Node

@export var max_health: int = 5
var health: int

@onready var health_bar: ProgressBar = $"../CanvasLayer/PlayerHealthBar"

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	print("Vida jugador:", health)

func take_damage(amount: int = 1) -> void:
	health -= amount

	CameraShake.shake()

	if health < 0:
		health = 0

	health_bar.value = health
	print("Vida jugador:", health)

	if health <= 0:
		print("Jugador derrotado")

		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.mode = player.Mode.DEFEATED

		await get_tree().create_timer(2.0).timeout

		if is_inside_tree():
			get_tree().reload_current_scene()
			
func heal(amount: int = 1) -> void:
	health += amount

	if health > max_health:
		health = max_health

	health_bar.value = health

	# Brillo verde temporal
	health_bar.modulate = Color(0.4, 1.0, 0.4)

	await get_tree().create_timer(1.0).timeout

	health_bar.modulate = Color.WHITE
