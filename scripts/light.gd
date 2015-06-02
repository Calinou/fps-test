extends SpotLight

# Timer to prevent flickering:
var timer = 0

func _ready():
	set_process_input(true)
	set_fixed_process(true)

func _fixed_process(delta):
	timer = timer + 1
	if timer >= 20:
		timer = 20
	
	if Input.is_action_pressed("toggle_flashlight") and get_parameter(PARAM_ENERGY) == 2 and timer == 20:
		set_parameter(PARAM_ENERGY, 0)
		print("Flashlight turned off.")
		timer = 0

	if Input.is_action_pressed("toggle_flashlight") and get_parameter(PARAM_ENERGY) == 0 and timer == 20:
		set_parameter(PARAM_ENERGY, 2)
		print("Flashlight turned on.")
		timer = 0
