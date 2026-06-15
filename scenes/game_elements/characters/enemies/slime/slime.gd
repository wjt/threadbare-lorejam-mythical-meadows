# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Slime
extends CharacterBody2D

enum State {
	IDLE,
	WANDERING,
	RETURNING,
	DETECTING,
	ALERTED,
	ATTACKING,
}

const FAST_DETECT_TIME: float = 0.2
const MAX_SPEED: float = 300

@export var debug_mode: bool = false
@export var time_to_detect_player: float = 1.2
@export var instantly_detect: bool = true

@export_category("Movement")
@export var chase_speed: float = 250
@export_range(1.0, 10.0, 0.5, "suffix:s") var idle_wait_time: float = 3.0
@export_range(1.0, 30.0, 0.5, "suffix:s") var wandering_duration: float = 10.0
@export var burst_deceleration: float = 400.0

@export_category("Sounds")
@export var alert_sound_stream: AudioStream:
	set = _set_alert_sound_stream

@export_category("Música del Nivel")
@export var musica_persecucion: AudioStream
var musica_cambiada: bool = false

@export_category("Cinemática de Muerte")
var secuencia_muerte_activa: bool = false
var fase_muerte: int = 0
var punto_caida: Vector2
var timer_muerte: float = 0.0

@export var capa_suelo_roto: TileMapLayer

@export_category("Efectos de Sonido del Jefe")
@export var sfx_jump: AudioStream
@export var sfx_land: AudioStream
@export var sfx_clone: AudioStream
@export var sfx_laser: AudioStream
@export var sfx_warning: AudioStream
@export var sfx_impact: AudioStream

@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer

var state: State = State.IDLE:
	set = _set_state
var _awareness: float = 0.0
var _player: CharacterBody2D = null
var _initial_position: Vector2
var _return_direction: Vector2
var _return_start_position: Vector2
var _stuck_timer: float = 0.0
var _max_stuck_time: float = 2.0
var _reached_max_speed: bool = false
var _current_chase_speed: float = 0.0
var _can_burst: bool = false
var _previous_non_detecting_state: State = State.IDLE

var frases_troll: Array = ["¡Esquiva esto!", "¡Gelatina letal!", "¿Cansado?", "¡Sorpresa!", "¡Soy tu sombra!", "¡Buuu!"]
var frases_ataque: Array = ["¡ZAS!", "¡KABOOM!", "¡Toma esto!", "¡Láser!", "¡PUM!", "¡Destrucción!"]
var talk_timer: float = 0.0
var dash_state: int = 0 
var dash_timer: float = 3.0 
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed: float = 2800.0 
var dash_horizontal: bool = true 
var dash_desde_negativo: bool = true
var carril_real: int = 0 
var mini_slime_scene = preload("res://scenes/game_elements/characters/enemies/slime/mini_slime/mini_slime.tscn") 
var es_ataque_lluvia: bool = false 
var posicion_fija_dialogo: Vector2
var fase_enojo: bool = false
var ataques_desactivados: bool = false

@onready var detection_area: Area2D = %DetectionArea
@onready var awareness_bar: TextureProgressBar = %PlayerAwareness
@onready var erratic_walk_behavior: ErraticWalkBehavior = %ErraticWalkBehavior
@onready var behavior_timer: Timer = %BehaviorTimer
@onready var debug_label: Label = %DebugInfo
@onready var attack_radius: Area2D = %AttackRadius
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var char_sprite_behavior: CharacterSpriteBehavior = %CharacterSpriteBehavior
@onready var _alert_sound: AudioStreamPlayer = %AlertSound

@onready var texto_troll = get_node_or_null("Burbuja/TextoTroll") if get_node_or_null("Burbuja/TextoTroll") else get_node_or_null("TextoTroll")
@onready var burbuja = get_node_or_null("Burbuja")
@onready var alerta1 = get_node_or_null("Alerta")
@onready var alerta2 = get_node_or_null("Alerta2")
@onready var alerta3 = get_node_or_null("Alerta3")
@onready var ilusion1 = get_node_or_null("Ilusion1")
@onready var ilusion2 = get_node_or_null("Ilusion2")

