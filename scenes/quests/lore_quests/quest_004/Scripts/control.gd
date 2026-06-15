# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@export var tamano_pixel: float = 3.0

var mapa_datos: Dictionary = {}
var jugador_ref: CharacterBody2D = null
var tilemap_ref: TileMapLayer = null

var offset_x: int = 0
var offset_y: int = 0

# ─── VARIABLES DE PROGRESO DE NIEBLA ───
var _salas_visitadas: Array[Vector2i] = []
# Dimensiones lógicas para mapear los bloques de celdas
var sala_ancho: int = 17
var sala_alto: int = 11


func _ready() -> void:
	jugador_ref = get_tree().current_scene.get_node_or_null("Player")
	tilemap_ref = get_tree().current_scene.get_node_or_null("SueloGlobal")


func _process(_delta: float) -> void:
	if is_instance_valid(jugador_ref):
		queue_redraw()


func _draw() -> void:
	if mapa_datos.is_empty():
		return

	# 1. Dibujar el mapa filtrando celdas no descubiertas
	for pos in mapa_datos:
		# Calculamos matemáticamente a qué habitación pertenece este pixel del mapa
		var s_row = int(floor(float(pos.x) / sala_alto)) + offset_x
		var s_col = int(floor(float(pos.y) / sala_ancho)) + offset_y
		var sala_del_tile = Vector2i(s_row, s_col)

		# ─── CLAVE: Si la sala no ha sido visitada en partida, no la dibujamos ───
		if not Engine.is_editor_hint() and sala_del_tile not in _salas_visitadas:
			continue

		var x = (pos.y - offset_y) * tamano_pixel
		var y = (pos.x - offset_x) * tamano_pixel
		var rect = Rect2(Vector2(x, y), Vector2(tamano_pixel, tamano_pixel))

		var celda = mapa_datos[pos]
		if typeof(celda) == TYPE_INT:
			if celda == 99:
				draw_rect(rect, Color(0.2, 0.2, 0.2))
			elif celda == 0:
				draw_rect(rect, Color(0.4, 0.4, 0.4, 0.5))
			else:
				draw_rect(rect, Color(0.3, 0.4, 0.6))

		elif typeof(celda) == TYPE_STRING:
			if celda == "X":
				draw_rect(rect, Color.DARK_RED)
			elif celda == "Q":
				draw_rect(rect, Color.GOLD)
			else:
				draw_rect(rect, Color.ORANGE_RED)

	# 2. Dibujar al Jugador (Siempre visible)
	if is_instance_valid(jugador_ref) and is_instance_valid(tilemap_ref):
		var baldosa_actual = tilemap_ref.local_to_map(
			tilemap_ref.to_local(jugador_ref.global_position)
		)
		var p_x = (baldosa_actual.x - offset_y) * tamano_pixel
		var p_y = (baldosa_actual.y - offset_x) * tamano_pixel

		var rect_jugador = Rect2(Vector2(p_x, p_y), Vector2(tamano_pixel + 1, tamano_pixel + 1))
		draw_rect(rect_jugador, Color.GREEN)


func inicializar_minimapa(nuevo_mapa: Dictionary, min_f: int, min_c: int) -> void:
	mapa_datos = nuevo_mapa
	offset_x = min_f
	offset_y = min_c
	queue_redraw()


# ─── NUEVA FUNCIÓN PÚBLICA RECIBIDA DESDE EL PROCESO DEL GENERADOR ───
func actualizar_visibilidad(salas_descubiertas: Array[Vector2i]) -> void:
	_salas_visitadas = salas_descubiertas
	queue_redraw()
