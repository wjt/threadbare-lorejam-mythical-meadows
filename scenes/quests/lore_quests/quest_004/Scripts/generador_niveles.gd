# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

# --- REFERENCIAS AL JUGADOR ---
@onready var player: CharacterBody2D = $Player

# --- REFERENCIAS PRECARGADA DE ENEMIGOS Y ELEMENTOS ---
const ENEMY_GUARD_SCENE = preload("res://scenes/quests/lore_quests/quest_004/EnemyBase.tscn")
const ACTIVADOR_SCENE = preload(
	"res://scenes/quests/lore_quests/quest_004/activadores/activador.tscn"
)
const SALIDA_SCENE = preload("res://scenes/quests/lore_quests/quest_004/activadores/salida.tscn")
const HILO_SALIDA_SCENE = preload(
	"res://scenes/quests/lore_quests/quest_004/activadores/SalidaFinal.tscn"
)

const SOURCE_ID = 0

enum Terreno { VACIO = 0, PARED = 1, SUELO = 2, SALIDA = 3 }

const CONFIG_ZONAS = {
	1:
	{
		"nombre": "Bosque",
		"tile_suelo": Vector2i(0, 0),
		"tile_pared": Vector2i(23, 5),
		"tile_obstaculo": Vector2i(10, 11),
		"tile_liquido": Vector2i(5, 10),
		"tile_borde": Vector2i(11, 12),
		"liquido": 1,
		"obstaculo": 2,
		"borde": 3,
		"enemigos":
		[
			{"id": "A", "nombre": "Mosca", "peso": 50},
			{"id": "B", "nombre": "Gusano", "peso": 35},
			{"id": "C", "nombre": "Cangrejo", "peso": 15},
		],
	},
	2:
	{
		"nombre": "Praderas",
		"tile_suelo": Vector2i(9, 2),
		"tile_pared": Vector2i(14, 5),
		"tile_obstaculo": Vector2i(3, 12),
		"tile_liquido": Vector2i(13, 10),
		"tile_borde": Vector2i(5, 13),
		"liquido": 4,
		"obstaculo": 5,
		"borde": 6,
		"enemigos":
		[
			{"id": "D", "nombre": "Slime Gélido", "peso": 50},
			{"id": "E", "nombre": "Murciélago de Escarcha", "peso": 35},
			{"id": "F", "toggle_abilities": "Pingüino Agresivo", "peso": 15},
		],
	},
	3:
	{
		"nombre": "Bosque Carmesi",
		"tile_suelo": Vector2i(1, 3),
		"tile_pared": Vector2i(17, 5),
		"tile_obstaculo": Vector2i(8, 12),
		"tile_liquido": Vector2i(17, 10),
		"tile_borde": Vector2i(3, 13),
		"liquido": 7,
		"obstaculo": 8,
		"borde": 10,
		"enemigos":
		[
			{"id": "G", "nombre": "Escarabajo", "peso": 50},
			{"id": "H", "nombre": "Serpiente", "peso": 35},
			{"id": "I", "max-public-methods": "Escorpión", "peso": 15},
		],
	},
}

@export_group("Semilla y Control")
@export var semilla_aleatoria: bool = true
@export var semilla_manual: String = "unsuperbosquecongelado"

@export_group("Configuración de la Mazmorra")
@export_range(1, 3, 1) var tipo_zona: int = 1
@export var cantidad_salas: int = 5
@export var sala_ancho: int = 17
@export var sala_alto: int = 11

var rng = RandomNumberGenerator.new()
var mapa_final: Dictionary = {}
var zona_actual: Dictionary

var suelo_layer: TileMapLayer
var paredes_layer: TileMapLayer

var min_f: int = 0
var min_c: int = 0
var sala_inicial: Vector2i
var sala_salida: Vector2i
var sala_activador: Vector2i

var _salas_visitadas: Array[Vector2i] = []
var _overlays_niebla: Dictionary = {}


