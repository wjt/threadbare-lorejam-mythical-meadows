extends Node2D
# Esta función se creará automáticamente al conectar la señal
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entró es el jugador
	if body.name == "Player" or body.is_in_group("Player"):
		print("¡Flor recolectada!")
		
		# Ocultamos la flor inmediatamente
		visible = false
		
		# Esperamos un breve momento para que se note la acción (opcional)
		await get_tree().create_timer(0.5).timeout
		
		# Terminamos el juego cerrando la ventana
		get_tree().quit()
