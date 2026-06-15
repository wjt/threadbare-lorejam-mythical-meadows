extends Node

@export var min_time: float = 15.0
@export var max_time: float = 35.0

@export var flash_alpha: float = 0.9
@export var flash_hold_time: float = 0.12
@export var fade_time: float = 1.2

@onready var flash: ColorRect = $"../CanvasLayer/ThunderFlash"
@onready var thunder_sound: AudioStreamPlayer = $"../CanvasLayer/ThunderSound"


func _ready() -> void:
	rain_sound.finished.connect(_on_rain_finished)
	rain_sound.play()
	flash.color = Color(1, 1, 1, 0)
	start_thunder_loop()



func start_thunder_loop() -> void:
	while true:
		var wait_time := randf_range(min_time, max_time)
		await get_tree().create_timer(wait_time).timeout
		await do_thunder()


func do_thunder() -> void:
	# Sonido y destello al mismo tiempo
	thunder_sound.play()

	# Pantalla blanca intensa
	flash.color = Color(1, 1, 1, flash_alpha)

	# Mantener un instante
	await get_tree().create_timer(flash_hold_time).timeout

	# Volver gradualmente a la normalidad
	var tween := create_tween()
	tween.tween_property(
		flash,
		"color",
		Color(1, 1, 1, 0),
		fade_time
	)
	
@onready var rain_sound: AudioStreamPlayer = $"../CanvasLayer/RainSound"


func _on_rain_finished() -> void:
	rain_sound.play()
