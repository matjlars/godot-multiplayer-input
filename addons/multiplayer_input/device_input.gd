extends RefCounted
class_name DeviceInput

# this is an optional helper class that just wraps the calls to MultiplayerInput
# so you can use this to keep track of the device and then you don't have to pass that around
# the following is a simple example of how to use this class
#
# var input
# func _ready():
#     input = DeviceInput.new(device)
# func _process(delta):
#     if input.is_action_just_pressed("jump"):
#         jump()

# if this is -1, then this is the keyboard player
# otherwise, it's the "device" used in the Input class functions.
var device: int

func _init(device_num: int):
	device = device_num

func is_keyboard() -> bool:
	return device < 0

func is_joypad() -> bool:
	return device >= 0

func get_action_raw_strength(action: StringName, exact_match: bool = false) -> float:
	return MultiplayerInput.get_action_raw_strength(device, action, exact_match)
	
func get_action_strength(action: StringName, exact_match: bool = false) -> float:
	return MultiplayerInput.get_action_strength(device, action, exact_match)

func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	return MultiplayerInput.get_axis(device, negative_action, positive_action)
	
func get_vector(negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, deadzone: float = -1.0) -> Vector2:
	return MultiplayerInput.get_vector(device, negative_x, positive_x, negative_y, positive_y, deadzone)

func is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
	return MultiplayerInput.is_action_just_pressed(device, action, exact_match)

func is_action_just_released(action: StringName, exact_match: bool = false) -> bool:
	return MultiplayerInput.is_action_just_released(device, action, exact_match)

func is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	return MultiplayerInput.is_action_pressed(device, action, exact_match)