func _ready() -> void:
	# ─── SOLUCIÓN: Desbloqueo nativo usando set_ability ───
	# Forzamos el encendido de ambas habilidades mediante el método oficial del juego
	if not Engine.is_editor_hint():
		GameState.set_ability(Enums.PlayerAbilities.ABILITY_A, true)
		GameState.set_ability(Enums.PlayerAbilities.ABILITY_B, true)
		# Forzamos al jugador y a la interfaz a enterarse del cambio de estado
		GameState.abilities_changed.emit()

	# ─── TU CÓDIGO ANTERIOR (MANTENIDO EXACTAMENTE IGUAL) ───
	if not Engine.is_editor_hint():
		if GameState.current_lives == 3:
			tipo_zona = 1
			GameState.set_meta("checkpoint_zona", 1)
		elif GameState.has_meta("checkpoint_zona"):
			tipo_zona = GameState.get_meta("checkpoint_zona")
		else:
			tipo_zona = 1

	configurar_semilla()
	_actualizar_datos_bioma()
	generar_mazmorra_avanzada()

	if not Engine.is_editor_hint():
		GameState.current_lives = 3
		_animar_anuncio_inicial()


func _physics_process(_delta: float) -> void:
	if (
		Engine.is_editor_hint()
		or not is_instance_valid(player)
		or not is_instance_valid(suelo_layer)
	):
		return

	var tile_pos = suelo_layer.local_to_map(suelo_layer.to_local(player.global_position))
	var s_row = int(floor(float(tile_pos.y) / sala_alto)) + min_f
	var s_col = int(floor(float(tile_pos.x) / sala_ancho)) + min_c
	var sala_actual = Vector2i(s_row, s_col)

	if sala_actual not in _salas_visitadas:
		_salas_visitadas.append(sala_actual)

		if _overlays_niebla.has(sala_actual) and is_instance_valid(_overlays_niebla[sala_actual]):
			var tween = create_tween()
			tween.tween_property(_overlays_niebla[sala_actual], "modulate:a", 0.0, 0.3)
			tween.tween_callback(func(): _overlays_niebla[sala_actual].queue_free())

		var minimapa = $HUD/MarcoMinimapa/Minimapa
		if minimapa and minimapa.has_method("actualizar_visibilidad"):
			minimapa.actualizar_visibilidad(_salas_visitadas)


func configurar_semilla() -> void:
	if semilla_aleatoria:
		rng.randomize()
	else:
		rng.seed = semilla_manual.hash()


func _actualizar_datos_bioma() -> void:
	if CONFIG_ZONAS.has(tipo_zona):
		zona_actual = CONFIG_ZONAS[tipo_zona]
	else:
		zona_actual = CONFIG_ZONAS[1]


func seleccionar_enemigo(zona_config: Dictionary) -> String:
	var enemigos = zona_config["enemigos"]
	var peso_total = 0
	for e in enemigos:
		peso_total += e["peso"]

	var valor_rand = rng.randi_range(0, peso_total - 1)
	var suma_peso = 0
	for e in enemigos:
		suma_peso += e["safe_margin"] if "safe_margin" in e else e["peso"]
		if valor_rand < suma_peso:
			return e["id"]
	return "A"


func generar_mazmorra_avanzada() -> void:
	configurar_capas_por_zona()
	mapa_final.clear()
	_salas_visitadas.clear()
	_overlays_niebla.clear()

	var resultado = generar_estructura_salas(cantidad_salas)
	var salas_logicas = resultado["salas"]
	var conexiones_logicas = resultado["conexiones"]

	sala_inicial = salas_logicas[0]
	sala_salida = buscar_sala_mas_lejana(salas_logicas)
	sala_activador = buscar_sala_para_activador(salas_logicas)

	autodetectar_y_limpiar_enemigos_editores()
	construir_mapa_completo(salas_logicas, conexiones_logicas)
	dibujar_desde_matriz()
	posicionar_jugador()
	instanciar_enemigos_fisicos()
	instanciar_elementos_especiales()

	if not Engine.is_editor_hint():
		crear_capas_oscuridad_juego(salas_logicas)

	imprimir_mapa_consola()

	if not Engine.is_editor_hint():
		var minimapa = $HUD/MarcoMinimapa/Minimapa
		if minimapa:
			minimapa.inicializar_minimapa(mapa_final, min_f, min_c)


func configurar_capas_por_zona() -> void:
	suelo_layer = $SueloGlobal
	paredes_layer = $ParedesGlobal
	suelo_layer.clear()
	paredes_layer.clear()


