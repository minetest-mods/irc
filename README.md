IRC Mod for Minetest
====================

Introduction
------------
This mod is just a glue between IRC and Minetest. It provides two-way
 communication between the in-game chat, and an arbitrary IRC channel.

The forum topic is at http://minetest.net/forum/viewtopic.php?id=3905

 
Installing
----------

Quick one line install for linux:

	cd <Mod directory> && git clone https://github.com/kaeza/minetest-irc.git irc && cd irc && git submodule update --init

Please change `<Mod directory>` to fit your installation of minetest.
For more information, see [the wiki](http://wiki.minetest.net/Installing_mods).

The Minetest IRC mod uses submodules, therefore you will have to run
`git submodule init` when first installing the mod, and `git submodule update`
every time that a submodule is updated.  These steps can be combined as
`git submodule update --init`.

The Minetest IRC mod also requires LuaSocket.  This can be installed using your
package manager on many distributions, for example on Arch Linux:

	# pacman -S lua51-socket


Settings
--------
All settings are changed in `minetest.conf`. If any of these settings
are not set, the default value is used.

  * `irc.server` (string, default "irc.freenode.net")
	This is the IRC server the mod connects to.

  * `irc.channel` (string, default "##mt-irc-mod")
	The IRC channel to join.

  * `irc.interval` (number, default 2.0)
	This prevents the server from flooding. It should be at
	least 2.0 but can be higher. After four messages this much
	time must pass between folowing messages.

  * `irc.nick` (string, default "MT-FFFFFF")
	Nickname used as "proxy" for the in-game chat. 
	'F' stands for a random base-16 number.

  * `irc.password` (string, default "")
	Password to use when connecting to the server.

  * `irc.NSPass` (string, default nil)
	NickServ password. Don't use this if you use SASL authentication.

  * `irc.sasl.pass` (string, default nil)
	SASL password, same as nickserv password.
	You should use this instead of NickServ authentication
	if the server supports it.

  * `irc.sasl.user` (string, default `irc.nick`)
	The SASL username. This should normaly be set to your main NickServ account name.

  * `irc.debug` (boolean, default false)
	Whether to output debug information.

  * `irc.disable_auto_connect` (boolean, default false)
	If false, the bot is connected by default. If true, a player with
	the 'irc_admin' privilege has to use the /irc_connect command to
	connect to the server.

  * `irc.disable_auto_join` (boolean, default false)
	If false, players join the channel automatically upon entering the
	game. If true, each user must manually use the /join command to
	join the channel. In any case, the players may use the /part
	command to opt-out of being in the channel.

  * `irc.send_join_part` (boolean, default true)
	Determines whether to send player join and part messages to the channel.

Usage
-----

Once the game is connected to the IRC channel, chatting using the 'T' or
F10 hotkeys will send the messages to the channel, and will be visible
by anyone. Also, when someone sends a message to the channel, that text
will be visible in-game.

Messages that begin with `[off]` from in-game or IRC are not sent to the
other side.

This mod also adds a few chat commands:

  * `/irc_msg <nick> <message>`
	Sends a private message to a IRC user.

  * `/join`
	Join the IRC chat.

  * `/part`
	Part the IRC chat.

  * `/irc_connect`
	Connect the bot manually to the IRC network.

  * `/irc_disconnect`
	Disconnect the bot manually from the IRC network (this does not
	shutdown the game).

  * `/irc_reconnect`
	Equivilant to `/irc_disconnect` followed by `/irc_connect`.

You can also send private messages from IRC to in-game players.

To do it, you must send a private message to the bot (set with
the `irc.nick` option above), in the following format:

	@playername message

For example, if there's a player named `mtuser`, you can send him/her
a private message from IRC with:

	/msg server_nick @mtuser Hello!

To avoid possible misunderstandings (since all in-game players use the
same IRC user to converse with you), the "proxy" user will reject any
private messages that are not in that format, and will send back a
nice reminder as a private message.

The bot also supports some basic commands, which are invoked by sending
a private message to it. Use `!list` to get a list of commands, and
`!help <command>` to get help about a specific command.


Thanks
------

I'd like to thank the users who supported this mod both on the Minetest
Forums and on the #minetest channel. In no particular order:

0gb.us, ShadowNinja, Shaun/kizeren, RAPHAEL, DARGON, Calinou, Exio,
vortexlabs/mrtux, marveidemanis, marktraceur, jmf/john\_minetest,
sdzen/Muadtralk, VanessaE, PilzAdam, sfan5, celeron55, KikaRz,
OldCoder, RealBadAngel, and all the people who commented in the
forum topic. Thanks to you all!


License
-------

(C) 2012-2013 Diego Martínez <kaeza@users.sf.net>

See LICENSE.txt for licensing information.

The files in the irc directory are part of the LuaIRC project.
See irc/LICENSE.txt for licensing information.

