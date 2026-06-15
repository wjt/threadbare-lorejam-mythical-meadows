extends PointLight2D

@export var speed: float = 1.5
@export var min_energy: float = 0.8
@export var max_energy: float = 2.0

func _process(delta):
	energy = lerp(min_energy, max_energy,
				  0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * speed))
