extends CanvasLayer

@onready var continue_button = $Panel/Continue

func _ready():
	if continue_button:
		if continue_button.pressed.is_connected(_on_continue_pressed):
			continue_button.pressed.disconnect(_on_continue_pressed)
		continue_button.pressed.connect(_on_continue_pressed)
		print("✅ Botón conectado correctamente")

func show_victory(saved: int, total: int):
	print("🏆 Victoria! ", saved, "/", total)
	
	var butterflies_label = $Panel/ButterfliesLabel
	if butterflies_label:
		butterflies_label.text = "Mariposas salvadas: " + str(saved) + "/" + str(total)
	
	var percentage = float(saved) / float(total) * 100.0
	var rating = ""
	
	if percentage >= 90:
		rating = "⭐⭐⭐⭐⭐ ORO"
	elif percentage >= 70:
		rating = "⭐⭐⭐⭐ PLATA"
	elif percentage >= 50:
		rating = "⭐⭐⭐ BRONCE"
	else:
		rating = "⭐⭐ PASABLE"
	
	var rating_label = $Panel/RatingLabel
	if rating_label:
		rating_label.text = rating

func _on_continue_pressed():
	print("🔄 Iniciando cambio de nivel...")
	
	# Ruta exacta respetando el espacio: "Juego 3 .tscn"
	var next_scene = "res://scenes/quests/lore_quests/quest_004/Minijuego_Guardian Biel/Juego 3 .tscn"
	
	await get_tree().process_frame
	
	if ResourceLoader.exists(next_scene):
		print("✅ Escena encontrada. Cambiando a Juego 3...")
		get_tree().change_scene_to_file(next_scene)
		# Eliminamos la pantalla de victoria RECIÉN cuando el cambio está en marcha
		queue_free()
	else:
		print("❌ ERROR CRÍTICO: No se encuentra la ruta: ", next_scene)
		# Si falla, reinicia el minijuego 2 para que no se quede congelado el juego
		get_tree().reload_current_scene()
