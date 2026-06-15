extends Control

signal option_selected(type)

@onready var button_1: Button = $HBoxContainer/OptionButton1
@onready var button_2: Button = $HBoxContainer/OptionButton2

var current_options: Array = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)

	button_1.pressed.connect(_on_button_1_pressed)
	button_2.pressed.connect(_on_button_2_pressed)

	button_1.icon = null
	button_2.icon = null

	hide()


func setup_options(options: Array) -> void:
	current_options = options

	button_1.text = get_upgrade_description(options[0])
	button_2.text = get_upgrade_description(options[1])

	# Sin imágenes en las mejoras
	button_1.icon = null
	button_2.icon = null

	button_1.grab_focus()
	show()


func get_upgrade_description(type: String) -> String:
	match type:
		"speed":
			return "Botas Ligeras\n+10% Velocidad de movimiento"
		"max_health":
			return "Coraza de Hierro\n+20 Vida Máxima"
		"bullet_damage":
			return "Pólvora Pesada\n+15 Daño por proyectil"
		"bullet_amount":
			return "Multi-Disparo\n+1 Bala adicional por ráfaga"
		"bullet_pierce":
			return "Bala Perforante\nTus proyectiles atraviesan +1 enemigo"
		"bullet_speed":
			return "Cañón Pulido\n+25% Velocidad de los proyectiles"
		"magnet":
			return "Hilo Imantado\n+60 Rango de recolección"

	return ""


func _on_button_1_pressed() -> void:
	option_selected.emit(current_options[0])
	hide()


func _on_button_2_pressed() -> void:
	option_selected.emit(current_options[1])
	hide()
