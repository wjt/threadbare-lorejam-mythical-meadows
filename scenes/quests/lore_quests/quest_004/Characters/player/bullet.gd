extends Area2D

@export var speed: float = 350.0
@export var damage: float = 25.0
@export var pierce_limit: int = 1

var direction: Vector2 = Vector2.ZERO
var enemies_hit: int = 0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * speed * delta

		# Rota la imagen para que la aguja apunte hacia donde viaja
		sprite.rotation = direction.angle() + deg_to_rad(270)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		enemies_hit += 1
		
		if enemies_hit >= pierce_limit:
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		return
	
	if area.is_in_group("enemies"):
		var target = area.get_parent()
		
		if target and target.has_method("take_damage"):
			target.take_damage(damage)
		
		enemies_hit += 1
		
		if enemies_hit >= pierce_limit:
			queue_free()
