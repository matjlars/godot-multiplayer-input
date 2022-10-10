extends Node2D

signal leave

var player: int
var input

# call this function when spawning this player to set up the input object based on the device
func init(player_num: int, device: int):
	player = player_num
	
	# in my project, I got the device integer by accessing the singleton autoload PlayerManager
	# but for simplicity, it's not an autoload in this demo.
	# but I recommend making it a singleton so you can access the player data from anywhere.
	# that would look like the following line, instead of the device function parameter above.
	# var device = PlayerManager.get_player_device(player)
	input = DeviceInput.new(device)
	
	$Player.text = "%s" % player_num

func _process(_delta):
	var move = input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += move
	
	# let the player leave by pressing the "join" button
	if input.is_action_just_pressed("join"):
		# an alternative to this is just call PlayerManager.leave(player)
		# but that only works if you set up the PlayerManager singleton
		leave.emit(player)
