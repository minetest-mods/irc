[![](https://github.com/minetest-mods/irc/workflows/Check%20&%20Release/badge.svg)](https://github.com/minetest-mods/irc/actions)

IRC Mod for Minetest
====================

Introduction
------------

This mod is just a glue between IRC and Minetest. It provides two-way
 communication between the in-game chat, and an arbitrary IRC channel.

The forum topic is [here][forum].

[forum]: https://forum.minetest.net/viewtopic.php?f=11&t=3905


Installing
----------

Quick one line install for Linux:

	cd <Mods directory> && git clone --recursive https://github.com/minetest-mods/irc.git

Please change `<Mods directory>` to fit your installation of Minetest.
For more information, see [the wiki][wiki].

The IRC mod's git repository uses submodules, therefore you will have to run
`git submodule init` when first installing the mod (unless you used
`--recursive` as above), and `git submodule update` every time that a submodule
is updated. These steps can be combined into `git submodule update --init`.

You'll need to install LuaSocket. You can do so with your package manager on
many distributions, for example:

	# # On Arch Linux:
	# pacman -S lua51-socket
	# # On Debian/Ubuntu:
	# # Debian/Ubuntu's LuaSocket packages are broken, so use LuaRocks.
	# apt-get install luarocks
	# luarocks install luasocket

You will also need to add IRC to your trusted mods if you haven't disabled mod
security. Here's an example configuration line:

	secure.trusted_mods = irc

[wiki]: https://wiki.minetest.net/Installing_mods


Settings
--------

All settings are changed in `minetest.conf`. If any of these settings
are not set, the default value is used.

* `irc.server` (string):
  The address of the IRC server to connect to.

* `irc.channel` (string):
  The IRC channel to join.

* `irc.interval` (number, default 2.0):
  This prevents the server from flooding. It should be at
  least 2.0 but can be higher. After four messages this much
  time must pass between folowing messages.

* `irc.nick` (string):
  Nickname the server uses when it connects to IRC.

* `irc.password` (string, default nil):
  Password to use when connecting to the server.

* `irc.NSPass` (string, default nil):
  NickServ password. Don't set this if you use SASL authentication.

* `irc.sasl.pass` (string, default nil):
  SASL password, same as nickserv password.
  You should use this instead of NickServ authentication
  if the server supports it.

* `irc.sasl.user` (string, default `irc.nick`):
  The SASL username. This should normaly be set to your
  NickServ account name.

* `irc.debug` (boolean, default false):
  Whether to output debug information.

* `irc.disable_auto_connect` (boolean, default false):
  If false, the bot is connected by default. If true, a player with
  the 'irc_admin' privilege has to use the `/irc_connect` command to
  connect to the server.

* `irc.disable_auto_join` (boolean, default false):
  If false, players join the channel automatically upon entering the
  game. If true, each user must manually use the `/join` command to
  join the channel. In any case, the players may use the `/part`
  command to opt-out of being in the channel.

* `irc.send_join_part` (boolean, default true):
  Determines whether to send player join and part messages to the channel.


Usage
-----

Once the game is connected to the IRC channel, chatting in-game will send
messages to the channel, and will be visible by anyone. Also, messages sent
to the channel will be visible in-game.

Messages that begin with `[off]` from in-game or IRC are not sent to the
other side.

This mod also adds a few chat commands:

* `/irc_msg <nick> <message>`:
  Send a private message to a IRC user.

* `/join`:
  Join the IRC chat.

* `/part`:
  Part the IRC chat.

* `/irc_connect`:
  Connect the bot manually to the IRC network.

* `/irc_disconnect`:
  Disconnect the bot manually from the IRC network (this does not
  shutdown the game).

* `/irc_reconnect`:
  Equivalent to `/irc_disconnect` followed by `/irc_connect`.

You can also send private messages from IRC to in-game players
by sending a private message to the bot (set with the `irc.nick`
option above), in the following format:

	@playername message

For example, if there's a player named `mtuser`, you can send him/her
a private message from IRC with:

	/msg server_nick @mtuser Hello!

The bot also supports some basic commands, which are invoked by saying
the bot name followed by either a colon or a comma and the command, or
sending a private message to it. For example: `ServerBot: help whereis`.

* `help [<command>]`:
  Prints help about a command, or a list of supported commands if no
  command is given.

* `uptime`:
  Prints the server's running time.

* `whereis <player>`:
  Prints the coordinates of the given player.

* `players`:
  Lists players currently in the server.


Thanks
------

I'd like to thank the users who supported this mod both on the Minetest
Forums and on the `#minetest` channel. In no particular order:

0gb.us, ShadowNinja, Shaun/kizeren, RAPHAEL, DARGON, Calinou, Exio,
vortexlabs/mrtux, marveidemanis, marktraceur, jmf/john\_minetest,
sdzen/Muadtralk, VanessaE, PilzAdam, sfan5, celeron55, KikaRz,
OldCoder, RealBadAngel, and all the people who commented in the
forum topic. Thanks to you all!


License
-------

See `LICENSE.txt` for details.

The files in the `irc` directory are part of the LuaIRC project.
See `irc/LICENSE.txt` for details.
