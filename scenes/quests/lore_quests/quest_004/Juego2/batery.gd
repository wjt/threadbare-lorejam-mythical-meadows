#batery

extends Area2D

@export var recharge_amount: float = 40.0
@export var respawn_time: float = 6.0

var _collected: bool = false
var _initial_position: Vector2

func _ready():
	_initial_position = global_position
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if _collected:
		return
	if body.is_in_group("player") and body.has_method("recharge"):
		_collected = true
		body.recharge(recharge_amount)
		visible = false
		$CollisionShape2D.disabled = true
		await get_tree().create_timer(respawn_time).timeout
		_collected = false
		visible = true
		$CollisionShape2D.disabled = false
