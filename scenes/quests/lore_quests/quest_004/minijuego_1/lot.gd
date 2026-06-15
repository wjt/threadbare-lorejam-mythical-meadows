extends Control

@export var id_correcto: int = 0

enum Estado {
	GRIS,
	VERDE,
	ROJO
}

var estado_actual: Estado = Estado.GRIS


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("slot")

	# El slot empieza invisible
	visible = false


func obtener_item_cercano(
	lista_de_items: Array,
	distancia_max_permitida: float
) -> Node:

	var mejor_objeto: Node = null
	var mejor_distancia: float = distancia_max_permitida

	for item: Node in lista_de_items:
		if not is_instance_valid(item):
			continue

		var centro_item: Vector2 = item.global_position

		if "size" in item:
			centro_item += item.size / 2.0

		var centro_slot: Vector2 = global_position

		if "size" in self:
			centro_slot += size / 2.0

		var distancia_actual: float = centro_item.distance_to(centro_slot)

		if distancia_actual < mejor_distancia:
			mejor_distancia = distancia_actual
			mejor_objeto = item

	return mejor_objeto


func evaluar(
	lista_de_items: Array,
	distancia_max_permitida: float
) -> bool:

	var item_detectado: Node = obtener_item_cercano(
		lista_de_items,
		distancia_max_permitida
	)

	if item_detectado == null:
		estado_actual = Estado.GRIS
		return false

	if item_detectado.id_correcto == id_correcto:
		estado_actual = Estado.VERDE
		return true

	estado_actual = Estado.ROJO
	return false


func reset_visual() -> void:
	estado_actual = Estado.GRIS


func _draw() -> void:
	var color: Color = Color(0.5, 0.5, 0.5, 0.5)

	match estado_actual:
		Estado.GRIS:
			color = Color(0.65, 0.65, 0.65, 0.8)

		Estado.VERDE:
			color = Color(0, 1, 0, 0.7)

		Estado.ROJO:
			color = Color(1, 0, 0, 0.7)

	draw_circle(size / 2.0, 35.0, color)


func _process(_delta: float) -> void:
	queue_redraw()
