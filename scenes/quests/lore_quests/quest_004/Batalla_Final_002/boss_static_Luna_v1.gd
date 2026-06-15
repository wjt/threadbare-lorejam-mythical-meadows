extends CharacterBody2D

@export var max_health: int = 20
var health: int
@export var defeat_dialogue: DialogueResource
@export var defeat_title: String = "start"
@onready var thunder_sound: AudioStreamPlayer2D = $ThunderSound
@export_file("*.tscn") var next_level: String
@export var use_transition: bool = true
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
@export var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE

var defeated: bool = false
@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var hit_flash_color: Color = Color(0.75, 0.25, 1.0, 1.0)
@export var shake_strength: float = 8.0
@export var shake_times: int = 6

func _ready() -> void:
	add_to_group("boss")
	
	print("BOSS ESTATICO FUNCIONANDO")
	
	health = max_health
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	if sprite:
		sprite.play("idle")


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return
	
	health -= amount
	
	if health < 0:
		health = 0
	
	if health_bar:
		health_bar.value = health
	
	print("Vida boss:", health)
	
	hit_effect()
	
	if health <= 0:
		defeat()


func defeat() -> void:
	if defeated:
		return

	defeated = true
	print("Boss derrotado")
	
	if thunder_sound:
		thunder_sound.play()

	await get_tree().create_timer(0.15).timeout
		
	var flash = get_tree().current_scene.get_node("CanvasLayer/ColorRect")

	for i in 3:
		flash.visible = true
		await get_tree().create_timer(0.08).timeout

		flash.visible = false
		await get_tree().create_timer(0.08).timeout

	await get_tree().create_timer(0.25).timeout
	
	get_tree().call_group("boss_spawner", "stop_spawning")

	await get_tree().process_frame

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	# Detiene al jugador
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("take_control"):
			player.take_control(self)

		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO

	if defeat_dialogue:
		DialogueManager.show_dialogue_balloon(defeat_dialogue, defeat_title, [self, player])
		await DialogueManager.dialogue_ended

	if next_level != "":
		if use_transition:
			SceneSwitcher.change_to_file_with_transition.call_deferred(
				next_level,
				^"",
				enter_transition,
				exit_transition
			)
		else:
			get_tree().call_deferred("change_scene_to_file", next_level)
		return

	queue_free()
	
func hit_effect() -> void:
	if not sprite:
		return

	var original_position: Vector2 = sprite.position
	var original_modulate: Color = sprite.modulate

	sprite.modulate = hit_flash_color

	for i in shake_times:
		var direction := -1 if i % 2 == 0 else 1
		sprite.position = original_position + Vector2(direction * shake_strength, 0)
		await get_tree().create_timer(0.04).timeout

	sprite.position = original_position
	sprite.modulate = original_modulate