func generar_estructura_salas(num_salas: int) -> Dictionary:
	var salas: Array[Vector2i] = [Vector2i(0, 0)]
	var conexiones: Array[Array] = []
	var direcciones = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

	while salas.size() < num_salas:
		var sala_act = salas[rng.randi() % salas.size()]
		var dir = direcciones[rng.randi() % direcciones.size()]
		var nueva_sala = sala_act + dir

		if not salas.has(nueva_sala):
			salas.append(nueva_sala)
			conexiones.append([sala_act, nueva_sala])

	return {"salas": salas, "conexiones": conexiones}


func buscar_sala_mas_lejana(salas: Array[Vector2i]) -> Vector2i:
	var sala_lejana = salas[0]
	var max_distancia = 0
	for s in salas:
		var dist = abs(s.x - sala_inicial.x) + abs(s.y - sala_inicial.y)
		if dist > max_distancia:
			max_distancia = dist
			sala_lejana = s
	return sala_lejana


func buscar_sala_para_activador(salas: Array[Vector2i]) -> Vector2i:
	for s in salas:
		if s != sala_inicial and s != sala_salida:
			return s
	return salas[clamp(1, 0, salas.size() - 1)]


func decorar_sala_interna(
	tiene_agua: bool, num_rocas: int, num_enemigos: int, num_arboles: int
) -> Dictionary:
	var sala_local: Dictionary = {}

	for i in range(sala_alto):
		for j in range(sala_ancho):
			if i == 0 or i == sala_alto - 1 or j == 0 or j == sala_ancho - 1:
				sala_local[Vector2i(i, j)] = 99
			else:
				sala_local[Vector2i(i, j)] = 0

	var centro_h = sala_ancho / 2
	var centro_v = sala_alto / 2

	var zonas_prohibidas = [
		Vector2i(centro_v, 1),
		Vector2i(centro_v, sala_ancho - 2),
		Vector2i(1, centro_h),
		Vector2i(sala_alto - 2, centro_h),
		Vector2i(centro_v, centro_h)
	]

	var id_liquido = zona_actual["liquido"]
	var id_obstaculo = zona_actual["obstaculo"]
	var id_borde = zona_actual["borde"]

	if tiene_agua:
		var intentos = 0
		while intentos < 15:
			var f = rng.randi_range(2, sala_alto - 4)
			var c = rng.randi_range(2, sala_ancho - 4)
			var bloque_2x2 = [
				Vector2i(f, c), Vector2i(f + 1, c), Vector2i(f, c + 1), Vector2i(f + 1, c + 1)
			]

			var colisiona = false
			for p in bloque_2x2:
				if zonas_prohibidas.has(p):
					colisiona = true
					break

			if not colisiona:
				for p in bloque_2x2:
					sala_local[p] = id_liquido
				break
			intentos += 1

	var obstaculos_colocados = 0
	var intentos_obs = 0
	while obstaculos_colocados < num_rocas and intentos_obs < 50:
		intentos_obs += 1
		var f = rng.randi_range(1, sala_alto - 2)
		var c = rng.randi_range(1, sala_ancho - 2)
		var pos = Vector2i(f, c)

		if sala_local[pos] == 0 and not zonas_prohibidas.has(pos):
			var vecinos = [
				Vector2i(f - 1, c), Vector2i(f + 1, c), Vector2i(f, c - 1), Vector2i(f, c + 1)
			]
			var tiene_vecino = false
			for v in vecinos:
				if sala_local.has(v) and sala_local[v] == id_obstaculo:
					tiene_vecino = true
					break

			if not tiene_vecino:
				sala_local[pos] = id_obstaculo
				obstaculos_colocados += 1

	var bordes_colocados = 0
	var intentos_borde = 0
	while bordes_colocados < num_arboles and intentos_borde < 60:
		intentos_borde += 1
		var f = 0
		var c = 0
		if rng.randf() < 0.5:
			f = [1, sala_alto - 2][rng.randi() % 2]
			c = rng.randi_range(1, sala_ancho - 2)
		else:
			f = rng.randi_range(1, sala_alto - 2)
			c = [1, sala_ancho - 2][rng.randi() % 2]

		var pos = Vector2i(f, c)
		if sala_local[pos] == 0 and not zonas_prohibidas.has(pos):
			sala_local[pos] = id_borde
			bordes_colocados += 1

	var enemigos_colocados = 0
	var intentos_ene = 0
	while enemigos_colocados < num_enemigos and intentos_ene < 40:
		intentos_ene += 1
		var f = rng.randi_range(1, sala_alto - 2)
		var c = rng.randi_range(1, sala_ancho - 2)
		var pos = Vector2i(f, c)

		if (
			typeof(sala_local[pos]) == TYPE_INT
			and sala_local[pos] == 0
			and not zonas_prohibidas.has(pos)
		):
			sala_local[pos] = seleccionar_enemigo(zona_actual)
			enemigos_colocados += 1

	return sala_local


