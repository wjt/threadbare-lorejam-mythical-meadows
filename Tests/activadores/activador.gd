extends Area2D

# Esta variable recibirá la referencia directa de la escena Salida mediante el script generador
var salida_vinculada: Area2D = null
var presionado: bool = false


func _ready() -> void:
	# Conectamos la señal nativa de Godot para detectar colisiones de cuerpos
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not presionado:
		presionado = true
		print("[MECÁNICA] ¡Activador presionado por el Jugador!")
		# TODO: Cambiar la textura del botón a "hundido" o activar sonido

		# Si la inyección fue correcta, encendemos la salida remotamente
		if is_instance_valid(salida_vinculada):
			salida_vinculada.encender_salida()
