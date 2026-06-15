# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer
## Intro: la pantalla arranca en NEGRO, se abre un libro que cuenta la historia
## página a página, y al terminar (o saltar con Esc) se desvanece y empieza el
## juego. Pausa el juego mientras se muestra. Colócalo en la primera escena.

## Páginas de la historia. Se permite BBCode ([center], [i], etc.).
@export var pages: PackedStringArray = []
## Duración de los fundidos de apertura/cierre (s).
@export var fade_time: float = 0.7

@onready var black: ColorRect = $Black
@onready var book: Control = $Book
@onready var page_text: RichTextLabel = $Book/PageText
@onready var hint: Label = $Hint

var _index: int = 0
var _busy: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	book.modulate.a = 0.0
	book.scale = Vector2(0.86, 0.86)
	if pages.is_empty():
		_finish()
		return
	_show_page(0)
	# Sobre el negro, abre el libro (aparece + escala con rebote).
	var t := create_tween().set_parallel(true)
	t.tween_property(book, "modulate:a", 1.0, fade_time)
	(
		t
		. tween_property(book, "scale", Vector2.ONE, fade_time)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	t.chain().tween_callback(_unlock)


func _unlock() -> void:
	_busy = false


func _show_page(i: int) -> void:
	_index = i
	page_text.text = pages[i]
	if i < pages.size() - 1:
		hint.text = "▶  clic / Enter    ·    Esc para saltar"
	else:
		hint.text = "▶  clic / Enter para empezar"


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()
		return
	var advance := (
		event.is_action_pressed(&"ui_accept")
		or event.is_action_pressed(&"interact")
		or (
			event is InputEventMouseButton
			and (event as InputEventMouseButton).pressed
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
		)
	)
	if advance:
		_next()
		get_viewport().set_input_as_handled()


func _next() -> void:
	if _index >= pages.size() - 1:
		_finish()
		return
	_busy = true
	# Pequeño "pase de página".
	var t := create_tween()
	t.tween_property(page_text, "modulate:a", 0.0, 0.12)
	t.tween_callback(_advance_page)
	t.tween_property(page_text, "modulate:a", 1.0, 0.14)
	t.tween_callback(_unlock)


func _advance_page() -> void:
	_show_page(_index + 1)


func _finish() -> void:
	_busy = true
	var t := create_tween().set_parallel(true)
	t.tween_property(book, "modulate:a", 0.0, fade_time)
	t.tween_property(black, "color:a", 0.0, fade_time)
	t.chain().tween_callback(_end)


func _end() -> void:
	get_tree().paused = false
	queue_free()
