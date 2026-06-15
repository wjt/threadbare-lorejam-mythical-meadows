extends Node2D

const MAX_ROCKS := 6

@export var rock_scene: PackedScene
@export var arena: Area2D


func _ready() -> void:

	randomize()

	print("=== ROCK SPAWNER INICIADO ===")

	if arena == null:
		push_error("No asignaste Arena en el Inspector")
		return

	spawn_loop()


func spawn_loop() -> void:

	while true:

		await get_tree().create_timer(
			randf_range(3.0, 6.0)
		).timeout

		spawn_rock()

func spawn_rock() -> void:

	var rocks = get_tree().get_nodes_in_group("rock")

	if rocks.size() >= MAX_ROCKS:
		return

	if rock_scene == null:
		return

	var collision := arena.get_node_or_null("CollisionShape2D")
	if collision == null:
		return

	var shape = collision.shape
	if not shape is RectangleShape2D:
		return

	var rect_shape: RectangleShape2D = shape
	var half_size := rect_shape.size * 0.5

	var spawn_pos := Vector2.ZERO
	var encontrada := false

	for intento in range(30):

		var local_pos := Vector2(
			randf_range(-half_size.x + 50, half_size.x - 50),
			randf_range(-half_size.y + 50, half_size.y - 50)
		)

		# convertir a mundo correctamente (respeta rotación y posición)
		spawn_pos = collision.global_position + local_pos.rotated(collision.global_rotation)

		var valido := true

		for rock in rocks:
			if spawn_pos.distance_to(rock.global_position) < 120.0:
				valido = false
				break

		if valido:
			encontrada = true
			break

	if not encontrada:
		return

	var nueva_roca = rock_scene.instantiate()
	get_tree().current_scene.add_child(nueva_roca)
	nueva_roca.global_position = spawn_pos

	print("Roca creada en: ", spawn_pos)
