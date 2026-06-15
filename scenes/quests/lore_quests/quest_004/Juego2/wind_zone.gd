#wind_zone

extends Area2D

@export var wind_strength: float = 500.0
@export var wind_direction: Vector2 = Vector2.RIGHT

@onready var wind_particles = $WindParticles
@onready var warning_particles = $WarningParticles

func _ready():
	body_entered.connect(_on_body_entered)
	_setup_wind_particles()
	_setup_warning_particles()

func _setup_wind_particles():
	if not wind_particles:
		return
	
	wind_particles.amount = 40
	wind_particles.lifetime = 1.2
	wind_particles.emitting = true
	wind_particles.one_shot = false
	wind_particles.emission_shape = 3  # RECTANGLE
	wind_particles.emission_rect_extents = Vector2(200, 80)
	wind_particles.direction = wind_direction
	wind_particles.spread = 15.0
	wind_particles.initial_velocity_min = 150
	wind_particles.initial_velocity_max = 250
	wind_particles.gravity = Vector2.ZERO
	wind_particles.scale_amount_min = 0.3
	wind_particles.scale_amount_max = 0.8
	wind_particles.color = Color(0.85, 0.9, 1.0, 0.4)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.velocity += wind_direction * wind_strength

func _setup_warning_particles():
	if not warning_particles:
		return
	
	#ADVERTENCIA
	warning_particles.amount = 15
	warning_particles.lifetime = 0.8
	warning_particles.one_shot = true
	warning_particles.emitting = false
	warning_particles.emission_shape = 3  
	warning_particles.emission_rect_extents = Vector2(60, 30)
	warning_particles.direction = Vector2(0, -1) 
	warning_particles.spread = 40.0
	warning_particles.initial_velocity_min = 50
	warning_particles.initial_velocity_max = 100
	warning_particles.gravity = Vector2(0, -20)  
	warning_particles.scale_amount_min = 0.2
	warning_particles.scale_amount_max = 0.5
	warning_particles.color = Color(1, 0.6, 0.2, 0.7)
	
func _on_warning_timer_timeout():
	if warning_particles:
		warning_particles.emitting = true
		await get_tree().create_timer(1.0).timeout
		warning_particles.emitting = false