func _ready() -> void:
	if is_instance_valid(debug_label):
		debug_label.visible = debug_mode
	awareness_bar.max_value = time_to_detect_player
	awareness_bar.value = 0.0
	awareness_bar.visible = false
	_set_alert_sound_stream(alert_sound_stream)
	_initial_position = global_position
	state = State.IDLE

func _physics_process(delta: float) -> void:
	if secuencia_muerte_activa:
		if fase_muerte == 100:
			reproducir_sonido(sfx_jump)
			if is_instance_valid(animated_sprite): animated_sprite.play("jump")
			if is_instance_valid(char_sprite_behavior): char_sprite_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			fase_muerte = 101
			
		elif fase_muerte == 101:
			global_position.y -= 4500 * delta
			if global_position.y < _player.global_position.y - 1500:
				
				var distancia = 500 
				var distancia_espalda = -distancia if _player.global_position.x < punto_caida.x else distancia
				global_position.x = _player.global_position.x + distancia_espalda
				fase_muerte = 102
				
		elif fase_muerte == 102:
			global_position.y += 4500 * delta
			if global_position.y >= _player.global_position.y:
				global_position.y = _player.global_position.y
				
				posicion_fija_dialogo = global_position 
				
				reproducir_sonido(sfx_land)
				if is_instance_valid(animated_sprite): animated_sprite.play("idle")
				fase_muerte = 1 
				
		elif fase_muerte == 1:
			velocity = Vector2.ZERO
			global_position = posicion_fija_dialogo
			
			if is_instance_valid(texto_troll):
				texto_troll.text = "¡MALDITO TEJEDOR!\n¡TE APLASTARÉ CON\nTODO MI PODER!"
			if is_instance_valid(burbuja): burbuja.visible = true
			
			timer_muerte = 2.0 
			fase_muerte = 2
			
		elif fase_muerte == 2:
			velocity = Vector2.ZERO
			global_position = posicion_fija_dialogo
			
			timer_muerte -= delta
			if timer_muerte <= 0.0:
				if is_instance_valid(burbuja): burbuja.visible = false
				if is_instance_valid(texto_troll): texto_troll.text = "" 
				
				reproducir_sonido(sfx_jump)
				if is_instance_valid(animated_sprite): animated_sprite.play("jump")
				
				if is_instance_valid(_player):
					_player.velocity = Vector2.ZERO 
					_player.process_mode = Node.PROCESS_MODE_INHERIT
					
				fase_muerte = 3
				
		elif fase_muerte == 3:
			global_position.y -= 3500 * delta
			if global_position.y <= punto_caida.y - 1500:
				global_position.x = punto_caida.x 
				fase_muerte = 4
				
		elif fase_muerte == 4:
			global_position.y += 4500 * delta
			if global_position.y >= punto_caida.y:
				global_position = punto_caida
				
				reproducir_sonido(sfx_land)
				
				romper_suelo() 
				
				if is_instance_valid(animated_sprite): animated_sprite.play("idle")
				fase_muerte = 5
				timer_muerte = 0.8
				
		elif fase_muerte == 5:
			timer_muerte -= delta
			if timer_muerte <= 0.0:
				fase_muerte = 6
				reproducir_sonido(sfx_laser) 
				
		elif fase_muerte == 6:
			global_position.y += 1200 * delta
			scale = scale.move_toward(Vector2.ZERO, delta * 1.5)
			if scale.x <= 0.05:
				queue_free()
				
		return
		
	if state != State.ALERTED and state != State.ATTACKING:
		_update_detection(delta)

	_process_movement(delta)

	var was_colliding: bool = is_on_wall()
	move_and_slide()
	var is_colliding: bool = is_on_wall()

	if state == State.RETURNING and is_colliding and not was_colliding:
		var angle_offset: float = PI / 4.0
		if randf() < 0.5:
			angle_offset *= -1
		_return_direction = _return_direction.rotated(angle_offset)
	elif state == State.RETURNING and not is_colliding:
		_return_direction = global_position.direction_to(_initial_position)

	if not debug_mode and state == State.ALERTED and is_instance_valid(_player):
		if attack_radius.overlaps_body(_player):
			state = State.ATTACKING

	_check_if_stuck(delta)

	if state == State.ALERTED and is_instance_valid(_player):
		talk_timer -= delta
		if talk_timer <= 0.0:
			lanzar_comentario_inteligente(frases_troll[randi() % frases_troll.size()])
			talk_timer = randf_range(4.0, 7.0) 
	else:
		if is_instance_valid(texto_troll): texto_troll.text = ""
		if is_instance_valid(burbuja): burbuja.visible = false

	if debug_mode:
		_update_debug_info()


