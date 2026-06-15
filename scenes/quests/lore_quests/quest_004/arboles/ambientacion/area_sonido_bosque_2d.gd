extends Area2D

@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio.play()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio.stop()
