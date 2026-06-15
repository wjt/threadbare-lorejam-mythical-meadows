extends Control

@onready var label: Label = $Label
@onready var timer: Timer = $Timer
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var bloques_creditos := [
	{
		"text": "Threadbare: Mythical Meadows",
		"font_size": 68,
		"wait_after": 2.0
	},
	{
		"text": "Desarrollado por:\nDiego Mayora\nFrancisco Ganoza\nJosé Chris\nAdrian Cornejo",
		"font_size": 56,
		"wait_after": 2.5
	},
	{
		"text": "Diseño del juego:\nDiego Mayora",
		"font_size": 56,
		"wait_after": 2.5
	},
	{
		"text": "Programación:\nFrancisco Ganoza\nAdrian Cornejo",
		"font_size": 56,
		"wait_after": 2.5
	},
	{
		"text": "Arte y escenarios:\nJosé Chris\nAdrian Cornejo",
		"font_size": 56,
		"wait_after": 2.5
		
	},
		{
		"text": "Diseño de personajes:\nJosé Chris",
		"font_size": 56,
		"wait_after": 2.5
	},
		{
		"text": "Composición musical y diseño de sonido:\nEduardo Mosquera (DeChillGames)\nEndless Studios",
		"font_size": 56,
		"wait_after": 2.5
	},
	

	{
		"text": "Historia y diálogos:\nDiego Mayora",
		"font_size": 56,
		"wait_after": 2.5
	},
			{
		"text": "Threadbare: Mythical Meadows - Main Theme:\nEduardo Mosquera (DeChillGames)",
		"font_size": 56,
		"wait_after": 2.5
	},
		{
		"text": "Agradecimientos especiales:\nJulian Giamportone\nCarolina Pohn\nLuis\nManu\nPor la ayuda a lo largo de toda esta semana <3",
		"font_size": 56,
		"wait_after": 2.5
	},
	{
		"text": "Basado en el universo de Threadbare\nEndless Studios",
		"font_size": 56,
		"wait_after": 2.8
	},
	{
		"text": "Gracias por jugar.",
		"font_size": 62,
		"wait_after": 2.5
	},
	{
		"text": "No todo lo olvidado desea ser encontrado.",
		"font_size": 46,
		"wait_after": 4.0
	},
		{
		"text": "Las tierras miticas volverán..",
		"font_size": 46,
		"wait_after": 4.0
	}
]

var bloque_actual := 0
var texto_actual := ""
var indice := 0
var escribiendo := false

var velocidad_letra := 0.055
var pausa_linea := 0.25
var fade_time := 0.8


func _ready() -> void:
	label.text = ""
	label.visible = true
	label.modulate = Color(1, 1, 1, 1)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	
	if background_music:
		background_music.play()
	
	timer.timeout.connect(_escribir_letra)
	mostrar_bloque()


func mostrar_bloque() -> void:
	if bloque_actual >= bloques_creditos.size():
		terminar_creditos()
		return
	
	var bloque = bloques_creditos[bloque_actual]
	
	texto_actual = ""
	indice = 0
	label.text = ""
	label.modulate = Color(1, 1, 1, 1)
	label.add_theme_font_size_override("font_size", bloque["font_size"])
	
	escribiendo = true
	timer.wait_time = velocidad_letra
	timer.start()


func _escribir_letra() -> void:
	var bloque = bloques_creditos[bloque_actual]
	var texto_objetivo: String = bloque["text"]
	
	if indice < texto_objetivo.length():
		var letra = texto_objetivo[indice]
		texto_actual += letra
		label.text = texto_actual
		indice += 1
		
		if letra == "\n":
			timer.wait_time = pausa_linea
		else:
			timer.wait_time = velocidad_letra
	else:
		timer.stop()
		escribiendo = false
		
		await get_tree().create_timer(bloque["wait_after"]).timeout
		await desaparecer_bloque()
		
		bloque_actual += 1
		mostrar_bloque()


func desaparecer_bloque() -> void:
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), fade_time)
	await tween.finished


func terminar_creditos() -> void:
	if background_music:
		background_music.stop()
	
	get_tree().change_scene_to_file("res://scenes/quests/lore_quests/quest_000/1_ruined_village/tutorial_ruined_village.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if escribiendo:
			var bloque = bloques_creditos[bloque_actual]
			label.text = bloque["text"]
			indice = bloque["text"].length()
			timer.stop()
			escribiendo = false
		else:
			bloque_actual += 1
			mostrar_bloque()
