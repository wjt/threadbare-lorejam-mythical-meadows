extends Node2D

@warning_ignore("untyped_declaration")
@onready var area_slots: Control = $"../AreaSlots"
@onready var posiciones_iniciales: Node = $posiciones_iniciales
@onready var zona_objetos: Node = $zona_objetos
@onready var slots: Array = $"../ZonaSlots".get_children()

@onready var cronometro: Timer = $"../Cronometro"
@onready var label_cronometro: Label = $"../datos/CronometroLabel"
@onready var resultado_label: Label = $"../datos/ResultadoLabel"
@export var spawn_recompensa: Marker2D
@export var recompensa: CollectibleItem
@export_file("*.tscn")
var escena_siguiente_recompensa := ""
var recompensa_creada := false
var objetos: Array = []
var solucion_actual: Array = []

var jugando: bool = false
var tiempo_restante: int = 45
var distancia_max: float = 120.0
var porcentaje: float = 0.0


# -------------------------
func _ready()-> void:

	add_to_group("puzzle_party")
	randomize()

	objetos = zona_objetos.get_children()

	for o in objetos:
		o.visible = false
		o.slot_actual = null

	generar_solucion()
	configurar_slots()

	cronometro.timeout.connect(_on_timer_tick)

	visible = false


# -------------------------
func generar_solucion()->void:

	solucion_actual = objetos.duplicate()
	solucion_actual.shuffle()

	for obj in solucion_actual:
		obj.slot_actual = null


# -------------------------
func configurar_slots() -> void:

	var rect: Rect2 = area_slots.get_global_rect()
	var posiciones := []

	for slot in slots:

		var pos := Vector2.ZERO

		for i in range(100):

			pos = Vector2(
				randf_range(
					rect.position.x + 120,
					rect.position.x + rect.size.x - 120
				),
				randf_range(
					rect.position.y + 120,
					rect.position.y + rect.size.y - 120
				)
			)

			var valido := true

			for p in posiciones:
				if pos.distance_to(p) < 180:
					valido = false
					break

			if valido:
				break

		# IMPORTANTE:
		# Eliminamos decimales para evitar
		# desplazamientos visuales en pixel art
		pos = pos.round()

		posiciones.append(pos)

		slot.global_position = pos

	print("AreaSlots")
	print("Posicion: ", rect.position)
	print("Size: ", rect.size)

	for slot in slots:
		print(
			slot.name,
			" -> ",
			slot.global_position,
			" size=",
			slot.size
		)

func debug_slots() -> void:

	print("=== POSICIONES DE SLOTS ===")

	for slot in slots:
		print(
			slot.name,
			" pos=",
			slot.global_position,
			" size=",
			slot.size
		)
# -------------------------
func iniciar_puzzle() -> void:

	debug_slots()

	visible = true
	jugando = true
	tiempo_restante = 45

	colocar_items()

	for slot: Control in slots:
		slot.visible = true

	for obj: Node in objetos:
		obj.set_process_input(true)
		obj.visible = true

	cronometro.start()


func evaluar_resultado() -> void:

	if not jugando and tiempo_restante > 0:
		return

	jugando = false
	cronometro.stop()
	var correctos := 0
	var total := slots.size()
	# Limpiamos fantasmas anteriores
	var fantasmas: Array = get_tree().get_nodes_in_group("fantasma")
	for n: Node in fantasmas:
		n.queue_free()

	for i in range(slots.size()):
		var slot: Node = slots[i]
		if not is_instance_valid(slot):
			continue

		var esperado: int = slot.id_correcto
		var objeto_mas_cercano: Node = null
		var menor_distancia := INF
		
		# Buscamos el objeto físicamente más cercano al slot
		for obj in objetos:
			if not is_instance_valid(obj):
				continue

			var pos_obj: Vector2 = obj.global_position
			var distancia: float = pos_obj.distance_to(slot.global_position)

			if distancia < menor_distancia:
				menor_distancia = distancia
				objeto_mas_cercano = obj

		var correcto := false

		if objeto_mas_cercano != null:
			print("   ↳ Objeto más cercano detectado: %s" % objeto_mas_cercano.name)

			if menor_distancia <= distancia_max:
				correcto = (objeto_mas_cercano.id_correcto == esperado)



		if correcto:
			correctos += 1
			slot.modulate = Color(0, 1, 0) # Verde
		else:
			slot.modulate = Color(1, 0, 0) # Rojo

	# Cálculo final
	porcentaje = (float(correctos) / float(total) * 100.0) if total > 0 else 0.0
	resultado_label.text = "Resultado: %d%%" % int(porcentaje)
	if porcentaje >= 80.0:
		resultado_label.text = "¡COMPLETADO! %d%%" % int(porcentaje)
		victoria()
		await get_tree().create_timer(4.0).timeout
	else:
		resultado_label.text = "FALLASTE %d%%" % int(porcentaje)
		await get_tree().create_timer(4.0).timeout

		resetear()
		colocar_items()

		for slot: Control in slots:
			slot.modulate = Color.WHITE
			slot.visible = false

		get_tree().call_group("talk_puzzle", "activar_reintento")

	jugando = false
	cronometro.stop()



func colocar_items() -> void:
	var posiciones: Array = posiciones_iniciales.get_children()

	for i in range(min(objetos.size(), posiciones.size())):
		var obj: Node = objetos[i]

		if is_instance_valid(obj):
			obj.global_position = posiciones[i].global_position

			if "slot_actual" in obj:
				obj.slot_actual = null

# -------------------------
# 🛠️ AQUÍ ESTÁ LA CORRECCIÓN DE LA ID Y LOS PRINTS DE MOVIMIENTO



# -------------------------
func _on_timer_tick() -> void:
	if not jugando:
		return

	tiempo_restante -= 1

	if tiempo_restante <= 0:
		tiempo_restante = 0
		label_cronometro.text = "Tiempo: 0"

		jugando = false
		cronometro.stop()

		await evaluar_resultado()
		return

	label_cronometro.text = "Tiempo: " + str(tiempo_restante)


# -------------------------
func resetear() -> void:
	jugando = false
	cronometro.stop()

	tiempo_restante = 45
	label_cronometro.text = "Tiempo: 45"
	resultado_label.text = "Resultado:"

	for obj: Node in objetos:
		if not is_instance_valid(obj):
			continue
		obj.slot_actual = null
		obj.visible = false

	for slot: Control in slots:
		slot.visible = false
		slot.modulate = Color.WHITE

	visible = false
func victoria():

	if recompensa == null:
		return

	recompensa.global_position = spawn_recompensa.global_position
	recompensa.revealed = true
