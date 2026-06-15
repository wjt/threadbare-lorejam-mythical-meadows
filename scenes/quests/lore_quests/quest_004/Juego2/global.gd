
extends Node

var player_light_position: Vector2 = Vector2.ZERO
var lantern_energy: float = 100.0
var max_lantern_energy: float = 100.0
var is_lantern_active: bool = true
var energy_drain_rate: float = 3.0
var total_butterflies_spawned: int = 0
var butterflies_alive: int = 0
var butterflies_saved: int = 0

func _ready():
	_reset_game_state()

func _reset_game_state():
	lantern_energy = max_lantern_energy
	is_lantern_active = true
	total_butterflies_spawned = 0
	butterflies_alive = 0
	butterflies_saved = 0

func consume_energy(delta: float) -> void:
	if not is_lantern_active:
		return
	lantern_energy -= energy_drain_rate * delta
	if lantern_energy <= 0:
		lantern_energy = 0
		is_lantern_active = false

func recharge_energy(amount: float) -> void:
	lantern_energy = min(max_lantern_energy, lantern_energy + amount)
	if not is_lantern_active and lantern_energy > 0:
		is_lantern_active = true