func _process_movement(delta: float) -> void:
	var walk_speed: float = 0.0
	if erratic_walk_behavior.get("speeds"):
		walk_speed = erratic_walk_behavior.speeds.walk_speed

	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			_reached_max_speed = false

		State.WANDERING:
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			erratic_walk_behavior._physics_process(delta)
			velocity = velocity.lerp(erratic_walk_behavior.direction * walk_speed, 0.1)
			_reached_max_speed = false

		State.RETURNING:
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			velocity = _return_direction * walk_speed
			_reached_max_speed = false
			if global_position.distance_to(_initial_position) < 5.0:
				global_position = _initial_position
				state = State.IDLE

		State.DETECTING:
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			
			if is_instance_valid(_player):
				var direction_to_player: Vector2 = global_position.direction_to(_player.global_position)
				velocity = velocity.lerp(direction_to_player * (walk_speed * 0.5), 0.15)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			_reached_max_speed = false

		State.ALERTED:
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			
			if not musica_cambiada:
				musica_cambiada = true
				var nodo_musica = get_tree().current_scene.get_node_or_null("BackgroundMusic")
				
				if is_instance_valid(nodo_musica) and is_instance_valid(musica_persecucion):
					nodo_musica.stream = musica_persecucion
					nodo_musica.play()

			if is_instance_valid(_player):
				var direction_to_player: Vector2 = global_position.direction_to(_player.global_position)
				var distancia = global_position.distance_to(_player.global_position)

				if dash_state == 0:
					if fase_enojo:
						_current_chase_speed = chase_speed * 1.6 
						if is_instance_valid(animated_sprite):
							animated_sprite.modulate = Color(1.0, 0.3, 0.3) 
						if is_instance_valid(char_sprite_behavior):
							char_sprite_behavior.process_mode = Node.PROCESS_MODE_INHERIT 
					else:
						_current_chase_speed = chase_speed
						if is_instance_valid(animated_sprite):
							animated_sprite.modulate = Color(1.0, 1.0, 1.0) 
						if is_instance_valid(char_sprite_behavior):
							char_sprite_behavior.process_mode = Node.PROCESS_MODE_DISABLED
					
					velocity = direction_to_player * _current_chase_speed
					
					if is_instance_valid(animated_sprite):
						if direction_to_player.x > 0:
							animated_sprite.flip_h = false 
						elif direction_to_player.x < 0:
							animated_sprite.flip_h = true
					
					if distancia > 3500.0:
						var offset_x = 1000 if randf() > 0.5 else -1000
						global_position = _player.global_position + Vector2(offset_x, -50)
					
					dash_timer -= delta
					if dash_timer <= 0.0 and distancia > 900.0 and not ataques_desactivados:
						es_ataque_lluvia = randf() > 0.6 
						
						if es_ataque_lluvia:
							dash_state = 10 
							dash_timer = 0.5 
						else:
							dash_state = 1 
							dash_timer = 0.35 
							
						if is_instance_valid(texto_troll):
							texto_troll.text = "¡Mira arriba!" if es_ataque_lluvia else "¡Preparate!"
							if is_instance_valid(burbuja): burbuja.visible = true
							
						reproducir_sonido(sfx_warning)

				elif dash_state == 10:
					velocity = Vector2.ZERO 
					
					var punto_cielo = _player.global_position + Vector2(600, -1500)
					
					global_position = global_position.move_toward(punto_cielo, 4500 * delta)
					
					if is_instance_valid(char_sprite_behavior):
						char_sprite_behavior.process_mode = Node.PROCESS_MODE_DISABLED
					if is_instance_valid(animated_sprite):
						animated_sprite.play("jump")
						
					if dash_timer == 0.5: 
						reproducir_sonido(sfx_jump)
					
					if is_instance_valid(burbuja): burbuja.visible = false
					if is_instance_valid(texto_troll): texto_troll.text = ""
					
					dash_timer -= delta
					if dash_timer <= 0.0:
						dash_state = 50 
						dash_timer = 1.0 

				elif dash_state == 50:
					velocity = Vector2.ZERO 
					
					global_position.x = _player.global_position.x + 600
					
					if is_instance_valid(animated_sprite):
						animated_sprite.flip_h = true
					
					global_position.y += 4500 * delta
					
					dash_timer -= delta
					if dash_timer <= 0.0 or global_position.y >= _player.global_position.y:
						global_position.y = _player.global_position.y 
						dash_state = 51
						dash_timer = 0.5 
						
						reproducir_sonido(sfx_land)
						
						if is_instance_valid(animated_sprite):
							animated_sprite.play("idle")

				elif dash_state == 51:
					velocity = Vector2.ZERO
					dash_timer -= delta
					if dash_timer <= 0.0:
						dash_state = 5 
						dash_timer = 1.5 
						
						if is_instance_valid(texto_troll):
							texto_troll.text = "¡Ataquen, mis clones!"
							if is_instance_valid(burbuja): burbuja.visible = true
							
						if is_instance_valid(animated_sprite):
							animated_sprite.play("cloning")
							
						reproducir_sonido(sfx_clone)
							
						if mini_slime_scene:
							for i in range(3):
								var mini = mini_slime_scene.instantiate()
								mini._player = _player 
								var offset_x = -100 + (i * 100) 
								mini.global_position = self.global_position + Vector2(offset_x, 0)
								get_parent().call_deferred("add_child", mini)

				elif dash_state == 1:
					velocity = Vector2.ZERO 
					global_position += Vector2(0, -4000) * delta
					
					if is_instance_valid(char_sprite_behavior):
						char_sprite_behavior.process_mode = Node.PROCESS_MODE_DISABLED
					if is_instance_valid(animated_sprite):
						animated_sprite.play("jump")
						
					if dash_timer == 0.35:
						reproducir_sonido(sfx_jump)
					
					if is_instance_valid(burbuja): burbuja.visible = false
					if is_instance_valid(texto_troll): texto_troll.text = ""
					if is_instance_valid(alerta2): alerta2.visible = false
					if is_instance_valid(alerta3): alerta3.visible = false
					if is_instance_valid(ilusion1): ilusion1.visible = false
					if is_instance_valid(ilusion2): ilusion2.visible = false
					
					dash_timer -= delta
					if dash_timer <= 0.0:
						dash_state = 2
						dash_timer = 1.0 
						
						reproducir_sonido(sfx_warning)
						
						dash_horizontal = randf() > 0.5 
						dash_desde_negativo = randf() > 0.5 
						
						if dash_horizontal:
							var offset_x = -1200 if dash_desde_negativo else 1200
							global_position = _player.global_position + Vector2(offset_x, 0)
							
							if is_instance_valid(animated_sprite):
								animated_sprite.play("walk")
								animated_sprite.frame = 16 
							if is_instance_valid(char_sprite_behavior):
								char_sprite_behavior.process_mode = Node.PROCESS_MODE_DISABLED
						else:
							var offset_y = -1200 if dash_desde_negativo else 1200
							global_position = _player.global_position + Vector2(0, offset_y)
							
							if is_instance_valid(char_sprite_behavior):
								char_sprite_behavior.process_mode = Node.PROCESS_MODE_INHERIT
							
							carril_real = randi() % 3
							if is_instance_valid(ilusion1): ilusion1.visible = true
							if is_instance_valid(ilusion2): ilusion2.visible = true
						
						if is_instance_valid(alerta1):
							alerta1.set_as_top_level(true)
							alerta1.visible = true

				elif dash_state == 2:
					velocity = Vector2.ZERO 
					
					var cam = get_viewport().get_camera_2d()
					var centro_camara = cam.global_position if cam else _player.global_position
					
					if dash_horizontal:
						var dist_x = -1200 if dash_desde_negativo else 1200
						global_position.x = _player.global_position.x + dist_x
						global_position.y = _player.global_position.y 
						
						if is_instance_valid(alerta1):
							var warn_x = -500 if dash_desde_negativo else 500
							alerta1.global_position = Vector2(centro_camara.x + warn_x, _player.global_position.y)
							alerta1.rotation = PI / 2.0 if dash_desde_negativo else -(PI / 2.0)
							alerta1.visible = int(Time.get_ticks_msec() / 50) % 2 == 0
							
						dash_direction = Vector2.RIGHT if dash_desde_negativo else Vector2.LEFT
					else:
						var dist_y = -1200 if dash_desde_negativo else 1200
						var warn_y = -350 if dash_desde_negativo else 350
						var rot_alerta = PI if dash_desde_negativo else 0.0
						var carriles = [-350, 0, 350] 

						global_position.x = _player.global_position.x + carriles[carril_real]
						global_position.y = _player.global_position.y + dist_y
						
						var parpadeo = int(Time.get_ticks_msec() / 50) % 2 == 0
						
						if is_instance_valid(alerta1):
							alerta1.global_position = Vector2(global_position.x, centro_camara.y + warn_y)
							alerta1.rotation = rot_alerta
							alerta1.visible = parpadeo

						var c_ilu1 = (carril_real + 1) % 3
						if is_instance_valid(ilusion1):
							ilusion1.global_position = Vector2(_player.global_position.x + carriles[c_ilu1], global_position.y)
							if is_instance_valid(alerta2):
								alerta2.global_position = Vector2(ilusion1.global_position.x, centro_camara.y + warn_y)
								alerta2.rotation = rot_alerta
								alerta2.visible = parpadeo

						var c_ilu2 = (carril_real + 2) % 3
						if is_instance_valid(ilusion2):
							ilusion2.global_position = Vector2(_player.global_position.x + carriles[c_ilu2], global_position.y)
							if is_instance_valid(alerta3):
								alerta3.global_position = Vector2(ilusion2.global_position.x, centro_camara.y + warn_y)
								alerta3.rotation = rot_alerta
								alerta3.visible = parpadeo

						dash_direction = Vector2.DOWN if dash_desde_negativo else Vector2.UP

					dash_timer -= delta
					if dash_timer <= 0.0:
						dash_state = 3
						dash_timer = 0.25 
						if is_instance_valid(alerta1): alerta1.visible = true
						if is_instance_valid(alerta2) and ilusion1 and ilusion1.visible: alerta2.visible = true
						if is_instance_valid(alerta3) and ilusion2 and ilusion2.visible: alerta3.visible = true
						
						if is_instance_valid(texto_troll):
							texto_troll.text = "¡Fijo!" if dash_horizontal else "¡Adivina!"
							if is_instance_valid(burbuja): burbuja.visible = true
							
				elif dash_state == 3:
					velocity = Vector2.ZERO 
					dash_timer -= delta
					if dash_timer <= 0.0:
						dash_state = 4
						dash_timer = 1.0 
						_current_chase_speed = dash_speed 
						
						if is_instance_valid(animated_sprite):
							animated_sprite.play("walk") 
							animated_sprite.frame = 16
						reproducir_sonido(sfx_laser)
						
						if is_instance_valid(texto_troll):
							texto_troll.text = frases_ataque[randi() % frases_ataque.size()]
							if is_instance_valid(burbuja): burbuja.visible = true

				elif dash_state == 4:
					velocity = Vector2.ZERO 
					global_position += dash_direction * _current_chase_speed * delta
					
					if is_instance_valid(ilusion1) and ilusion1.visible:
						ilusion1.global_position += dash_direction * _current_chase_speed * delta
					if is_instance_valid(ilusion2) and ilusion2.visible:
						ilusion2.global_position += dash_direction * _current_chase_speed * delta
						
					dash_timer -= delta
					if dash_timer <= 0.0:
						if is_instance_valid(alerta1): alerta1.visible = false 
						if is_instance_valid(alerta2): alerta2.visible = false 
						if is_instance_valid(alerta3): alerta3.visible = false 
						if is_instance_valid(ilusion1): ilusion1.visible = false 
						if is_instance_valid(ilusion2): ilusion2.visible = false 

						if dash_horizontal:
							dash_state = 0 
							dash_timer = randf_range(1.5, 3.0) 
							talk_timer = 0.0 
							
							reproducir_sonido(sfx_impact)
							
							if is_instance_valid(char_sprite_behavior):
								char_sprite_behavior.process_mode = Node.PROCESS_MODE_INHERIT
							
						else:
							dash_state = 60

				elif dash_state == 60:
					velocity = Vector2.ZERO
					global_position = _player.global_position + Vector2(600, -1200)
					
					if is_instance_valid(char_sprite_behavior):
						char_sprite_behavior.process_mode = Node.PROCESS_MODE_DISABLED
					if is_instance_valid(animated_sprite):
						animated_sprite.play("jump")
						
					reproducir_sonido(sfx_jump)
					
					dash_state = 61

				elif dash_state == 61:
					velocity = Vector2.ZERO 
					global_position += Vector2(0, 4500) * delta
					
					if global_position.y >= _player.global_position.y:
						global_position.y = _player.global_position.y 
						
						reproducir_sonido(sfx_land)
						
						if is_instance_valid(animated_sprite) and animated_sprite.animation == "jump":
							animated_sprite.play("idle")
						if is_instance_valid(char_sprite_behavior):
							char_sprite_behavior.process_mode = Node.PROCESS_MODE_INHERIT
							
						dash_state = 0 
						dash_timer = randf_range(1.5, 3.0) 
						talk_timer = 0.0

				elif dash_state == 5:
					velocity = Vector2.ZERO 
					
					dash_timer -= delta
					if dash_timer <= 0.0:
						dash_state = 0 
						dash_timer = randf_range(1.5, 3.0) 
						talk_timer = 0.0 
						if is_instance_valid(burbuja): burbuja.visible = false
						
						if is_instance_valid(animated_sprite):
							animated_sprite.play("idle")
						if is_instance_valid(char_sprite_behavior):
							char_sprite_behavior.process_mode = Node.PROCESS_MODE_INHERIT
				
				_reached_max_speed = true
			else:
				_reached_max_speed = false

