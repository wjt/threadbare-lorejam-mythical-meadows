extends Node2D

@export var piano_offset: Vector2 = Vector2(0, -80)
@export var ability_duration: float = 10.0
@export var projectile_scene: PackedScene
@onready var activate_sound: AudioStreamPlayer2D = $ActivateSound
var player: Node2D
var piano_active: bool = false
var detected_enemies: Array[Node2D] = []


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	show_piano_hud()
	visible = false
	$AnimatedSprite2D.play("idle")
	player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	if player and piano_active:
		global_position = player.global_position + piano_offset


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		activate_piano()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot_to_marked_enemies()


func activate_piano() -> void:
	if piano_active:
		return
	
	piano_active = true
	visible = true
	activate_sound.play()
	
	await get_tree().create_timer(ability_duration).timeout
	
	piano_active = false
	visible = false
	detected_enemies.clear()


func shoot_to_marked_enemies() -> void:
	if not piano_active:
		return
	
	if projectile_scene == null:
		print("Falta asignar la escena del proyectil")
		return
	
	detected_enemies = detected_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	if detected_enemies.is_empty():
		print("No hay enemigos marcados")
		return
	
	for enemy in detected_enemies:
		var projectile = projectile_scene.instantiate()
		projectile.global_position = $Marker2D.global_position
		projectile.target = enemy
		get_tree().current_scene.add_child(projectile)
	
	print("Piano disparó a enemigos marcados")


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if not body in detected_enemies:
			detected_enemies.append(body)
			print("Enemigo marcado:", body.name)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body in detected_enemies:
		detected_enemies.erase(body)
		print("Enemigo salió del área:", body.name)
		
func show_piano_hud() -> void:
	var hud = get_tree().current_scene.get_node_or_null("CanvasLayer/PianoSkillHUD")

	if hud:
		hud.show_piano_message()
