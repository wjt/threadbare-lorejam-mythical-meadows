extends Control

@onready var title_label: Label = $Panel/TitleLabel
@onready var info_label: Label = $Panel/InfoLabel
@onready var button: Button = $Panel/Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.pressed.connect(close_hud)

func show_piano_message() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	get_tree().paused = true

	title_label.text = "Nueva habilidad: Piano Primordial"
	info_label.text = "Presiona R para invocar el piano.\nClick izquierdo para atacar enemigos marcados."
	button.text = "Entendido"

func close_hud() -> void:
	get_tree().paused = false
	visible = false
