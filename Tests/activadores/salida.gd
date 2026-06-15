extends Area2D

var abierta: bool = false


func _ready() -> void:
	# Al spawnear, desactivamos la colisión física para que el jugador no escape antes de tiempo
	$CollisionShape2D.disabled = true
	# TODO: Cambiar el sprite a su estado cerrado/apagado


func encender_salida() -> void:
	if abierta:
		return
	abierta = true
	set_deferred("monitoring", true)  # Activa la detección de la salida de forma segura
	$CollisionShape2D.set_deferred("disabled", false)  # Desactiva el bloqueo de la colisión

	print("[SISTEMA] ¡La salida ha sido desbloqueada e iluminada!")
	# TODO: Reproducir animación de apertura o cambiar el Sprite visual


func _on_body_entered(body: Node2D) -> void:
	if body is Player and abierta:
		print("[SISTEMA] ¡El jugador cruzó la salida con éxito!")
		# Aquí llamas a tu lógica de cambiar de nivel
