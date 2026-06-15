#sacred_flower

extends Area2D

@export var max_energy: float = 100.0
@export var energy_per_butterfly: float = 10.0
@export var victory_screen_scene: PackedScene

var current_energy: float = 0.0
var butterflies_saved: int = 0
var game_finished: bool = false

@onready var point_light = $PointLight2D
@onready var glow_sprite = $GlowSprite

func _ready():
	add_to_group("sacred_flower")
	if has_node("ProgressBar"):
		$ProgressBar.max_value = max_energy
		$ProgressBar.value = 0
	body_entered.connect(_on_body_entered)
	_update_brightness(0)

func _update_brightness(percentage: float):
	# Luz
	if point_light:
		point_light.energy = 0.3 + (percentage * 1.5)
		if percentage < 0.3:
			point_light.color = Color(1, 0.5, 0.2)
		elif percentage < 0.7:
			point_light.color = Color(1, 0.8, 0.3)
		else:
			point_light.color = Color(1, 1, 0.8)
	
	# Glow
	if glow_sprite:
		var scale_val = 0.8 + (percentage * 1.2)
		glow_sprite.scale = Vector2(scale_val, scale_val)
		glow_sprite.modulate.a = 0.3 + (percentage * 0.7)

func _flash_effect():
	var tween = create_tween()
	if point_light:
		var original = point_light.energy
		tween.tween_property(point_light, "energy", original * 1.5, 0.05)
		tween.tween_property(point_light, "energy", original, 0.3)

func _on_body_entered(body: Node2D):
	if game_finished:
		return
	if not body.is_in_group("butterflies"):
		return
	
	current_energy += energy_per_butterfly
	current_energy = min(current_energy, max_energy)
	butterflies_saved += 1
	
	if has_node("ProgressBar"):
		$ProgressBar.value = current_energy
	
	var percentage = current_energy / max_energy
	_update_brightness(percentage)
	_flash_effect()
	
	body.die()
	
	if current_energy >= max_energy and not game_finished:
		_win()

func _win():
	game_finished = true
	_update_brightness(1.0)
	if victory_screen_scene:
		var victory = victory_screen_scene.instantiate()
		get_tree().root.add_child(victory)
