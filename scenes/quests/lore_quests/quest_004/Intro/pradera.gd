extends Node2D

# Cargamos el recurso de diálogos directamente
const DIALOGUE_RESOURCE = preload("res://scenes/quests/lore_quests/quest_004/Intro/intro.dialogue")

@onready var spirit_bun: CharacterBody2D = $OnTheGround/SpiritBun
@onready var player: CharacterBody2D = $OnTheGround/Player

# Variables de control de la historia para separar los 3 momentos
var monologo_inicial_hecho: bool = false
var dialogo_conejo_hecho: bool = false
var dialogo_arbol_hecho: bool = false

func _ready() -> void:
	# Deshabilitamos el movimiento de Wiñay temporalmente al iniciar
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)
		
	# Esperamos un pequeño instante (0.5 segundos) para que cargue la pantalla
	await get_tree().create_timer(0.5).timeout
		
		# 1. LANZAMOS ÚNICAMENTE EL MONÓLOGO INICIAL
	DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "inicio_monologo")
	await DialogueManager.dialogue_ended
	monologo_inicial_hecho = true
		
		# Le devolvemos el control a Wiñay para que camine libremente hacia el conejo
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(true)


func _unhandled_input(event: InputEvent) -> void:
		# Verificamos si el jugador está cerca del conejo
	if spirit_bun and "jugador_cerca" in spirit_bun and spirit_bun.jugador_cerca:
			
			# Detectamos la pulsación única de Espacio
		if event.is_action_pressed("dialogue_next") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
				
			get_viewport().set_input_as_handled()
				
				# CASO 1: Primer encuentro (El conejo está en su sitio inicial, habla y luego huye)
			if monologo_inicial_hecho and not dialogo_conejo_hecho:
					iniciar_conversacion_conejo()
					
				# CASO 2: Segundo encuentro (Solo cuando ya llegó al árbol y terminó de correr)
			elif dialogo_conejo_hecho and not dialogo_arbol_hecho:
				if "esta_huyendo" in spirit_bun and not spirit_bun.esta_huyendo:
					iniciar_conversacion_arbol()


func iniciar_conversacion_conejo() -> void:
	dialogo_conejo_hecho = true
		
		# Apagamos la flecha flotante
	if spirit_bun and spirit_bun.has_node("IndicadorVisual"):
		spirit_bun.get_node("IndicadorVisual").visible = false
		
		# Congelamos a Wiñay de forma segura para la conversación
	if player:
		player.velocity = Vector2.ZERO
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")
		if player.has_method("set_physics_process"):
			player.set_physics_process(false)
				
		# 2. LANZAMOS EL SEGUNDO DIÁLOGO (ENCUENTRO CONEJO)
	DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "encuentro_conejo")
	await DialogueManager.dialogue_ended
		
		# Devolvemos el control temporal para que el jugador pueda seguirlo
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(true)
			
		# El conejo sale corriendo hacia el árbol
	activar_huida_conejo()


func iniciar_conversacion_arbol() -> void:
	dialogo_arbol_hecho = true
		
		# Apagamos la flecha flotante en el árbol
	if spirit_bun and spirit_bun.has_node("IndicadorVisual"):
		spirit_bun.get_node("IndicadorVisual").visible = false
			
		# Volvemos a frenar a Wiñay para su monólogo final
	if player:
		player.velocity = Vector2.ZERO
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")
		if player.has_method("set_physics_process"):
			player.set_physics_process(false)
				
		# Lanzamos el tercer bloque de diálogo (encuentro_arbol)
	DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "encuentro_arbol")
	await DialogueManager.dialogue_ended
		
		# Le devolvemos el proceso físico por si acaso
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(true)
		
		# --- NUEVO: CAMBIO DE ESCENA A BARNABY STORE ---
		# Agregamos un minúsculo retraso de 0.2 segundos para que la transición no sea brusca al cerrarse el texto
	await get_tree().create_timer(0.2).timeout

	var ruta := "res://scenes/quests/lore_quests/quest_004/Intro/Barnaby_store.tscn"

	GameState.set_challenge_start_scene(ruta)
	SceneSwitcher.change_to_file_with_transition(ruta)

func activar_huida_conejo() -> void:
	if spirit_bun:
		var ruta_del_conejo: Array[Vector2] = [
			Vector2(1100.0, 293.0),
			Vector2(1860.0, 380.0)
		]
		if spirit_bun.has_method("iniciar_ruta_huida"):
			spirit_bun.iniciar_ruta_huida(ruta_del_conejo)
