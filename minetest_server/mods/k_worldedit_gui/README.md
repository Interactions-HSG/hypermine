K WorldEdit Command Builder GUI
===============================

# Purpose

Have you ever played [Mineclonia](https://content.minetest.net/packages/ryvnf/mineclonia/) and wished you could use the [`worldedit`](https://content.minetest.net/packages/sfan5/worldedit/) tools but were too scared of messing up chat commands and the `worldedit_gui` does not work because it requires specific inventory GUIs to be installed?

This mod fills that gap by adding a makeshift/semi-convenient GUI frontend to access all registered `worldedit` chat commands via a tool instead of inventory only buttons.

It technically should be compatible with any game unless incompatible with the [flow](https://content.minetest.net/packages/luk3yx/flow/) package which is used to build the UI.

Feel free to open issues for bugs and suggestions.

# Usage/Features

 * Either use in creative mode or `/giveme k_worldedit_gui:command_tablet` to acquire the Tablet of Worldly Commands ![Tablet of Worldly Commands](textures/k_worldedit_gui_tablet.png).
 * Sort of has a far wand built in on `use` (click).
    * Behaves a bit like additive wand. `aux1` + `use` to place maker "above" pointed node instead of "under".
    * Otherwise, markers still works with other worldedit wands as long as they use the same 2 marker system.
 * Available commands depend on player privileges. You will at least require `server` or `worldedit` privilege for most of them.
 * `place` (right-click) to show UI to build commands.
    * Select command from list.
    * Then proceed to param builder.
 * Conveniently set/clear `pos1` and `pos2` coordinates from the UI for finetuning.
 * All available commands are shown and parameter entry is free form. It's what power users call powerful.
    * Especially useful is the `//lua` command where you can now just paste lua code in a text area and run it.
    * Help text and description shown in same window because it's hard remember all that
 * Commands parameters are remembered for that session and are kept separate per command. So you can relaunch the same command with the same parameters multiple times.
 * `<node[1-4]>` placeholder substitution in the command.

# Limitations and Things To Do

 * [`worldeditadditions`](https://content.minetest.net/packages/Starbeamrainbowlabs/worldeditadditions/) and other `worldedit` related mods that register new commands should work, however..
    * Some of the aliases may get muddled and buttons with duplicate functionality may show up.
    * Help text and parameter hints between mods may be inconsistent.
    * todo - hide some of the less useful commands.
 * todo - Node name placeholder search. Currently just a dropdown - lots of scrolling involved.
 * todo - increment/decrement buttons for marker coordinates possibly.
 * More styling, scrollable containers, etc.
 * De-spaghettify code.

# License

Everything [GPL 3.0 or Later](https://spdx.org/licenses/GPL-3.0-or-later.html).
