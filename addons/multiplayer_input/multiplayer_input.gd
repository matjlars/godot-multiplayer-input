extends Node
## A globally accessible manager for device-specific actions.
##
## This class automatically duplicates relevant events on all actions for new joypads
## when they connect and disconnect.
## It also provides a nice API to access all the normal "Input" methods,
## but using the device integers and the same action names.
## All methods in this class that have a "device" parameter can accept -1
## which means the keyboard device.
## NOTE: The -1 device will not work on Input methods because it is a specific
## concept to this MultiplayerInput class.
##
## See DeviceInput for an object-oriented way to get input for a single device.

## An array of all the non-duplicated action names
var core_actions = []

# a dictionary of all action names
# the keys are the device numbers
# the values are a dictionary that maps action name to device action name
# for example device_actions[device][action_name] is the device-specific action name
# the purpose of this is to cache all the StringNames of all the actions
# ... so it doesn't need to generate them every time
var device_actions = {}

## Array of GUIDs - If a device with an ignored GUID is detected, no input actions will be added.
var ignored_guids = []

func _init():
	reset()

# Call this if you change any of the core actions or need to reset everything.
func reset():
	InputMap.load_from_project_settings()
	core_actions = InputMap.get_actions()

	# disable joypad events on keyboard actions
	# by setting device id to 8 (out of range, so they'll never trigger)
	# I can't just delete them because they're used as blueprints
	# ... when a joypad connects
	# This skips UI actions so it doesn't mess them up.
	for action in core_actions:
		for e in InputMap.action_get_events(action):
			if _is_joypad_event(e) and !is_ui_action(action):
				e.device = 8

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
	# skip action creation if the device should be ignored
	if Input.get_joy_guid(device) in ignored_guids:
		return

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
			actions_to_erase.append(action)

	# now actually erase them
	# this is done separately so I'm not erasing from the collection I'm looping on
	# not sure if this is necessary but whatever, this is safe
	for action in actions_to_erase:
		InputMap.erase_action(action)



# use these functions to query the action states just like normal Input functions

## This is equivalent to Input.get_action_raw_strength except it will only check the relevant device.
func get_action_raw_strength(device: int, action: StringName, exact_match: bool = false) -> float:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.get_action_raw_strength(action, exact_match)

## This is equivalent to Input.get_action_strength except it will only check the relevant device.
func get_action_strength(device: int, action: StringName, exact_match: bool = false) -> float:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.get_action_strength(action, exact_match)

## This is equivalent to Input.get_axis except it will only check the relevant device.
func get_axis(device: int, negative_action: StringName, positive_action: StringName) -> float:
	if device >= 0:
		negative_action = get_action_name(device, negative_action)
		positive_action = get_action_name(device, positive_action)
	return Input.get_axis(negative_action, positive_action)

## This is equivalent to Input.get_vector except it will only check the relevant device.
func get_vector(device: int, negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, deadzone: float = -1.0) -> Vector2:
	if device >= 0:
		negative_x = get_action_name(device, negative_x)
		positive_x = get_action_name(device, positive_x)
		negative_y = get_action_name(device, negative_y)
		positive_y = get_action_name(device, positive_y)
	return Input.get_vector(negative_x, positive_x, negative_y, positive_y, deadzone)

## This is equivalent to Input.is_action_just_pressed except it will only check the relevant device.
func is_action_just_pressed(device: int, action: StringName, exact_match: bool = false) -> bool:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.is_action_just_pressed(action, exact_match)

## This is equivalent to Input.is_action_just_released except it will only check the relevant device.
func is_action_just_released(device: int, action: StringName, exact_match: bool = false) -> bool:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.is_action_just_released(action, exact_match)

## This is equivalent to Input.is_action_pressed except it will only check the relevant device.
func is_action_pressed(device: int, action: StringName, exact_match: bool = false) -> bool:
	if device >= 0:
		action = get_action_name(device, action)
	return Input.is_action_pressed(action, exact_match)

## Returns the name of a gamepad-specific action
func get_action_name(device: int, action: StringName) -> StringName:
	if device >= 0:
		assert(device_actions.has(device), "Device %s has no actions. Maybe the joypad is disconnected." % device)
		# if it says this dictionary doesn't have the key,
		# that could mean it's an invalid action name.
		# or it could mean that action doesn't have a joypad event assigned
		return device_actions[device][action]

	# return the normal action name for the keyboard player
	return action

## Restricts actions that start with "ui_" to only work on a single device.
## Pass a -2 to reset it back to default behavior, to allow all devices to trigger "ui_" actions.
## For example, pass a -1 if you want only the keyboard/mouse device to control menus.
## NOTE: this calls reset(), so if you make any changes to the InputMap via code, you'll need to make them again.
func set_ui_action_device(device: int):
	# First, totally re-create the InputMap for all devices
	# This is necessary because this function may have messed up the UI Actions
	# ... on a previous call
	reset()
	
	# We are back to default behavior.
	# So if that's what the caller wants, we're done!
	if device == -2: return
	
	# find all ui actions and erase irrelevant events
	for action in InputMap.get_actions():
		# ignore non-ui-actions
		if !is_ui_action(action): break
		
		if device == -1:
			# in this context, we want to erase all joypad events
			for e in InputMap.action_get_events(action):
				if _is_joypad_event(e):
					InputMap.action_erase_event(action, e)
		else:
			# in this context, we want to delete all non-joypad events.
			# and we also want to set the event's device to the given device.
			for e in InputMap.action_get_events(action):
				if _is_joypad_event(e):
					e.device = device
				else:
					# this isn't event a joypad event, so erase it entirely
					InputMap.action_erase_event(action, e)

## Returns true if the given event is a joypad event.
func _is_joypad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion

## Returns true if this is a UI action.
## Which basically just means it starts with "ui_".
## But you can override this in your project if you want.
func is_ui_action(action_name: StringName):
	return action_name.begins_with("ui_")
