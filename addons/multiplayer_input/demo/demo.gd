extends Node

# this is a singleton autoload in my project but for the purposes of this demo,
# this is simpler
@onready var player_manager = $PlayerManager

# map from player integer to the player node
var player_nodes = {}

func _ready():
	player_manager.player_joined.connect(spawn_player)
	player_manager.player_left.connect(delete_player)

func _process(_delta):
	player_manager.handle_join_input()

func spawn_player(player: int):
	# create the player node
	var player_scene = load("res://demo/demo_player.tscn")
	var player_node = player_scene.instantiate()
	player_node.leave.connect(on_player_leave)
	player_nodes[player] = player_node
	
	# let the player know which device controls it
	var device = player_manager.get_player_device(player)
	player_node.init(player, device)
	
	# add the player to the tree
	add_child(player_node)
	
	# random spawn position
	player_node.position = Vector2(randf_range(50, 400), randf_range(50, 400))

func delete_player(player: int):
	player_nodes[player].queue_free()
	player_nodes.erase(player)

func on_player_leave(player: int):
	# just let the player manager know this player is leaving
	# this will, through the player manager's "player_left" signal,
	# indirectly call delete_player because it's connected in this file's _ready()
	player_manager.leave(player)
