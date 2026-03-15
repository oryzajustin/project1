class_name Setor
extends CharacterBody3D

@export var rotation_speed: float = 2.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	rotation.y += rotation_speed * delta
	move_and_slide()

func get_animation_prefix() -> String:
	return "idle"
