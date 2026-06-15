@tool
extends AnimatedSprite2D

func _ready() -> void:
	play("default")

	var frames_length := sprite_frames.get_frame_count("default")

	if frames_length > 1:
		frame = randi_range(0, frames_length - 1)
		frame_progress = randf()
