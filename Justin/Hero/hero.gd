class_name Hero
extends Node3D

enum State {
	IDLE, 
	MOVE, 
	JUMP,
	ATTACK,
	HURT,
	DEATH
}

@export var health: int = 100
@export var max_health: int = 100
@export var speed: float = 10.0
@export var direction: Vector3 = Vector3.ZERO
@export var state: State = State.IDLE

## Rotate the entire game object about the Y axis at this rate (degrees per second). 0 = no rotation.
@export var spin_speed_degrees_per_second: float = 90.0

func _process(delta: float) -> void:
	if spin_speed_degrees_per_second != 0.0:
		rotate_y(deg_to_rad(spin_speed_degrees_per_second) * delta)
