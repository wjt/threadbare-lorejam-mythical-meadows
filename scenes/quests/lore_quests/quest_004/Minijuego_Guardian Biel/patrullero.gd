extends CharacterBody2D

@export var velocidad_persecucion: float = 120.0
@export var distancia_frenado: float = 40.0
@export var fuerza_retroceso: float = 650.0  # Un poco más de fuerza para asegurar el despegue

var jugador: Node2D = null
var vector_retroceso: Vector2 = Vector2.ZERO
var aturdido: bool = false

@onready var nav_agent = $NavigationAgent2D
@onready var colision_fisica = $CollisionShape2D # Detecta tu forma física principal

func _ready():
	jugador = get_tree().current_scene.find_child("Player", true, false)
	if nav_agent:
		nav_agent.target_desired_distance = distancia_frenado
		nav_agent.path_max_distance = 20.0

func _physics_process(delta):
	if aturdido:
		velocity = vector_retroceso
		vector_retroceso = vector_retroceso.move_toward(Vector2.ZERO, 18.0 * velocidad_persecucion * delta)
		
		if vector_retroceso == Vector2.ZERO:
			aturdido = false
			# 2. CUANDO DEJA DE RETROCEDER: Le devolvemos su colisión física normal
			if colision_fisica:
				colision_fisica.disabled = false
			
		move_and_slide()
		return

	if not is_instance_valid(jugador):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distancia = global_position.distance_to(jugador.global_position)

	if distancia < 450.0 and distancia > distancia_frenado:
		nav_agent.target_position = jugador.global_position
		
		if nav_agent.is_target_reachable() or not nav_agent.is_navigation_finished():
			var siguiente_punto = nav_agent.get_next_path_position()
			var direccion = (siguiente_punto - global_position).normalized()
			velocity = direccion * velocidad_persecucion
		else:
			var direccion = (jugador.global_position - global_position).normalized()
			velocity = direccion * velocidad_persecucion
	else:
		velocity = Vector2.ZERO
		
		# Detecta el golpe del jugador
		if distancia <= distancia_frenado and Input.is_action_just_pressed("atacar"):
			aplicar_retroceso()

	move_and_slide()

func aplicar_retroceso():
	if is_instance_valid(jugador):
		print("💥 ¡Golpe crítico! Desactivando colisión y empujando.")
		aturdido = true
		
		# 1. AL RECIBIR EL GOLPE: Apagamos su colisión para que no se atranque contigo
		if colision_fisica:
			colision_fisica.disabled = true
		
		var direccion_golpe = (global_position - jugador.global_position).normalized()
		if direccion_golpe == Vector2.ZERO:
			direccion_golpe = Vector2.UP # Dirección por defecto si están encimados
			
		vector_retroceso = direccion_golpe * fuerza_retroceso
