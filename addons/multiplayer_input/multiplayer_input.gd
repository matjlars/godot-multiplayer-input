extends Node

# This is an autoloaded class that can be accessed at MultiplayerInput
# device of (-1) means the keyboard player
# when a device connects, actions are created for that device
# these dynamically created action names start with the device number
#
# this is an example of how to allow players to join in your PlayerManager
#
# signal player_joined(device)
# func is_device_joined(device: int) -> bool:
#     pass # implement this for your game. return true if there are any players with this device.
# func unjoined_devices():
#     var valid_devices = Input.get_connected_joypads()
#     valid_devices.append(-1) # also consider the keyboard player (device -1 for MultiplayerInput functions)
#     return valid_devices.filter(func(device): return is_device_joined(device))
# func _process(_delta):
#     for device in unjoined_devices():
#         if MultiplayerInput.is_action_just_pressed(device, "join"):
#             player_joined.emit(device)

# an array of all the non-duplicated action names
var core_actions = []

# a dictionary of all action names
# the keys are the device numbers
# the values are a dictionary that maps action name to device action name
# for example device_actions[device][action_name] is the device-specific action name
# the purpose of this is to cache all the StringNames of all the actions
# ... so it doesn't need to generate them every time
var device_actions = {}

func _init():
	reset()

# call this if you change any of the core actions or need to reset everything
func reset():
	InputMap.load_from_project_settings()
	core_actions = InputMap.get_actions()
	
	# disable joypad events on keyboard actions
	# by setting device id to 8 (out of range, so they'll never trigger)
	# I can't just delete them because they're used as blueprints
	# ... when a joypad connects
	for action in core_actions:
		for e in InputMap.action_get_events(action):
			if _is_joypad_event(e):
				e.device = 8
	
	# create actions for already connected gamepads
	for device in Input.get_connected_joypads():
		_create_actions_for_device(device)
	
	# create actions for gamepads that connect in the future
	# also clean up when gamepads disconnect
	if !Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(device: int, connected: bool):
	if connected:
		_create_actions_for_device(device)
	else:
		_delete_actions_for_device(device)

func _create_actions_for_device(device: int):
	device_actions[device] = {}
	for core_action in core_actions:
		var new_action = "%s%s" % [device, core_action]
		var deadzone = InputMap.action_get_deadzone(core_action)
		
		# get all joypad events for this action
		var events = InputMap.action_get_events(core_action).filter(_is_joypad_event)
		
		# only copy this event if it is relevant to joypads
		if events.size() > 0:
			# first add the action with the new name
			InputMap.add_action(new_action, deadzone)
			device_actions[device][core_action] = new_action
			
			# then copy all the events associated with that action
			# this only includes events that are relevant to joypads
			for event in events:
				# without duplicating, all of them have a reference to the same event object
				# which doesn't work because this has to be unique to this device
				var new_event = event.duplicate()
				new_event.device = device
				
				# switch the device to be just this joypad
				InputMap.action_add_event(new_action, new_event)

func _delete_actions_for_device(device: int):
	device_actions.erase(device)
	var actions_to_erase = []
	var device_num_str = str(device)
	
	# figure out which actions should be erased
	for action in InputMap.get_actions():
		var action_str = String(action)
		var maybe_device = action_str.substr(0, device_num_str.length())
		if maybe_device == device_num_str:
			actions_to_erase = action
	
	# now actually erase them
	# this is done separately so I'm not erasing from the collection I'm looping on
	# not sure if this is necessary but whatever, this is safe
	for action in actions_to_erase:
		InputMap.erase_action(action)



# use these functions to query the action states just like normal Input functions

func get_action_raw_strength(device: int, action: StringName, exact_match: bool = false) -> float:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.get_action_raw_strength(action, exact_match)
	
func get_action_strength(device: int, action: StringName, exact_match: bool = false) -> float:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.get_action_strength(action, exact_match)

func get_axis(device: int, negative_action: StringName, positive_action: StringName) -> float:
	if device >= 0:
		negative_action = get_action_name(device, negative_action)
		positive_action = get_action_name(device, positive_action)
	return Input.get_axis(negative_action, positive_action)

func get_vector(device: int, negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, deadzone: float = -1.0) -> Vector2:
	if device >= 0:
		negative_x = get_action_name(device, negative_x)
		positive_x = get_action_name(device, positive_x)
		negative_y = get_action_name(device, negative_y)
		positive_y = get_action_name(device, positive_y)
	return Input.get_vector(negative_x, positive_x, negative_y, positive_y, deadzone)

func is_action_just_pressed(device: int, action: StringName, exact_match: bool = false) -> bool:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.is_action_just_pressed(action, exact_match)

func is_action_just_released(device: int, action: StringName, exact_match: bool = false) -> bool:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.is_action_just_released(action, exact_match)

func is_action_pressed(device: int, action: StringName, exact_match: bool = false) -> bool:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.is_action_pressed(action, exact_match)

# returns the name of a gamepad-specific action
func get_action_name(device: int, action: StringName) -> StringName:
	if device >= 0:
		# if it says this dictionary doesn't have the key,
		# that could mean it's an invalid action name.
		# or it could mean that action doesn't have a joypad event assigned
		return device_actions[device][action]
	
	# return the normal action name for the keyboard player
	return action

func _is_joypad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion
