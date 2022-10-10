# MultiplayerInput
This Godot addon provides two simple APIs for using normal Input Actions, but spread out across a Keyboard player and up to 8 Joypad players.


# Simple Usage

## Installation
1. Download the addons/multiplayer_input directory into your project
1. In Project Settings -> Plugins, find the MultiplayerInput addon and click the "Enable" check box.
1. Change your code to use the new MultiplayerInput singleton instead of the Input singleton anywhere you want to support multiple devices.

## Set up actions
Set up your actions in Project Settings -> Input Manager just like a normal single player game.
You can completely ignore the Device setting in the Input Manager, because the MultiplayerInput singleton handles those automatically.
Set up both your Keyboard and Joypad events on all your actions.
Behind the scenes, when the MultiplayerInput singleton loads, and when joypads connect, it will duplicate all of your Action Maps and assign them the correct device.
This allows you to keep a clean list in your InputMap in the editor, and also have it automatically work how you want with multiple players.

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

## What is "device"?
In a lot of the built-in Input functions, there is a "device" parameter.
It is an integer that uniquely identifies a Joypad.
Device 0 is the first joypad, and device 7 is the 8th joypad, etc.
Additionally, for all MultiplayerInput functions, -1 represents the player using the keyboard and mouse.
So keep in mind that if you pass along the device integer to functions in Input, you should only do so for Joypad players, AKA if device is >= 0.

## How do I let my players join the game?
This is actually a pretty tricky problem to navigate if you have never done it before.
It is also game-specific so I decided to leave that logic out of this tool.
The general idea is each player should keep track of their "device" integer somehow.

Since this is so tricky and I finally have a decent solution, I copied it over into the "demo" folder and stripped it down, so you can see an example of it all working.

If you don't know where to start, I recommend copying demo/player_manager.gd into your project as a starting place for managing players joining, leaving, and keeping player-specific metadata.
I also recommend making your player_manager.gd a singleton in Project Settings -> Autoload so you can access player data anywhere easily.
I also recommend leaving all logic related to the player nodes out of the player manager. It got messy fast when I tried it. Hence the player_joined and player_left signals.

## Why two APIs?
First, I made the MultiplayerInput class be similar to the Input class so it is easy to understand and use.
Then, I realized it would be nice to encapsulate the device integer in a small wrapper that has all the same functions, but passes the device integer for you.
Hence the DeviceInput class.

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

Notice how the player is passed the relevant "device" number, and then the rest of the code looks exactly like using the Input singleton, except it's using a DeviceInput object instead.

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

## What about other Input functions?
You can still use all the normal Input functions, but there are a couple things to keep in mind.

None of the functions with "action" in their name will work as you expect, so use MultiplayerInput for those instead.
This is because behind the scenes, in duplicates the actions and assigns them a different name in this format: "%s%s" % [device, action]

Any of the Input functions that accept a device integer parameter will work with the same device integers that MultiplayerInput functions use, with one exception.
The keyboard player is device -1.
That -1 is specific to MultiplayerInput though.
It will not work if you pass a -1 into any of the Input functions as a device integer.
Behind the scenes, a -1 will tell MultiplayerInput to use the set of actions that you set up in the editor, as opposed to any of the replicated, device-specific ones.
That essentially just means use the keyboard/mouse actions.
