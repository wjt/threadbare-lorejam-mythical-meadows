extends CharacterBody2D

@onready var player_battle_health: Node = get_tree().current_scene.get_node("PlayerBattleHealth")

@export var chase_speed: float = 120.0
@export var stop_distance: float = 75.0
@export var attack_cooldown: float = 1.0

@export var repel_force: float = 450.0
@export var repel_time: float = 0.25
@export var stun_time: float = 0.6

var is_repelled: bool = false
var repel_velocity: Vector2 = Vector2.ZERO

@export var max_health: int = 3
var health: int 

@onready var health_bar: ProgressBar = $HealthBar


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $DamageArea

var player_in_damage_area: bool = false
var player: Player = null
var player_fighting: Node = null
var is_chasing: bool = false
var can_attack: bool = true
var is_attacking: bool = false



func _ready() -> void:
	add_to_group("enemy")
	add_to_group("repellable")
	print("ENEMIGO SCRIPT FUNCIONANDO")
	
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)

	sprite.play("idle")


func _physics_process(_delta: float) -> void:
	if is_repelled:
		velocity = repel_velocity
		move_and_slide()
		return
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_chasing and is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)

		if distance <= stop_distance:
			velocity = Vector2.ZERO
			move_and_slide()

			if can_attack:
				sprite.play("alerted")

			return

		var direction := global_position.direction_to(player.global_position)
		velocity = direction * chase_speed
		move_and_slide()

		if sprite.animation != "walk":
			sprite.play("walk")

		sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		move_and_slide()

		if sprite.animation != "idle":
			sprite.play("idle")


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		player = body as Player
		player_fighting = null

		is_chasing = true
		sprite.play("alerted")
		print("Jugador detectado")

		if player_fighting:
			print("PlayerFighting encontrado")
		else:
			print("No se encontró PlayerFighting")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		is_chasing = false
		print("Jugador salió del área")


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		player_in_damage_area = true
		_attack_player()

func _on_damage_area_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		player_in_damage_area = false

	
func _attack_player() -> void:
	if not can_attack:
		return

	if not player_in_damage_area:
		return

	can_attack = false
	is_attacking = true
	velocity = Vector2.ZERO
	move_and_slide()

	sprite.play("alerted")
	print("El enemigo atacó al jugador")

	if player_battle_health:
		player_battle_health.take_damage(1)

		if player_battle_health.health <= 0:
			return

	await get_tree().create_timer(attack_cooldown).timeout

	is_attacking = false
	can_attack = true

	if player_in_damage_area:
		_attack_player()		

func repel_from(source_position: Vector2) -> void:
	is_repelled = true
	is_attacking = false
	can_attack = false
	player_in_damage_area = false

	var direction := source_position.direction_to(global_position)
	repel_velocity = direction * repel_force

	sprite.play("alerted")
	print("Enemigo repelido")

	await get_tree().create_timer(repel_time).timeout

	repel_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	move_and_slide()

	await get_tree().create_timer(stun_time).timeout

	is_repelled = false
	can_attack = true

func defeat() -> void:
	print("Enemigo especial derrotado")

	var boss: Node = get_tree().get_first_node_in_group("boss")
	print("Boss encontrado:", boss)

	if boss:
		boss.take_damage(1)

	queue_free()
	
func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return

	health -= amount

	if health < 0:
		health = 0

	health_bar.value = health
	print("Vida enemigo:", health)

	if health <= 0:
		defeat()
		
func got_repelled(direction: Vector2) -> void:
	is_repelled = true
	is_attacking = false
	can_attack = false
	player_in_damage_area = false

	repel_velocity = direction * repel_force

	sprite.play("alerted")
	take_damage(1)
	print("Enemigo repelido por PlayerRepel")

	await get_tree().create_timer(repel_time).timeout

	repel_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	move_and_slide()

	await get_tree().create_timer(stun_time).timeout

	is_repelled = false
	can_attack = true


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.name == "AirStream":
		print("El enemigo recibió daño del repel")
		take_damage(1)