## Checks if stuck in RETURNING state and forces WANDERING if so.
func _check_if_stuck(delta: float) -> void:
	if state == State.RETURNING:
		var distance_moved: float = global_position.distance_to(_return_start_position)

		if distance_moved < 10.0:
			_stuck_timer += delta
		else:
			_stuck_timer = 0.0
			_return_start_position = global_position

		if _stuck_timer >= _max_stuck_time:
			state = State.WANDERING
			_stuck_timer = 0.0


## Updates player awareness level and manages state transitions to DETECTING and ALERTED.
func _update_detection(delta: float) -> void:
	var target_awareness: float = 0.0
	var awareness_speed: float = 1.0

	if is_instance_valid(_player):
		target_awareness = time_to_detect_player

		if state == State.IDLE or state == State.WANDERING:
			_previous_non_detecting_state = state

		if state != State.ALERTED and state != State.ATTACKING:
			state = State.DETECTING

		if instantly_detect:
			awareness_speed = time_to_detect_player / FAST_DETECT_TIME
	else:
		target_awareness = 0.0

	if _awareness < target_awareness:
		_awareness = move_toward(_awareness, target_awareness, delta * awareness_speed)
	else:
		_awareness = move_toward(_awareness, target_awareness, delta * 1.0)

	awareness_bar.value = _awareness
	awareness_bar.visible = awareness_bar.ratio > 0.0
	awareness_bar.modulate.a = clamp(awareness_bar.ratio, 0.5, 1.0)

	if _awareness >= time_to_detect_player:
		state = State.ALERTED
	elif (
		_awareness == 0.0
		and state != State.IDLE
		and state != State.WANDERING
		and state != State.RETURNING
		and state != State.ATTACKING
	):
		state = State.WANDERING


