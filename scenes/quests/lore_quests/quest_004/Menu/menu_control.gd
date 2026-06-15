extends Control

@onready var contenedor_logo: VBoxContainer = $ContenedorLogo
@onready var mensaje_boton: Label = $ContenedorLogo/MensajeBoton
@onready var contenedor_botones: VBoxContainer = $ContenedorBotones

var menu_activado: bool = false
var posicion_logo_centro: Vector2
var posicion_logo_izquierda: Vector2


func _ready() -> void:
	contenedor_botones.modulate.a = 0
	contenedor_botones.visible = false

	contenedor_botones.add_theme_constant_override("separation", 20)

	posicion_logo_centro = contenedor_logo.position
	posicion_logo_izquierda = Vector2(400, posicion_logo_centro.y)

	var estilo_base := StyleBoxFlat.new()
	estilo_base.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	estilo_base.border_color = Color(1.0, 1.0, 1.0)
	estilo_base.set_border_width_all(3)
	estilo_base.set_corner_radius_all(12)
	estilo_base.set_expand_margin_all(8)

	var estilo_hover := estilo_base.duplicate()
	estilo_hover.bg_color = Color(0.25, 0.25, 0.25, 0.9)

	var hijos: Array[Node] = contenedor_botones.get_children()

	for nodo: Node in hijos:
		if nodo is Button:
			var boton: Button = nodo
			boton.add_theme_stylebox_override("normal", estilo_base)
			boton.add_theme_stylebox_override("hover", estilo_hover)
			boton.add_theme_stylebox_override("pressed", estilo_base)


func _input(event: InputEvent) -> void:
	if not menu_activado and (event is InputEventKey or event is InputEventMouseButton):
		if event.is_pressed():
			activar_menu()


func activar_menu() -> void:
	menu_activado = true
	contenedor_botones.visible = true

	var tween := create_tween().set_parallel(true)

	tween.tween_property(mensaje_boton, "modulate:a", 0.0, 0.3)
	(
		tween
		. tween_property(contenedor_logo, "position", posicion_logo_izquierda, 0.8)
		. set_trans(Tween.TRANS_QUART)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(contenedor_botones, "modulate:a", 1.0, 0.8).set_delay(0.2)
