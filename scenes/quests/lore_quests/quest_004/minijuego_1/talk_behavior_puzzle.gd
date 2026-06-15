@tool
class_name TalkBehaviorPuzzle
extends Node

@export var dialogue: DialogueResource
@export var title: String = ""

@export var interact_area: InteractArea
@export var canvas_mapa: CanvasLayer
@export var puzzle: Node2D
@export var tiempo_mostrar: float = 5.0

var puede_interactuar: bool = true


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	add_to_group("talk_puzzle")
	interact_area.interaction_started.connect(_on_interaction_started)


# Llamar a esta función solamente cuando el jugador pierda
func activar_reintento() -> void:
	puede_interactuar = true

	interact_area.monitoring = true
	interact_area.monitorable = true


func _on_interaction_started(player: Node, _from_right: bool) -> void:
	if not puede_interactuar:
		interact_area.end_interaction()
		return

	puede_interactuar = false

	interact_area.monitoring = false
	interact_area.monitorable = false

	DialogueManager.show_dialogue_balloon(
		dialogue,
		title,
		[get_parent(), player, {}]
	)

	await DialogueManager.dialogue_ended
	await mostrar_solucion()

	if puzzle and puzzle.has_method("iniciar_puzzle"):
		puzzle.iniciar_puzzle()

	interact_area.end_interaction()


func mostrar_solucion() -> void:
	if canvas_mapa == null or puzzle == null:
		return

	canvas_mapa.visible = true

	var contenedor: Control = canvas_mapa.get_node_or_null("ContenedorSolucion")
	var label_cuenta: Label = canvas_mapa.get_node_or_null("LabelCuentaAtras")

	if contenedor == null or label_cuenta == null:
		push_error("No se encontró ContenedorSolucion o LabelCuentaAtras")
		return

	for hijo: Node in contenedor.get_children():
		hijo.queue_free()

	await get_tree().process_frame

	if puzzle.solucion_actual.is_empty():
		return

	var area_rect: Rect2 = puzzle.area_slots.get_global_rect()

	var escala: Vector2 = Vector2(
		contenedor.size.x / area_rect.size.x,
		contenedor.size.y / area_rect.size.y
	)

	for slot_item: Control in puzzle.slots:
		if not is_instance_valid(slot_item):
			continue

		var item: Node = null

		for obj: Node in puzzle.objetos:
			if is_instance_valid(obj) and obj.id_correcto == slot_item.id_correcto:
				item = obj
				break

		if item == null:
			continue

		var preview := AnimatedSprite2D.new()
		preview.sprite_frames = item.sprite_frames

		if preview.sprite_frames.has_animation("idle"):
			preview.play("idle")
		else:
			preview.frame = 0

		preview.centered = true

		contenedor.add_child(preview)

		# Posición REAL del slot dentro del área
		var pos_relativa: Vector2 = (
			slot_item.global_position - area_rect.position
		)

		var pos_canvas: Vector2 = Vector2(
			pos_relativa.x * escala.x,
			pos_relativa.y * escala.y
		)

		preview.position = pos_canvas
		preview.scale = Vector2(0.5, 0.5)

	if puzzle.has_method("ocultar_cronometro"):
		puzzle.ocultar_cronometro()

	label_cuenta.visible = true

	for i in range(int(tiempo_mostrar), 0, -1):
		label_cuenta.text = str(i)
		await get_tree().create_timer(1.0).timeout

	label_cuenta.text = "¡YA!"
	await get_tree().create_timer(0.5).timeout

	label_cuenta.visible = false

	if puzzle.has_method("mostrar_cronometro"):
		puzzle.mostrar_cronometro()

	canvas_mapa.visible = false
