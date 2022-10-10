@tool
extends EditorPlugin

const AUTOLOAD_NAME = "MultiplayerInput"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/multiplayer_input/multiplayer_input.gd")

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
