extends TileMapLayer

var source_id: int = 1

var esq_sup_izq: Vector2i = Vector2i(8, 18)
var esq_sup_der: Vector2i = Vector2i(4, 19)
var esq_inf_izq: Vector2i = Vector2i(6, 19)
var esq_inf_der: Vector2i = Vector2i(7, 19)
var borde_arriba: Vector2i = Vector2i(4, 18)
var borde_abajo: Vector2i = Vector2i(5, 19)
var borde_izq: Vector2i = Vector2i(6, 18)
var borde_der: Vector2i = Vector2i(3, 19)
var relleno: Vector2i = Vector2i(1, 18)

var centros_nubes: Array[Vector2i] = []
var distancia_minima: float = 3.5

var capas_flotantes: Array[TileMapLayer] = []
var velocidad_viento: float = 8.0  # Píxeles por segundo
var avance_x: float = 0.0

var ancho_bucle_tiles: int = 30
var ancho_bucle_pixeles: float = ancho_bucle_tiles * 16.0


func _ready() -> void:
	clear()
	scale = Vector2(5, 5)

	generar_nube(Vector2i(-10, -5), 50, 20, true)

	var nubes_creadas: int = 0
	var intentos: int = 0

	var total_nubes_deseadas: int = 24

	while nubes_creadas < total_nubes_deseadas and intentos < 3000:
		var pos_x: int = randi_range(0, ancho_bucle_tiles - 1)
		var pos_y: int = randi_range(-2, 9)
		var ancho: int = randi_range(4, 9)
		var alto: int = randi_range(4, 6)

		if evaluar_espacio(Vector2i(pos_x, pos_y), ancho, alto):
			registrar_nube(Vector2i(pos_x, pos_y), ancho, alto)

			generar_nube(Vector2i(pos_x, pos_y), ancho, alto, false)

			generar_nube(Vector2i(pos_x - ancho_bucle_tiles, pos_y), ancho, alto, false)

			nubes_creadas += 1

		intentos += 1


func _process(delta: float) -> void:
	avance_x += velocidad_viento * delta

	if avance_x >= ancho_bucle_pixeles:
		avance_x -= ancho_bucle_pixeles

	for capa in capas_flotantes:
		capa.position.x = avance_x


func evaluar_espacio(pos_inicial: Vector2i, ancho: int, alto: int) -> bool:
	var centro_x: int = pos_inicial.x + int(ancho / 2.0)
	var centro_y: int = pos_inicial.y + int(alto / 2.0)
	var centro_nuevo := Vector2i(centro_x, centro_y)

	for centro_guardado in centros_nubes:
		if centro_nuevo.distance_to(centro_guardado) < distancia_minima:
			return false
	return true


func registrar_nube(pos_inicial: Vector2i, ancho: int, alto: int) -> void:
	var centro_x: int = pos_inicial.x + int(ancho / 2.0)
	var centro_y: int = pos_inicial.y + int(alto / 2.0)
	centros_nubes.append(Vector2i(centro_x, centro_y))


func generar_nube(pos_inicial: Vector2i, ancho: int, alto: int, es_base: bool = false) -> void:
	var capa_nube := TileMapLayer.new()
	capa_nube.tile_set = self.tile_set
	add_child(capa_nube)

	for x in range(ancho):
		for y in range(alto):
			var celda_actual: Vector2i = pos_inicial + Vector2i(x, y)
			var atlas_coord: Vector2i = Vector2i()

			if x == 0 and y == 0:
				atlas_coord = esq_sup_izq
			elif x == ancho - 1 and y == 0:
				atlas_coord = esq_sup_der
			elif x == 0 and y == alto - 1:
				atlas_coord = esq_inf_izq
			elif x == ancho - 1 and y == alto - 1:
				atlas_coord = esq_inf_der
			elif y == 0:
				atlas_coord = borde_arriba
			elif y == alto - 1:
				atlas_coord = borde_abajo
			elif x == 0:
				atlas_coord = borde_izq
			elif x == ancho - 1:
				atlas_coord = borde_der
			else:
				atlas_coord = relleno

			capa_nube.set_cell(celda_actual, source_id, atlas_coord)

	if not es_base:
		capas_flotantes.append(capa_nube)
