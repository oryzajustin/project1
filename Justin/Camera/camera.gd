extends Camera3D
class_name GameCamera

# Fixed 45° angle to world — no orientation change; pan (WASD) and zoom only
@export var target_path: NodePath
@export var camera_distance := 10.0
@export var pan_speed: float = 6.0
@export var zoom_speed: float = 3.0
@export var drag_sensitivity: float = 0.05
@export var min_distance: float = 3.0
@export var max_distance: float = 15.0
@export var target: Node3D
## How quickly pan velocity decays when input stops (higher = snappier stop).
@export var pan_deceleration: float = 6.0
## Clamp pan velocity so it doesn't grow without bound.
@export var max_pan_velocity: float = 50.0

# Focus point we look at; panned with WASD or click-drag
var focus: Vector3 = Vector3.ZERO
var target_node: Node3D
var is_dragging := false
## Current pan velocity in XZ; smoothed each frame.
var pan_velocity := Vector3.ZERO

# Fixed angle: 45° down from horizontal, 45° in XZ (isometric-style view)
const CAMERA_ANGLE_DOWN := deg_to_rad(40.0)
const CAMERA_ANGLE_Y := deg_to_rad(45.0)

# Pixel animation / rendering: groups to update for camera-facing sprites
var sprite_groups = ["entity"]

func _ready():
	if target_path:
		target_node = get_node(target_path)
	elif target:
		target_node = target
	if target_node:
		focus = target_node.global_position
	else:
		focus = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current = true

func _get_camera_axes_xz() -> Array[Vector3]:
	var h := cos(CAMERA_ANGLE_DOWN) * camera_distance
	var offset := Vector3(
		sin(CAMERA_ANGLE_Y) * h,
		sin(CAMERA_ANGLE_DOWN) * camera_distance,
		cos(CAMERA_ANGLE_Y) * h
	)
	var forward_xz := Vector3(-offset.x, 0.0, -offset.z)
	if forward_xz.length_squared() > 0.0001:
		forward_xz = forward_xz.normalized()
	var right_xz := Vector3(offset.z, 0.0, -offset.x).normalized()
	return [forward_xz, right_xz]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = clamp(camera_distance - zoom_speed, min_distance, max_distance)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = clamp(camera_distance + zoom_speed, min_distance, max_distance)
	if event is InputEventMouseMotion and is_dragging:
		var axes := _get_camera_axes_xz()
		var forward_xz: Vector3 = axes[0]
		var right_xz: Vector3 = axes[1]
		# Inverted: grab and pull — drag direction adds velocity so you pull view toward cursor
		var pull: Vector3 = right_xz * event.relative.x - forward_xz * event.relative.y
		pan_velocity -= pull * drag_sensitivity

func _physics_process(delta: float) -> void:
	var axes := _get_camera_axes_xz()
	var forward_xz: Vector3 = axes[0]
	var right_xz: Vector3 = axes[1]

	# Offset from focus (camera at fixed 45° isometric angle)
	var h := cos(CAMERA_ANGLE_DOWN) * camera_distance
	var offset := Vector3(
		sin(CAMERA_ANGLE_Y) * h,
		sin(CAMERA_ANGLE_DOWN) * camera_distance,
		cos(CAMERA_ANGLE_Y) * h
	)

	# Pan with WASD: add to velocity (camera-relative XZ)
	var pan_forward := -Input.get_axis(&"ui_up", &"ui_down")
	var pan_right := Input.get_axis(&"ui_left", &"ui_right")
	var pan_dir := forward_xz * pan_forward + right_xz * pan_right
	if pan_dir != Vector3.ZERO:
		pan_velocity += pan_dir.normalized() * pan_speed

	# Clamp velocity magnitude
	var speed := pan_velocity.length()
	if speed > max_pan_velocity:
		pan_velocity = pan_velocity * (max_pan_velocity / speed)

	# Apply velocity and smooth deceleration (frame-rate independent)
	focus += pan_velocity * delta
	var decay: float = 1.0 - exp(-pan_deceleration * delta)
	pan_velocity = pan_velocity.lerp(Vector3.ZERO, decay)

	global_position = focus + offset
	look_at(focus)

func _process(_delta):
	var camera_forward := -global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	for group in sprite_groups:
		for node in get_tree().get_nodes_in_group(group):
			_update_sprite_direction(node, camera_forward)


func _update_sprite_direction(node: Node3D, camera_forward: Vector3) -> void:
	var sprite := _find_sprite(node)
	if sprite == null:
		return
	if not node.has_method(&"get_animation_prefix"):
		return

	var dir_suffix := _get_direction_suffix(node, camera_forward)
	var prefix: String = node.get_animation_prefix()

	var directional := prefix + "_" + dir_suffix
	if sprite.sprite_frames.has_animation(directional):
		sprite.play(directional)
	elif sprite.sprite_frames.has_animation(prefix):
		sprite.play(prefix)


func _find_sprite(node: Node3D) -> AnimatedSprite3D:
	for path in ["AnimatedSprite3D", "Pivot/AnimatedSprite3D"]:
		if node.has_node(path):
			var child := node.get_node(path)
			if child is AnimatedSprite3D:
				return child
	return null


func _get_direction_suffix(node: Node3D, camera_forward: Vector3) -> String:
	var object_forward := node.global_transform.basis.z
	object_forward.y = 0.0
	object_forward = object_forward.normalized()

	var cam_angle := atan2(camera_forward.x, camera_forward.z)
	var obj_angle := atan2(object_forward.x, object_forward.z)
	var relative := rad_to_deg(cam_angle - obj_angle)
	relative = fmod(relative + 360.0, 360.0)

	var quadrant := int((relative + 45.0) / 90.0) % 4
	return ["back", "right", "front", "left"][quadrant]
