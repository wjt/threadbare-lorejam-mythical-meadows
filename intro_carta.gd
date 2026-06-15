extends Control

@onready var carta_label: Label = $Label
@onready var timer: Timer = $Timer
@onready var logo: TextureRect = $Logo

var texto_carta := """A quien reciba esta carta:

Mi nombre es Filomena Merodiatela, cartógrafa del Observatorio del Oscuro.

Durante años he seguido los rastros de una tierra que no aparece en los mapas comunes: las Praderas Míticas.

Dicen que alguna vez fue un hogar, lleno de flores luminosas, ríos extraños y magia tranquila. Pero algo ocurrió allí. Los caminos quedaron vacíos y las voces de sus antiguos habitantes siguen atrapadas entre la hierba.

Mis registros hablan de piedras que susurran recuerdos, rutas olvidadas y figuras espectrales.

También hay advertencias sobre lobos alterados por la magia del lugar.

Antes de perder el rumbo, dejé un marcador de hilo cerca del camino principal. Si lo encuentras, sabrás que vas por donde yo pasé.

Viaja hasta las Praderas Míticas. Observa todo. Escucha los ecos. Sigue el camino hasta el final."""

var texto_advertencia := """Pero ten cuidado.

No todo lo olvidado desea ser encontrado."""

var texto_actual := ""
var texto_en_pantalla := ""
var indice := 0

var duracion_total_intro := 30.0

var duracion_logo_fade_in := 1.5
var duracion_logo_visible := 5.0
var duracion_logo_fade_out := 1.5

var pausa_despues_carta := 0.8
var pausa_despues_advertencia := 1.2

var velocidad_letra := 0.02
var velocidad_advertencia := 0.035
var pausa_parrafo := 0.25

var mostrando_advertencia := false
var mostrando_logo := false


func _ready():
	carta_label.text = ""
	carta_label.visible = true

	carta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	carta_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	carta_label.add_theme_font_size_override("font_size", 26)

	texto_en_pantalla = texto_carta

	logo.texture = load("res://scenes/quests/lore_quests/quest_004/assets/images/NewLogo.jpeg")
	logo.visible = true
	logo.modulate = Color(1, 1, 1, 0)
	logo.z_index = 999
	logo.move_to_front()

	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.offset_left = 0
	logo.offset_top = 0
	logo.offset_right = 0
	logo.offset_bottom = 0

	calcular_velocidad_texto()

	timer.wait_time = velocidad_letra
	timer.timeout.connect(_escribir_letra)
	timer.start()


func calcular_velocidad_texto() -> void:
	var texto_total = texto_carta + texto_advertencia

	var letras_normales := 0
	var saltos_linea := 0

	for letra in texto_total:
		if letra == "\n":
			saltos_linea += 1
		else:
			letras_normales += 1

	var duracion_logo = duracion_logo_fade_in + duracion_logo_visible + duracion_logo_fade_out
	var duracion_pausas = pausa_despues_carta + pausa_despues_advertencia
	var duracion_saltos = saltos_linea * pausa_parrafo

	var tiempo_para_letras = duracion_total_intro - duracion_logo - duracion_pausas - duracion_saltos

	if letras_normales > 0:
		velocidad_letra = tiempo_para_letras / letras_normales


func _escribir_letra():
	if indice < texto_en_pantalla.length():
		var letra = texto_en_pantalla[indice]
		texto_actual += letra
		carta_label.text = texto_actual
		indice += 1

		if letra == "\n":
			timer.wait_time = pausa_parrafo
		elif mostrando_advertencia:
			timer.wait_time = velocidad_advertencia
		else:
			timer.wait_time = velocidad_letra
	else:
		timer.stop()

		if not mostrando_advertencia:
			await get_tree().create_timer(pausa_despues_carta).timeout
			mostrar_advertencia()
		else:
			await get_tree().create_timer(pausa_despues_advertencia).timeout
			await mostrar_logo()
			ir_al_juego()


func mostrar_advertencia():
	mostrando_advertencia = true

	texto_actual = ""
	indice = 0
	carta_label.text = ""

	carta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	carta_label.add_theme_font_size_override("font_size", 44)

	texto_en_pantalla = texto_advertencia

	timer.wait_time = velocidad_advertencia
	timer.start()


func mostrar_logo():
	mostrando_logo = true
	carta_label.visible = false

	logo.visible = true
	logo.modulate = Color(1, 1, 1, 0)
	logo.z_index = 999
	logo.move_to_front()

	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.offset_left = 0
	logo.offset_top = 0
	logo.offset_right = 0
	logo.offset_bottom = 0

	var tween = create_tween()

	tween.tween_property(logo, "modulate", Color(1, 1, 1, 1), duracion_logo_fade_in)
	tween.tween_interval(duracion_logo_visible)
	tween.tween_property(logo, "modulate", Color(1, 1, 1, 0), duracion_logo_fade_out)

	await tween.finished
	mostrando_logo = false


func ir_al_juego():
	get_tree().change_scene_to_file("res://scenes/quests/lore_quests/quest_004/1_intro/mythical_meadows.tscn")


func _input(event):
	if event.is_action_pressed("ui_accept"):
		if mostrando_logo:
			return

		if not mostrando_advertencia:
			timer.stop()
			mostrar_advertencia()
		else:
			timer.stop()
			await mostrar_logo()
			ir_al_juego()
