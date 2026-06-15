extends CharacterBody2D

@export var speed := 100.0
@export var tiempo_derrota := 2.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var hitbox: Area2D = $Area2D

var atacando := false

func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null:
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _on_body_entered(body: Node) -> void:
	if atacando:
		return

	if body.is_in_group("player"):
		atacando = true
		velocity = Vector2.ZERO

		var sprite = body.find_child("PlayerSprite", true, false)

		if sprite == null:
			sprite = body.find_child("AnimatedSprite2D", true, false)

		if sprite:
			sprite.animation = "defeated"
			sprite.frame = 0
			sprite.play()

		await get_tree().process_frame

		body.set_physics_process(false)
		body.set_process(false)

		await get_tree().create_timer(tiempo_derrota).timeout
		get_tree().reload_current_scene()
