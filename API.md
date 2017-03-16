IRC Mod API
===========

This file documents the Minetest IRC mod API.

Basics
------

In order to allow your mod to interface with this mod, you must add `irc`
to your mod's `depends.txt` file.


Reference
---------

irc.say([name,] message)
Sends <message> to either the channel (if <name> is nil or not specified),
or to the given user (if <name> is specified).
Example:
	irc.say("Hello, Channel!")
	irc.say("john1234", "How are you?")

irc.register_bot_command(name, cmdDef)
	Registers a new bot command named <name>.
	When an user sends a private message to the bot with the command name, the
	command's function is called.
	Here's the format of a command definition (<cmdDef>):
		cmdDef = {
			params = "<param1> ...",      -- A description of the command's parameters
			description = "My command",   -- A description of what the command does. (one-liner)
			func = function(user, args)
				-- This function gets called when the command is invoked.
				-- <user> is a user table for the user that ran the command.
				--   (See the LuaIRC documentation for details.)
				--   It contains fields such as 'nick' and 'ident'
				-- <args> is a string of arguments to the command (may be "")
				-- This function should return boolean success and a message.
			end,
		};
	Example:
		irc.register_bot_command("hello", {
			params = "",
			description = "Greet user",
			func = function(user, param)
				return true, "Hello!"
			end,
		});

irc.joined_players[name]
	This table holds the players who are currently on the channel (may be less
	than the players in the game). It is modified by the /part and /join chat
	commands.
	Example:
	if irc.joined_players["joe"] then
		-- Joe is talking on IRC
	end

irc.register_hook(name, func)
	Registers a function to be called when an event happens. <name> is the name
	of the event, and <func> is the function to be called. See HOOKS below
	for more information
	Example:
	irc.register_hook("OnSend", function(line)
		print("SEND: "..line)
	end)

This mod also supplies some utility functions:

string.expandvars(string, vars)
	Expands all occurrences of the pattern "$(varname)" with the value of
	'varname' in the <vars> table. Variable names not found on the table
	are left verbatim in the string.
	Example:
	local tpl = "$(foo) $(bar) $(baz)"
	local s = tpl:expandvars({foo=1, bar="Hello"})
	assert(s == "1 Hello $(baz)") 

In addition, all the configuration options decribed in `README.txt` are
available to other mods, though they should be considered read-only. Do
not modify these settings at runtime or you might crash the server!


Hooks
-----

The `irc.register_hook` function can register functions to be called
when some events happen. The events supported are the same as the LuaIRC
ones with a few added (mostly for internal use).
See src/LuaIRC/doc/irc.luadoc for more information.

