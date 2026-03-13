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

@export var speed: float = 5.0
@export var state: State = State.IDLE
@export var is_player: bool = false
@export var avoidance_radius: float = 3.0

var entity: Entity = null
var move_target: Vector3 = Vector3.ZERO
var has_move_target: bool = false


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


func _unhandled_input(event: InputEvent) -> void:
	if not is_player:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		_set_movement_target(event.position)


func _set_movement_target(screen_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	if absf(ray_dir.y) < 0.001:
		return
	var t := -ray_origin.y / ray_dir.y
	if t < 0.0:
		return
	move_target = ray_origin + ray_dir * t
	move_target.y = 0.0
	has_move_target = true
	state = State.MOVE


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if state == State.MOVE and has_move_target:
		var to_target := move_target - global_position
		to_target.y = 0.0
		var dist := to_target.length()

		if dist < 0.3:
			_arrive()
		else:
			var desired_dir := to_target / dist
			var avoidance := _get_avoidance_steering()
			var steer := desired_dir + avoidance
			steer.y = 0.0
			if steer.length_squared() > 0.001:
				steer = steer.normalized()
			else:
				steer = desired_dir
			rotation.y = atan2(steer.x, steer.z)
			velocity.x = steer.x * speed
			velocity.z = steer.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _arrive() -> void:
	state = State.IDLE
	has_move_target = false
	velocity.x = 0.0
	velocity.z = 0.0


func _get_avoidance_steering() -> Vector3:
	var steer := Vector3.ZERO
	for node in get_tree().get_nodes_in_group("entity"):
		if node == self or not node is CharacterBody3D:
			continue
		var away: Vector3 = global_position - node.global_position
		away.y = 0.0
		var dist := away.length()
		if dist < avoidance_radius and dist > 0.01:
			steer += away.normalized() * (1.0 - dist / avoidance_radius) * 2.0
	return steer
