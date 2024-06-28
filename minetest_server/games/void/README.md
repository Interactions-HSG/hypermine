*Void – A Game That Contains Nothing*

This game for Minetest was reduced to the bare minimum of files and configuration. It contains quite literally “nothing”. It registers no more items than the essentially needed nodes and the hand.

The game is not meant for playing (well, of course you can but there is nothing fun to do except digging the three essential nodes and placing them again). The purpose of this game is to test mods in an absolutely “clean” environment with absolutely no “3rd-party” mods or APIs provided by such mods.

## Contents

### Game Files

Some necessary game files are used.

* `game.conf` – Sets the human-readable name of the game as per Minetest API
* `README.md` – This document
* `LICENSE.txt` – Licensing information for the whole game including all the mods
* `mods/void_essential` – This mod adds essential things for properly running a map generator
* `mods/void_hand` – This mod registers the “hand” tool for proper interaction with nodes (i.e. node breaking)

### Void Essential Mod

The `void_essential` mod contains all that is needed for the map generator to create a usable world for testing mods. The following items and nodes are registered by that mod.

* `void_essential:stone` aliased to `mapgen_stone` – This is an essential node used by map generators to generate the terrain. Without that node you would fall all the way down to the bottom of the world and could not place anything on ground, because there literally is no ground
* `void_essential:water_source` aliased to `mapgen_water_source` – Same as with the stone node the water source is one of the essential nodes that are used by map generators to generate the terrain. Without this node, all bodies of water would not be existent. The registered node does not have ANY water properties. It does not spread out, you cannot swim in it, you cannot see through it. IT basically is just a node named “water”
* `void_essential:river_water_source` aliased to `mapgen_river_water_source` – This is exactly the same as with the other water source node and is also one of the essential map generator nodes that need to be registered in order to have proper terrain generation.

All nodes have the only group `oddly_breakable_by_hand = 3` set. The nodes also have `is_ground_content = true` set so the map generator can carve through them when generating caves, etc.

The mod also provides three simple textures.

* `void_essential_stone.png` for the essential stone node
* `void_essential_water_source.png` for the essential water source node
* `void_essential_river_water_source.png` for the essential river water source node

This mod uses the bare minimum that is needed for mods.

### Void Hand Mod

`void_hand` registers the hand tool is not technically needed to generate terrain and entering a world but not having it testing would become unnecessary complicated because the unconfigured hand does not even allow to break nodes that are configured to be *breakable by hand*.

* `:` – The “hand tool” registration. Tool capabilities are identical to the capabilities used by *Minetest Game* because it was seen as default since most of the time. The `wield_scale` was slightly changed (`{x = 0.5, y = 1, z = 4}` instead of `{x = 1, y = 1, z = 2.5}`) which only results in visual changes.

This mod also adds a simple texture.

* `void_hand_hand.png` for the registered “hand tool”

This mod also uses the bare minimum that is needed for mods.

## Usage

To use this game simply switch to the game in the client and create a new world. You can use all standards compliant map generators with all of the settings. Except the three essential nodes (stone, water, river water) and the “hand tool” nothing is registered or loaded, or provided. You’ll have a pure, absolutely independent, bare minimum version of a game.

In order to test your mods simply configure the created world and add the mods as needed for testing. Then start the world and see what’s happening. Since there is no creative inventory turning on creative mode does not change the Minetest-provided default inventory. You need a mod for that or use the `/giveme` command.

## Legal Information

* All code and all documentation of this game and all code and all documentation of all mods of this game are are licensed under the *MIT license*.
* All media files of the game and all media files in all of the game’s mods are licensed under the *Creative Commons Attribution 4.0 International* license (*CC BY 4.0*).
