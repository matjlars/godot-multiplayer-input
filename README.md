# MultiplayerInput
This Godot addon provides two simple APIs for using normal Input Actions, but spread out across a Keyboard player and up to 8 Joypad players.


# Simple Usage

## Set up actions
Set up your actions in Project Settings -> Input Manager just like a normal single player game.
You can completely ignore the Device setting in the Input Manager, because this tool handles those automatically.
Set up both your Keyboard and Joypad events on all your actions.

## Use this tool to query input actions
Basically, instead of doing this:

```
Input.is_action_pressed("jump")
```

You want to instead do this:

```
MultiplayerInput.is_action_pressed(device, "jump")
```

So you may be wondering, what is "device"?

## What is "device"
In a lot of the built-in Input functions, there is a "device" parameter.
It is an integer that uniquely identifies a Joypad.
Device 0 is the first joypad, and device 7 is the 8th joypad, etc.
Additionally, for all MultiplayerInput functions, -1 represents the player using the keyboard and mouse.
So keep in mind that if you pass along the device integer to functions in Input, you should only do so for Joypad players, AKA if device is >= 0.

## How do I let my players join the game?
This is game-specific so I decided to leave that logic out of this tool.
The general idea is each player should keep track of their "device" integer somehow.
Joining can be a tricky problem, so I have put together a minimal example below.

## Why two APIs?
First, I made the MultiplayerInput class be similar to the Input class so it is easy to understand and use.
Then, I realized it would be nice to encapsulate the device integer in a small wrapper that has all the same functions, but passes the device integer for you.
In other words, it is sort of an object oriented replacement of the Input singleton, that is scoped to a single device.
Here is a basic usage example:

```
# player_controller.gd
var input
func set_device(device: int):
    input = DeviceInput.new(device)
func _process(delta):
    if input.is_action_just_pressed("jump"):
        jump()
```

Take a look at addons/multiplayer_input/device_input.gd for all the functions.

The great thing is, this works for the keyboard player as well as any of the joypad players if you use a device integer of -1 for the keyboard player.

## What about mouse input?
If you want to do some logic that doesn't work with the actions system, for example reading relative mouse input, just do an if statement like this:

```
var input
func _input(event):
    if !input.is_keyboard(): return
    # in this context, you know this is a keyboard/mouse player, so you can read mouse input here and do stuff
```

## Join Game Example
TODO paste minimal Player Join code here