## Changes the current state and performs associated transition actions.
func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	behavior_timer.stop()

	if char_sprite_behavior:
		char_sprite_behavior.play_animations = true

	match state:
		State.IDLE:
			_alert_sound.stop()
			behavior_timer.start(idle_wait_time)
			awareness_bar.tint_progress = Color.WHITE
			_reached_max_speed = false

		State.WANDERING:
			behavior_timer.start(wandering_duration)
			erratic_walk_behavior._update_direction()
			_reached_max_speed = false

		State.RETURNING:
			_return_direction = global_position.direction_to(_initial_position)
			_return_start_position = global_position
			_stuck_timer = 0.0
			_reached_max_speed = false

		State.DETECTING:
			if not _alert_sound.playing:
				_alert_sound.play()
			awareness_bar.tint_progress = Color.WHITE
			_reached_max_speed = false

			if char_sprite_behavior:
				char_sprite_behavior.play_animations = false
			if is_instance_valid(animated_sprite):
				animated_sprite.play("attack_anticipation")

		State.ALERTED:
			if not _alert_sound.playing:
				_alert_sound.play()
			awareness_bar.value = awareness_bar.max_value
			awareness_bar.tint_progress = Color.RED
			awareness_bar.modulate.a = 1.0
			_reached_max_speed = true

			if char_sprite_behavior:
				char_sprite_behavior.play_animations = false
			if is_instance_valid(animated_sprite):
				animated_sprite.play("attack_anticipation")

			if is_instance_valid(_player):
				_current_chase_speed = chase_speed

				var direction_to_player: Vector2 = global_position.direction_to(
					_player.global_position
				)
				velocity = direction_to_player * _current_chase_speed

		State.ATTACKING:
			if char_sprite_behavior:
				char_sprite_behavior.play_animations = false
			if is_instance_valid(animated_sprite):
				animated_sprite.play("attack")