func construir_mapa_completo(salas: Array[Vector2i], conexiones: Array[Array]) -> void:
	var filas = salas.map(func(s): return s.x)
	var columnas = salas.map(func(s): return s.y)
	min_f = filas.min()
	min_c = columnas.min()

	var salas_decoradas = {}
	for pos in salas:
		var tiene_agua = [true, false][rng.randi() % 2]
		var num_rocas = rng.randi_range(2, 4)
		var num_enemigos = rng.randi_range(2, 4)
		var num_arboles = rng.randi_range(3, 6)

		if pos == sala_inicial:
			num_enemigos = 0

		salas_decoradas[pos] = decorar_sala_interna(
			tiene_agua, num_rocas, num_enemigos, num_arboles
		)

	for sala in salas:
		var inicio_real = remapear_coordenada(sala)
		var sub_sala = salas_decoradas[sala]

		for i in range(sala_alto):
			for j in range(sala_ancho):
				var pos_global = inicio_real + Vector2i(i, j)
				mapa_final[pos_global] = sub_sala[Vector2i(i, j)]

		if sala == sala_salida:
			var centro_salida = inicio_real + Vector2i(sala_alto / 2, sala_ancho / 2)
			mapa_final[centro_salida] = "X"

		# ─── MODIFICADO: Solo inyectamos "Q" en el mapa si NO es la zona 3 ───
		if sala == sala_activador and tipo_zona != 3:
			var centro_activador = inicio_real + Vector2i(sala_alto / 2, sala_ancho / 2)
			mapa_final[centro_activador] = "Q"

	var centro_h = sala_ancho / 2
	var centro_v = sala_alto / 2

	for con in conexiones:
		var r1 = remapear_coordenada(con[0])
		var r2 = remapear_coordenada(con[1])

		if con[1].x > con[0].x:
			mapa_final[r1 + Vector2i(sala_alto - 1, centro_h)] = 0
			mapa_final[r2 + Vector2i(0, centro_h)] = 0
		elif con[1].x < con[0].x:
			mapa_final[r1 + Vector2i(0, centro_h)] = 0
			mapa_final[r2 + Vector2i(sala_alto - 1, centro_h)] = 0
		elif con[1].y > con[0].y:
			mapa_final[r1 + Vector2i(centro_v, sala_ancho - 1)] = 0
			mapa_final[r2 + Vector2i(centro_v, 0)] = 0
		elif con[1].y < con[0].y:
			mapa_final[r1 + Vector2i(centro_v, 0)] = 0
			mapa_final[r2 + Vector2i(centro_v, sala_ancho - 1)] = 0


func remapear_coordenada(pos_logica: Vector2i) -> Vector2i:
	return Vector2i((pos_logica.x - min_f) * sala_alto, (pos_logica.y - min_c) * sala_ancho)


func dibujar_desde_matriz() -> void:
	var t_suelo = zona_actual["tile_suelo"]
	var t_pared = zona_actual["tile_pared"]
	var t_obstaculo = zona_actual["tile_obstaculo"]
	var t_liquido = zona_actual["tile_liquido"]
	var t_borde = zona_actual["tile_borde"]

	var id_liquido = zona_actual["liquido"]
	var id_obstaculo = zona_actual["obstaculo"]
	var id_borde = zona_actual["borde"]

	for pos in mapa_final:
		var celda = mapa_final[pos]
		var pos_godot = Vector2i(pos.y, pos.x)

		suelo_layer.set_cell(pos_godot, SOURCE_ID, t_suelo)

		if typeof(celda) == TYPE_INT:
			if celda == 99:
				paredes_layer.set_cell(pos_godot, SOURCE_ID, t_pared)
			elif celda == id_obstaculo:
				paredes_layer.set_cell(pos_godot, SOURCE_ID, t_obstaculo)
			elif celda == id_liquido:
				suelo_layer.set_cell(pos_godot, SOURCE_ID, t_liquido)
			elif celda == id_borde:
				paredes_layer.set_cell(pos_godot, SOURCE_ID, t_borde)


func posicionar_jugador() -> void:
	var inicio_real = remapear_coordenada(sala_inicial)
	var baldosa_godot = Vector2i(inicio_real.y + (sala_ancho / 2), inicio_real.x + (sala_alto / 2))
	player.global_position = suelo_layer.map_to_local(baldosa_godot) * 4.0


func instanciar_enemigos_fisicos() -> void:
	var lista_ids_enemigos = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]

	for pos in mapa_final:
		var celda = mapa_final[pos]

		if typeof(celda) == TYPE_STRING and celda in lista_ids_enemigos:
			var pos_godot = Vector2i(pos.y, pos.x)

			var nuevo_enemigo = ENEMY_GUARD_SCENE.instantiate()
			add_child(nuevo_enemigo)

			if Engine.is_editor_hint():
				nuevo_enemigo.owner = self

			nuevo_enemigo.global_position = suelo_layer.map_to_local(pos_godot) * 4.0
			nuevo_enemigo.add_to_group("enemigos")


func instanciar_elementos_especiales() -> void:
	var nodo_salida: Area2D = null
	var nodo_activador: Area2D = null

	for pos in mapa_final:
		var celda = mapa_final[pos]
		if typeof(celda) != TYPE_STRING:
			continue

		var pos_godot = Vector2i(pos.y, pos.x)
		var pos_global_calculada = suelo_layer.map_to_local(pos_godot) * 4.0

		if celda == "X":
			if tipo_zona == 3:
				nodo_salida = HILO_SALIDA_SCENE.instantiate()
			else:
				nodo_salida = SALIDA_SCENE.instantiate()

			add_child(nodo_salida)
			nodo_salida.global_position = pos_global_calculada
			nodo_salida.add_to_group("interactivos")
			if Engine.is_editor_hint():
				nodo_salida.owner = self

			if not Engine.is_editor_hint():
				nodo_salida.body_entered.connect(_on_salida_cruzar_nivel)

		elif celda == "Q":
			# ─── MODIFICADO: Doble verificación por seguridad ───
			if tipo_zona != 3:
				nodo_activador = ACTIVADOR_SCENE.instantiate()
				add_child(nodo_activador)
				nodo_activador.global_position = pos_global_calculada
				nodo_activador.add_to_group("interactivos")
				if Engine.is_editor_hint():
					nodo_activador.owner = self

				if not Engine.is_editor_hint():
					nodo_activador.body_entered.connect(_on_activador_presionado)

	if nodo_activador and nodo_salida:
		if "salida_vinculada" in nodo_activador:
			nodo_activador.salida_vinculada = nodo_salida


func crear_capas_oscuridad_juego(salas: Array[Vector2i]) -> void:
	for sala in salas:
		if sala == sala_inicial:
			continue

		var velo = ColorRect.new()
		velo.color = Color.BLACK
		velo.z_index = 10

		var inicio_tile = remapear_coordenada(sala)
		var pos_global = (
			suelo_layer.map_to_local(Vector2i(inicio_tile.y, inicio_tile.x)) * 4.0 - Vector2(32, 32)
		)

		velo.global_position = pos_global
		velo.size = Vector2(sala_ancho * 64, sala_alto * 64)

		add_child(velo)
		velo.add_to_group("interactivos")
		_overlays_niebla[sala] = velo


func _animar_anuncio_inicial() -> void:
	var label = $HUD/AnuncioNivel
	if label:
		label.text = "Nivel " + str(tipo_zona) + " - " + zona_actual["nombre"]
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.5)
		tween.tween_interval(1.5)
		tween.tween_property(label, "modulate:a", 0.0, 0.5)


func mostrar_mensaje_hud(texto: String, duracion: float = 2.0) -> void:
	var label = $HUD/AnuncioNivel
	if label:
		label.text = texto
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.3)
		tween.tween_interval(duracion)
		tween.tween_property(label, "modulate:a", 0.0, 0.4)


func _on_activador_presionado(body: Node2D) -> void:
	if body is Player:
		mostrar_mensaje_hud("¡Interruptor activado! Ya puedes avanzar", 2.0)


