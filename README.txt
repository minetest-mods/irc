IRC Mod for Minetest
(C) 2012-2013 Diego Martínez <kaeza@users.sf.net>

INTRODUCTION
------------
This mod is just a glue between luasocket, LuaIRC, and Minetest. It
 provides a two-way communication between the in-game chat, and an
 arbitrary IRC channel. 

The forum topic is at http://minetest.net/forum/viewtopic.php?id=3905

 
COMPILING
---------
Make sure you have CMake (http://cmake.org/), and of course, a C compiler,
 on your system before proceeding.
For Windows, try MinGW32 (http://mingw.org/).
For Unix-based systems, you should not have any problems with the C compiler
 since there's one (almost) always available. Puppy Linux users of course
 need a separate 'devx.sfs' (from the same place where you got the Puppy
 ISO), since vanilla Puppy does not come with 'gcc'. See your Puppy docs for
 more info about how to install additional SFS files.

Quick one line build for linux.  

git clone https://github.com/kaeza/minetest-irc.git && cd minetest-irc && git submodule update --init && ./quick_install.sh <mod directory>
Please change <mod directory> to fit your install of minetest.

To compile and pack the mod:

  - Open a command prompt/terminal and CD to the minetest-irc directory.
  - (optional) Create a directory named "Build", and CD into it:
      mkdir Build
      cd Build
  - Run CMake to generate the build system (see your CMake docs for more
     information about command line options, in particular the '-G' option).
      cmake . (cmake .. if you made a seperate build directory)
  - Use the build tool for the generated build system to compile the
     native library. For example, if using Microsoft Visual Studio, open
     the generated workspace and build from there. If using make, just run
     "make" from within the Build directory.
  - After building you will have a folder named 'irc' in your build folder.
     Move that to your mod folder.


INSTALLING
----------
Just put the created 'irc' directory in any of the directories where
 Minetest looks for mods. For more information, see:
    http://wiki.minetest.com/wiki/Installing_mods


SETTINGS
--------
All settings are changed in 'minetest.conf'. If any of these settings
 are either not set or false, the default value is used.

    irc.server (string, default "irc.freenode.net")
        This is the IRC server the mod connects to.

    irc.channel (string, default "##mt-irc-mod")
        The IRC channel to join.

    irc.interval (number, default 2.0)
        This prevents the server from flooding. It should be at
        least 2.0 but can be higher. After four messages this much
        time must pass between folowing messages.

    irc.timeout (number, default 60.0)
        Underlying socket timeout in seconds. This is the time before
        the system drops an idle connection.

    irc.nick (string, default "minetest-"..<server-id>)
        Nickname used as "proxy" for the in-game chat. 
        "<server-id>" is a random 32 bit number.

    irc.password (string, default "")
        Password to use when connecting to the server.

    irc.NSPass (string, default nil)
        NickServ password. Don't use this if you use SASL authentication.

    irc.SASLPass (string, default nil)
        SASL password, same as nickserv password.
        You should use this instead of NickServ authentication
        if the server supports it.

    irc.SASLUser (string, default irc.nick)
        The SASL username. This should normaly be set to your main NickServ account name.

    irc.debug (boolean, default false)
        Whether to output debug information.

    irc.disable_auto_connect (boolean, default false)
        If false, the bot is connected by default. If true, a player with
         the 'irc_admin' privilege has to use the /irc_connect command to
         connect to the server.

    irc.disable_auto_join (boolean, default false)
        If false, players join the channel automatically upon entering the
         game. If true, each user must manually use the /join command to
         join the channel. In any case, the players may use the /part
         command to opt-out of being in the channel.

USAGE
-----
Once the game is connected to the IRC channel, chatting using the 'T' or
 F10 hotkeys will send the messages to the channel, and will be visible
 by anyone. Also, when someone sends a message to the channel, that text
 will be visible in-game.

Messages that begin with "[off]" from in-game or IRC are not sent to the
 other side.

This mod also adds a few chat commands:

    /irc_msg <nick> <message>
        Sends a private message to a IRC user.

    /join
        Join the IRC channel.

    /part
        Part the IRC channel.

    /irc_connect
        Connect the bot manually to the IRC network.

    /irc_disconnect
        Disconnect the bot manually from the IRC network (this does not
        shutdown the game).

    /irc_reconnect
        Equivilant to /irc_disconnect followed by /irc_connect.

You can also send private messages from IRC to in-game players, though
 it's a bit tricky.

To do it, you must send a private message to the bot (set with
 the 'irc.nick' option above), in the following format:
    @playername message
For example, if there's a player named 'mtuser', you can send him/her
 a private message from IRC with:
    /msg server_nick @mtuser Hello!

To avoid possible misunderstandings (since all in-game players use the
 same IRC user to converse with you), the "proxy" user will reject any
 private messages that are not in that format, and will send back a
 nice reminder as a private message.

The bot also supports some basic commands, which are invoked by sending
 a private message to it. Use '!help' to get a list of commands, and
 '!help <command>' to get help about a specific command.


THANKS
------
I'd like to thank the users who supported this mod both on the Minetest
 Forums and on the #minetest channel. In no particular order:

    0gb.us, ShadowNinja, Shaun/kizeren, RAPHAEL, DARGON, Calinou, Exio,
    vortexlabs/mrtux, marveidemanis, marktraceur, jmf/john_minetest,
    sdzen/Muadtralk, VanessaE, PilzAdam, sfan5, celeron55, KikaRz,
    OldCoder, RealBadAngel, and all the people who commented in the
    forum topic. Thanks to you all!


LICENSE
-------

See src/LICENSE.txt for licensing information.

The files in src/lua are part of the lua project.
 See src/lua/LICENSE.txt for licensing information.

The files in src/luasocket are part of the luasocket project
 (http://luasocket.luaforge.org/). See 'src/luasocket/LICENSE.txt' for
 licensing information.

The files in src/LuaIRC are part of the LuaIRC project.
 See src/LuaIRC/LICENSE.txt for licensing information.