func _set_alert_sound_stream(new_value: AudioStream) -> void:
	alert_sound_stream = new_value
	if not is_node_ready():
		await ready
	_alert_sound.stream = new_value


## Called when a body enters the detection area.
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_awareness = 0.0
		if state != State.ALERTED:
			pass


## Called when a body exits the detection area.
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if state == State.DETECTING:
			state = State.RETURNING


## Called when behavior timer times out during IDLE or WANDERING states.
func _on_BehaviorTimer_timeout() -> void:
	match state:
		State.IDLE:
			state = State.WANDERING
		State.WANDERING:
			state = State.RETURNING


## Called when a body enters the attack radius.
## Ignored if debug mode is enabled.
func _on_attack_radius_body_entered(body: Node2D) -> void:
	if debug_mode:
		return

	if body.is_in_group("player"):
		if state != State.ATTACKING:
			state = State.ATTACKING

		if body.has_method("defeat"):
			var player: Node2D = body
			player.defeat()


## Called when the attack animation finishes.
## Returns to ALERTED state to resume chasing the player.
func _on_animated_sprite_animation_finished() -> void:
	if state == State.ATTACKING and animated_sprite.animation == "attack":
		state = State.ALERTED


## Updates the debugging information display.
## Only called when debug mode is enabled.
func _update_debug_info() -> void:
	if not is_instance_valid(debug_label):
		return

	var debug_text: String = "pos: (%.1f, %.1f)\n" % [global_position.x, global_position.y]
	debug_text += "state: %s" % State.keys()[state].to_lower()

	if behavior_timer.time_left > 0:
		debug_text += " (%.1fs)" % behavior_timer.time_left

	debug_text += "\n"

	var current_speed: float = velocity.length()
	var target_speed: float = 0.0
	var speed_label: String = "n/a"

	if state == State.ALERTED:
		target_speed = chase_speed
		speed_label = "chase"

		if _current_chase_speed > chase_speed + 5:
			debug_text += "current speed: %d\n" % current_speed
			debug_text += "burst speed: %d (decaying)\n" % _current_chase_speed
			debug_text += "target speed: %d (%s) [burst!]" % [target_speed, speed_label]
		else:
			debug_text += "current speed: %d\n" % current_speed
			debug_text += "target speed: %d (%s)" % [target_speed, speed_label]

	elif state == State.WANDERING or state == State.RETURNING:
		if erratic_walk_behavior.get("speeds"):
			target_speed = erratic_walk_behavior.speeds.walk_speed
			speed_label = "walk"
		debug_text += "current speed: %d\n" % current_speed
		debug_text += "target speed: %d (%s)" % [target_speed, speed_label]

	elif state == State.ATTACKING:
		debug_text += "current speed: 0\n"
		debug_text += "target speed: 0 (ATTACKING)"

	else:
		debug_text += "current speed: %d\n" % current_speed
		debug_text += "target speed: 0 (idle)"

	debug_label.text = debug_text

