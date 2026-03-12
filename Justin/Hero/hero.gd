class_name Hero
extends CharacterBody3D

enum State {
	IDLE, 
	MOVE, 
	JUMP,
	ATTACK,
	HURT,
	DEATH
}

@export var speed: float = 10.0
@export var direction: Vector3 = Vector3.ZERO
@export var state: State = State.IDLE
var entity: Entity = null

## Rotate the entire game object about the Y axis at this rate (degrees per second). 0 = no rotation.
@export var spin_speed_degrees_per_second: float = 90.0

func _ready() -> void:
	entity = Entity.of(self)
	var regen_behaviour = Augment.new()
	regen_behaviour.tag = "regen"
	entity.add_augment(regen_behaviour)
	var move_speed_behaviour = Augment.new()
	move_speed_behaviour.tag = "move_speed"
	entity.add_augment(move_speed_behaviour)
	var attack_behaviour = Augment.new()
	attack_behaviour.tag = "attack"
	entity.add_augment(attack_behaviour)

func _process(delta: float) -> void:
	if spin_speed_degrees_per_second != 0.0:
		rotate_y(deg_to_rad(spin_speed_degrees_per_second) * delta)
	
	print(entity.get_augment("regen"))