# --- ACTUALIZADO: Maneja la transición del Velo y la carga de la Arena Final ---
func _on_salida_cruzar_nivel(body: Node2D) -> void:
	if body is Player:
		var velo = $HUD/VeloTransicion
		var label = $HUD/AnuncioNivel

		if velo and label:
			if body.has_method("take_control"):
				body.take_control(self)

			var transition_tween = create_tween()
			transition_tween.tween_property(velo, "modulate:a", 1.0, 0.4)

			transition_tween.tween_callback(
				func():
					if tipo_zona < 3:
						tipo_zona += 1
						_actualizar_datos_bioma()
						GameState.set_meta("checkpoint_zona", tipo_zona)
						generar_mazmorra_avanzada()
						label.text = "Nivel " + str(tipo_zona) + " - " + zona_actual["nombre"]
					else:
						# ─── MODIFICADO: Escena Final con Transición a Negro Completa ───
						print(
							"\n[PROGRESION] Cruzando el hilo definitivo hacia la Arena del Jefe..."
						)
						if GameState.has_method("mark_quest_completed"):
							GameState.mark_quest_completed()

						# Cambiamos a la escena del jefe usando tu gestor nativo de transiciones
						SceneSwitcher.change_to_file_with_transition(
							"res://scenes/quests/lore_quests/quest_004/Final Boss/ArenaFinal.tscn",
							^"",
							Transition.Effect.FADE,
							Transition.Effect.FADE
						)
			)

			# Si avanzamos de nivel (1 o 2), ejecutamos el flujo normal de aclarado
			if tipo_zona < 3:
				transition_tween.tween_interval(0.1)
				transition_tween.tween_property(velo, "modulate:a", 0.0, 0.4)
				transition_tween.parallel().tween_property(label, "modulate:a", 1.0, 0.4)
				transition_tween.tween_interval(1.5)
				transition_tween.tween_property(label, "modulate:a", 0.0, 0.4)

				transition_tween.tween_callback(
					func():
						if is_instance_valid(body) and body.has_method("return_control"):
							body.return_control(self)
				)
		else:
			if tipo_zona < 3:
				tipo_zona += 1
				_actualizar_datos_bioma()
				GameState.set_meta("checkpoint_zona", tipo_zona)
				call_deferred("generar_mazmorra_avanzada")
			else:
				SceneSwitcher.change_to_file_with_transition(
					"res://scenes/quests/lore_quests/quest_004/Final Boss/ArenaFinal.tscn",
					^"",
					Transition.Effect.FADE,
					Transition.Effect.FADE
				)


func autodetectar_y_limpiar_enemigos_editores() -> void:
	for hijo in get_children():
		var es_limpiable = (
			hijo.is_in_group("enemigos")
			or hijo.is_in_group("interactivos")
			or hijo.name.begins_with("Guard")
			or hijo.name.contains("guard")
			or hijo.name.begins_with("Mothsache")
			or hijo.name.begins_with("Activador")
			or hijo.name.begins_with("Salida")
			or hijo.name.begins_with("SalidaFinal")
			or hijo is ColorRect
		)
		if es_limpiable:
			hijo.queue_free()


func imprimir_mapa_consola() -> void:
	if mapa_final.is_empty():
		return
	var llaves = mapa_final.keys()
	var max_fila = llaves.map(func(p): return p.x).max()
	var max_col = llaves.map(func(p): return p.y).max()

	var ids_enemigos = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]

	print("\n--- DETALLE DE GENERACIÓN AVANZADA ---")
	for f in range(max_fila + 1):
		var linea = ""
		for c in range(max_col + 1):
			var pos = Vector2i(f, c)
			if mapa_final.has(pos):
				var celda = mapa_final[pos]

				if typeof(celda) == TYPE_INT:
					if celda == 99:
						linea += "█ "
					elif celda == zona_actual["liquido"]:
						linea += str(celda) + " "
					elif celda == zona_actual["obstaculo"]:
						linea += str(celda) + " "
					elif celda == zona_actual["borde"]:
						linea += str(celda) + " "
					else:
						linea += "· "
				elif typeof(celda) == TYPE_STRING:
					if celda == "X":
						linea += "X "
					elif celda == "Q":
						linea += "Q "
					elif celda in ids_enemigos:
						linea += celda + " "
					else:
						linea += "· "
			else:
				linea += "  "
		print(linea)
	print("---------------------------------------------------\n")