func hablar(mensaje: String) -> void:
	if is_instance_valid(burbuja) and is_instance_valid(texto_troll):
		if mensaje == "":
			burbuja.visible = false
			texto_troll.text = ""
		else:
			burbuja.visible = true
			texto_troll.text = mensaje
			
func reproducir_sonido(sonido: AudioStream) -> void:
	if sonido and is_instance_valid(sfx_player):
		sfx_player.stream = sonido
		sfx_player.play()

func limpiar_efectos_ataque() -> void:
	if is_instance_valid(alerta1): alerta1.visible = false
	if is_instance_valid(alerta2): alerta2.visible = false
	if is_instance_valid(alerta3): alerta3.visible = false
	if is_instance_valid(ilusion1): ilusion1.visible = false
	if is_instance_valid(ilusion2): ilusion2.visible = false
	hablar("")

func iniciar_muerte(punto: Vector2) -> void:
	secuencia_muerte_activa = true
	fase_muerte = 100
	punto_caida = punto
	velocity = Vector2.ZERO
	
	limpiar_efectos_ataque()
	
	var nodo_musica = get_tree().current_scene.get_node_or_null("BackgroundMusic")
	if nodo_musica:
		nodo_musica.stop()

	congelar_jugador_cinematica()

func congelar_jugador_cinematica() -> void:
	if is_instance_valid(_player):
		_player.velocity = Vector2.ZERO
		
		_player.process_mode = Node.PROCESS_MODE_DISABLED
		
		var sprite = _player.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.animation = "idle"
			sprite.frame = 0

func desactivar_ataques() -> void:
	ataques_desactivados = true
	dash_state = 0
	
	limpiar_efectos_ataque()
	
	if is_instance_valid(animated_sprite):
		animated_sprite.play("walk")

func lanzar_comentario_inteligente(texto: String) -> void:
	hablar(texto)
	
	await get_tree().create_timer(2.5).timeout
	
	if dash_state == 0:
		hablar("")

func romper_suelo() -> void:
	if not is_instance_valid(capa_suelo_roto): 
		return
		
	var pos_local = capa_suelo_roto.to_local(punto_caida)
	var tile_pos = capa_suelo_roto.local_to_map(pos_local)
	
	for x in range(-2, 3):
		for y in range(-2, 3):
			capa_suelo_roto.set_cell(tile_pos + Vector2i(x, y), -1)
			

func activar_furia() -> void:
	if not fase_enojo:
		fase_enojo = true
		
		if is_instance_valid(animated_sprite):
			animated_sprite.modulate = Color(1.0, 0.3, 0.3)
			
		lanzar_comentario_inteligente("¡MALDITO, NO ESCAPARÁS!")
