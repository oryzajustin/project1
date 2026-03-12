extends Camera3D
class_name GameCamera

# Basic camera orientation
@export var target_path: NodePath
@export var camera_distance := 10.0
@export var height_offset := 5.0
@export var target: Node3D
@export var orbit_speed: float = 2.0
@export var mouse_sensitivity: float = 0.003

var target_node: Node3D
var camera_rotation := Vector3.ZERO

# Pixel animation / rendering: groups to update for camera-facing sprites
var sprite_groups = ["players"]

func _ready():
	if target_path:
		target_node = get_node(target_path)
	elif target:
		target_node = target
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current = true

func _input(event):
	if event is InputEventMouseMotion:
		camera_rotation.y -= event.relative.x * mouse_sensitivity

func _physics_process(_delta):
	if !target_node:
		return

	var target_pos = target_node.global_position
	var offset = Vector3(
		sin(camera_rotation.y) * camera_distance,
		height_offset,
		cos(camera_rotation.y) * camera_distance
	)
	global_position = target_pos + offset
	look_at(target_pos + Vector3(0, height_offset * 0.5, 0))

func _process(_delta):
	var camera_forward = -global_transform.basis.z
	camera_forward.y = 0
	camera_forward = camera_forward.normalized()

	for group in sprite_groups:
		var nodes = get_tree().get_nodes_in_group(group)
		for node in nodes:
			update_sprite_direction(node, camera_forward)

func update_sprite_direction(node: Node3D, camera_forward: Vector3):
	if not is_multiplayer_authority():
		return

	var sprite = null
	if node.has_node("AnimatedSprite3D"):
		sprite = node.get_node("AnimatedSprite3D")
	elif node.has_node("Pivot/AnimatedSprite3D"):
		sprite = node.get_node("Pivot/AnimatedSprite3D")

	if not sprite is AnimatedSprite3D:
		return

	var object_forward = node.global_transform.basis.z
	object_forward.y = 0
	object_forward = object_forward.normalized()

	var angle = atan2(camera_forward.x, camera_forward.z)
	var object_angle = atan2(object_forward.x, object_forward.z)
	var relative_angle = angle - object_angle

	var degrees = rad_to_deg(relative_angle)
	degrees = fmod(degrees + 360, 360)

	var direction = int((degrees + 45) / 90) % 4
	var dir_suffix = ["back", "right", "front", "left"][direction]

	# if node is Player:
	# sprite.play(match_animation_state(node, dir_suffix))

# func match_enemy_animation_state(enemy: Enemy, dir_suffix: String) -> String:
# 	if enemy.state == Enemy.State.HURT:
# 		return "hurt"
# 	if enemy.state == Enemy.State.ATTACK:
# 		return "attacking_" + dir_suffix
# 	if enemy.state == Enemy.State.DIE:
# 		return "die"

# 	match enemy.state:
# 		Enemy.State.IDLE:
# 			return "idle_" + dir_suffix
# 		Enemy.State.MOVE:
# 			return "running_" + dir_suffix
# 		_:
# 			return "idle_" + dir_suffix

# func match_animation_state(player: Player, dir_suffix: String) -> String:
	# if player.state == Player.State.HURT:
	# 	return "hurt_" + dir_suffix
	# if player.state == Player.State.ATTACK:
	# 	return "attacking_" + dir_suffix

	# match player.state:
	# 	Player.State.IDLE:
	# 		return "idle_" + dir_suffix
	# 	Player.State.MOVE:
	# 		return "running_" + dir_suffix
	# 	Player.State.JUMP:
	# 		return "jumping_" + dir_suffix
	# 	Player.State.DEATH:
	# 		return "death"
	# 	_:
	# 		return "idle_" + dir_suffix
