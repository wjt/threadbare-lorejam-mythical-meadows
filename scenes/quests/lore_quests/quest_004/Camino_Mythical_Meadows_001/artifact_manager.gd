extends Node

@onready var pickup: Node = $"../ArtifactPickup"
@onready var door: Node = $"../Door"

func _ready() -> void:
	pickup.collected.connect(_on_artifact_collected)

func _on_artifact_collected() -> void:
	print("Artefacto recogido")
	door.open()
