extends Node2D
class_name ItemOrden

@export var id_correcto: int = 0
@export var animal: PackedScene
@export var sprite_frames: SpriteFrames

var slot_actual = null 
var animal_instancia: Node2D = null
var siendo_cargado := false
var jugador_referencia: CharacterBody2D = null

func _ready() -> void:
	# El Z-Index alto asegura que se vea sobre el mapa
	z_index = 10
	if animal:
		animal_instancia = animal.instantiate()
		add_child(animal_instancia)
		# Posición local 0,0 para que herede la del padre
		animal_instancia.position = Vector2.ZERO 
		_configurar_animal()

func _configurar_animal():
	if not animal_instancia: return
	var sprite = animal_instancia.find_child("AnimatedSprite2D", true, false)
	if sprite and sprite is AnimatedSprite2D:
		if sprite_frames: sprite.sprite_frames = sprite_frames
		sprite.play("idle")
		sprite.show()

# DESPUÉS
func _process(_delta: float) -> void:
	if is_instance_valid(animal_instancia):
		var carryable := animal_instancia as CarryableAnimal
		if carryable and carryable.carried:
			global_position = carryable.global_position
# Funciones de control desde el jugador
func cargar(jugador: CharacterBody2D):
	siendo_cargado = true
	jugador_referencia = jugador

func soltar():
	siendo_cargado = false
	jugador_referencia = null
