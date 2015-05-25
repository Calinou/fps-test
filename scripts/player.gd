extends RigidBody

export var view_sensitivity = 0.25
export var yaw = 0
export var pitch = 0

const max_accel = 0.005
const air_accel = 0.02

var timer = 0

# Walking speed and jumping height are defined later.
var walk_speed
var jump_speed
var health = 100
var stamina = 10000

func _ready():
	set_process_input(true)
	# Capture mouse once game is started:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_fixed_process(true)
	OS.set_iterations_per_second(60)

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		yaw = fmod(yaw - event.relative_x * view_sensitivity, 360)
		# Quake-like minimum pitch -80, maximum pitch 70:
		pitch = max(min(pitch - event.relative_y * view_sensitivity, 70), -80)
		get_node("yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
		get_node("yaw/camera").set_rotation(Vector3(deg2rad(pitch), 0, 0))

	# Toggle mouse capture:
	if Input.is_action_pressed("toggle_mouse_capture"):
		if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			view_sensitivity = 0
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			view_sensitivity = 0.25

	# Quit the game:
	if Input.is_action_pressed("quit"):
		quit()

func _integrate_forces(state):
	timer += 1

	if timer >= 8:
		timer = 0

	if Input.is_action_pressed("attack") and timer == 0:
		get_node("Sounds").play("rifle")

	# Default walk speed:
	walk_speed = 4
	# Default jump height:
	jump_speed = 3
	# Regenerate stamina:
	stamina += 5
	
	# Cap stamina:
	if stamina >= 10000:
		stamina = 10000
	if stamina <= 0:
		stamina = 0

	var aim = get_node("yaw").get_global_transform().basis

	var direction = Vector3()

	if Input.is_action_pressed("move_forwards"):
		direction -= aim[2]
	if Input.is_action_pressed("move_backwards"):
		direction += aim[2]
	if Input.is_action_pressed("move_left"):
		direction -= aim[0]
	if Input.is_action_pressed("move_right"):
		direction += aim[0]

	# Increase walk speed and jump height while running and decrement stamina:
	if Input.is_action_pressed("run") and stamina > 0:
		walk_speed *= 1.35
		jump_speed *= 1.35
		stamina -= 10

	direction = direction.normalized()
	var ray = get_node("ray")

	if ray.is_colliding():
		var up = state.get_total_gravity().normalized()
		var normal = ray.get_collision_normal()
		var floor_velocity = Vector3()
		var object = ray.get_collider()

		if object extends RigidBody or object extends StaticBody:
			var point = ray.get_collision_point() - object.get_translation()
			var floor_angular_vel = Vector3()
			if object extends RigidBody:
				floor_velocity = object.get_linear_velocity()
				floor_angular_vel = object.get_angular_velocity()
			elif object extends StaticBody:
				floor_velocity = object.get_constant_linear_velocity()
				floor_angular_vel = object.get_constant_angular_velocity()
			# Surely there should be a function to convert Euler angles to a 3x3 matrix
			var transform = Matrix3(Vector3(1, 0, 0), floor_angular_vel.x)
			transform = transform.rotated(Vector3(0, 1, 0), floor_angular_vel.y)
			transform = transform.rotated(Vector3(0, 0, 1), floor_angular_vel.z)
			floor_velocity += transform.xform_inv(point) - point
			yaw = fmod(yaw + rad2deg(floor_angular_vel.y) * state.get_step(), 360)
			get_node("yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))

		var diff = floor_velocity + direction * walk_speed - state.get_linear_velocity()
		var vertdiff = aim[1] * diff.dot(aim[1])
		diff -= vertdiff
		diff = diff.normalized() * clamp(diff.length(), 0, max_accel / state.get_step())
		diff += vertdiff

		# FPS counter:
		get_node("FPS").set_text(str(OS.get_frames_per_second(), " FPS"))
		# Health status (currently hidden):
		#get_node("Health").set_text(str(int(health), " % Health"))
		# Stamina status:
		get_node("Stamina").set_value(stamina)
		# Basic crosshair:
		get_node("Crosshair").set_text("+")

		apply_impulse(Vector3(), diff * get_mass())

		if Input.is_action_pressed("jump") and stamina > 0:
			apply_impulse(Vector3(), normal * jump_speed * get_mass())
			get_node("Sounds").play("jump")
			stamina -= 150

	else:
		apply_impulse(Vector3(), direction * air_accel * get_mass())

	state.integrate_forces()

func _exit_scene():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Functions
# =========

# Quits the game:
func quit():
	get_tree().quit()
