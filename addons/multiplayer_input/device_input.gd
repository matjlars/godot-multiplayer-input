extends RefCounted

## An object-oriented replacement of Input that is scoped to a single device.
##
## To use this class, first instantiate an object like this:
## [code]var input = DeviceInput.new(device)[/code]
## Then you can call any of the methods listed here like this for example: [code]input.is_action_just_pressed("jump")[/code]
##
## This class gracefully handles joypad disconnection by returning default values
## for all of the methods with "action" in their name if it's currently disconnected.
class_name DeviceInput

## Emitted when this device disconnects or re-connects
## This will never be emitted for the keyboard player.
signal connection_changed(connected: bool)

## If this is -1, then this is the keyboard player.
## Otherwise, it's the "device" used in the Input class functions.
var device: int

## Whether this device is currently connected
var is_connected: bool = true

func _init(device_num: int):
	device = device_num
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

## Returns true if this device is the keyboard/mouse "device"
func is_keyboard() -> bool:
	return device < 0

## Returns true if this device is a joypad.
func is_joypad() -> bool:
	return device >= 0

## See Input.get_joy_guid() for what this returns.
## If this is the keyboard device, this returns "Keyboard"
func get_guid() -> String:
	if is_keyboard(): return "Keyboard"
	return Input.get_joy_guid(device)

## See Input.get_joy_name() for what this returns.
## If this is the keyboard device, this returns "Keyboard"
func get_name() -> String:
	if is_keyboard(): return "Keyboard"
	return Input.get_joy_name(device)

## See Input.get_joy_vibration_duration for what this returns.
## This will always be 0.0 for the keyboard device.
func get_vibration_duration() -> float:
	if is_keyboard(): return 0.0
	return Input.get_joy_vibration_duration(device)

## See Input.get_joy_vibration_strength for what this returns.
## This will always be Vector2.ZERO for the keyboard device.
func get_vibration_strength() -> Vector2:
	if is_keyboard(): return Vector2.ZERO
	return Input.get_joy_vibration_strength(device)

## See Input.is_joy_known for what this returns.
## This will always return true for the keyboard device.
func is_known() -> bool:
	if is_keyboard(): return true
	return Input.is_joy_known(device)

## See Input.start_joy_vibration for what this does.
## This does nothing for the keyboard device.
func start_vibration(weak_magnitude: float, strong_magnitude: float, duration: float = 0.0):
	if is_keyboard(): return
	Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)

## See Input.stop_joy_vibration for what this does.
## This does nothing for the keyboard device.
func stop_vibration():
	if is_keyboard(): return
	Input.stop_joy_vibration(device)

## This is equivalent to Input.get_action_raw_strength except it will only check the relevant device.
func get_action_raw_strength(action: StringName, exact_match: bool = false) -> float:
	if !is_connected: return 0.0
	return MultiplayerInput.get_action_raw_strength(device, action, exact_match)

## This is equivalent to Input.get_action_strength except it will only check the relevant device.
func get_action_strength(action: StringName, exact_match: bool = false) -> float:
	if !is_connected: return 0.0
	return MultiplayerInput.get_action_strength(device, action, exact_match)

## This is equivalent to Input.get_axis except it will only check the relevant device.
func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	if !is_connected: return 0.0
	return MultiplayerInput.get_axis(device, negative_action, positive_action)

## This is equivalent to Input.get_vector except it will only check the relevant device.
func get_vector(negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, deadzone: float = -1.0) -> Vector2:
	if !is_connected: return Vector2.ZERO
	return MultiplayerInput.get_vector(device, negative_x, positive_x, negative_y, positive_y, deadzone)

## This is equivalent to Input.is_action_just_pressed except it will only check the relevant device.
func is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
	if !is_connected: return false
	return MultiplayerInput.is_action_just_pressed(device, action, exact_match)

## This is equivalent to Input.is_action_just_released except it will only check the relevant device.
func is_action_just_released(action: StringName, exact_match: bool = false) -> bool:
	if !is_connected: return false
	return MultiplayerInput.is_action_just_released(device, action, exact_match)

## This is equivalent to Input.is_action_pressed except it will only check the relevant device.
func is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	if !is_connected: return false
	return MultiplayerInput.is_action_pressed(device, action, exact_match)

## Takes exclusive control over all "ui_" actions.
## See MultiplayerInput.set_ui_action_device() doc for more info.
func take_ui_actions():
	if !is_connected: return
	MultiplayerInput.set_ui_action_device(device)

## Internal method that is called whenever any device is connected or disconnected.
## This is how this object keeps its "is_connected" property updated.
func _on_joy_connection_changed(_device: int, connected: bool):
	if device == _device:
		connection_changed.emit(connected)
		is_connected = connected
