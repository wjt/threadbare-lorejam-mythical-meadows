# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

# Estados lógicos del enemigo
enum State { IDLE, CHASE, PREPARE, DASH, COOLDOWN }
var current_state: State = State.IDLE

@export_group("Movimiento y Rangos")
@export var speed: float = 90.0  # Velocidad normal de persecución
@export var dash_speed: float = 450.0  # Velocidad del lanzamiento furioso
@export var detection_range: float = 300.0  # Qué tan cerca debes estar para que te persiga
@export var attack_range: float = 140.0  # Distancia límite para empezar el Dash

var player: Player = null
var dash_direction: Vector2 = Vector2.ZERO
var esta_muerto: bool = false

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Player

	hitbox.body_entered.connect(_on_hitbox_body_entered)
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# ─── CLAVE: Apagamos el daño al inicio (no hace daño al perseguir) ───
	hitbox.monitoring = false


func _physics_process(delta: float) -> void:
	if esta_muerto or Engine.is_editor_hint() or not is_instance_valid(player):
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			if distance_to_player <= detection_range:
				current_state = State.CHASE

		State.CHASE:
			velocity = direction * speed
			if distance_to_player <= attack_range:
				current_state = State.PREPARE
				_iniciar_anticipacion(direction)
			elif distance_to_player > detection_range:
				current_state = State.IDLE

		State.PREPARE:
			velocity = Vector2.ZERO

		State.DASH:
			velocity = dash_direction * dash_speed

		State.COOLDOWN:
			velocity = velocity.move_toward(Vector2.ZERO, speed * 2.0 * delta)

	move_and_slide()


func _iniciar_anticipacion(target_direction: Vector2) -> void:
	dash_direction = target_direction

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.3)

	# Tiempo de espera cargando el ataque (mientras parpadea en rojo)
	await get_tree().create_timer(0.4).timeout

	if is_instance_valid(player) and not esta_muerto:
		current_state = State.DASH

		# ─── CLAVE: Encendemos el daño justo cuando sale disparado ───
		hitbox.set_deferred("monitoring", true)

		await get_tree().create_timer(0.25).timeout
		_terminar_dash()


func _terminar_dash() -> void:
	if esta_muerto:
		return

	# ─── CLAVE: Apagamos el daño inmediatamente al terminar la embestida ───
	hitbox.set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

	current_state = State.COOLDOWN
	cooldown_timer.start()


func _on_cooldown_timer_timeout() -> void:
	if current_state == State.COOLDOWN and not esta_muerto:
		current_state = State.IDLE


# --- CONEXIÓN DE DAÑO FÍSICO AL JUGADOR ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if esta_muerto:
		return

	# Doble validación estricta por código: sólo si está activamente en DASH
	if body.has_method("defeat") and current_state == State.DASH:
		print("[COMBATE] ¡El enemigo embistió con éxito al Jugador!")
		body.defeat()


# --- DETECCIÓN DE DAÑO RECIBIDO POR CUERPO ---
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if esta_muerto:
		return
	if body is Player:
		if body.player_sprite.animation in [&"attack_01", &"attack_02"]:
			morir()


# --- DETECCIÓN DE DAÑO RECIBIDO POR ÁREA (ESPADA) ---
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if esta_muerto:
		return
	if area.name.contains("Attack") or area.name.contains("Sword") or area.get_parent() is Player:
		if (
			is_instance_valid(player)
			and player.player_sprite.animation in [&"attack_01", &"attack_02"]
		):
			morir()


func morir() -> void:
	esta_muerto = true
	velocity = Vector2.ZERO
	print("[COMBATE] ¡Enemigo derrotado por la espada del jugador!")

	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation_degrees", 360.0, 0.4)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)

	await tween.finished
	queue_free()
