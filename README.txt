IRC Mod for Minetest
(C) 2012 Diego Martínez <kaeza@users.sf.net>

INTRODUCTION
------------
This mod is just a glue between luasocket, LuaIRC, and Minetest. It
 provides a two-way communication between the in-game chat, and an
 arbitrary IRC channel. 

 
COMPILING
---------
Make sure you have CMake (http://cmake.org/), and of course, a C compiler,
 on your system before proceeding.
For Windows, try MinGW32 (http://mingw.org/).
For Unix-based systems, you should not have any problems with the C compiler
 since there's one (almost) always available. Puppy Linux users of course
 need a separate `devx.sfs' (from the same place where you got the Puppy
 ISO), since vanilla Puppy does not come with `gcc'. See your Puppy docs for
 more info about how to install additional SFS files.

Quick one line build for linux.  

git clone https://github.com/kaeza/minetest-irc.git && cd minetest-irc && mkdir build && cd build && cmake .. && make && make pack_mod && cp -R irc <your mod directory>
Plese change the "cp -R irc" to fit your install of minetest.

To compile and "pack" the mod:

  - Open a command prompt/terminal and CD to the minetest-irc directory.
  - Create a directory named "Build", and CD into it:
      mkdir Build
      cd Build
  - Run CMake to generate the build system (see your CMake docs for more
     information about command line options, in particular the `-G' option).
      cmake ..
  - Use the build tool for the generated build system to compile the
     native library. For example, if using Microsoft Visual Studio, open
     the generated workspace and build from there. If using make, just run
     "make" from within the Build directory.
  - Again use the build tool to invoke the `pack_mod' target. For example,
     if using `make', run "make pack_mod" from within the build directory.
     This will create an `irc' directory inside the build directory.
     This `irc' directory will be ready to be deployed to your Minetest mods
     directory.


INSTALLING
----------
Just put the created `irc' directory in any of the directories where
 Minetest looks for mods. For more information, see:
    http://wiki.minetest.net/wiki/Installing_mods


SETTINGS
--------
All settings are changed in the `config.lua' file. If any of these settings
 are either nil or false, the default value is used.

    mt_irc.server (string, default "irc.freenode.net")
        This is the IRC server the mod connects to.

    mt_irc.channel (string, default "#minetest-irc-testing")
        The IRC channel to join.

    mt_irc.dtime (number, default 0.2)
        This is the time in seconds between updates in the connection.
        In order not to block the game, the mod must periodically "poll"
        the connection to both send messages to, and receive messages
        from the channel. A high value means slower connection to IRC,
        but possibly better response from the game. A low value means
        the mod "polls" the connection more often, but can make the
        game hang. It allows fractional values.

    mt_irc.timeout (number, default 60.0)
        Underlying socket timeout in seconds. This is the time before
        the system drops an idle connection.

    mt_irc.server_nick (string, default "minetest-"..<server-id>)
        Nickname used as "proxy" for the in-game chat. 
        "<server-id>" is the server IP address packed as a 32 bit integer.
        (Currently, it's just a random 32 bit number).

    mt_irc.password (string, default "")
        Password to use when connecting to the server.

    mt_irc.message_format_out (string, default "<$(name)> $(message)")
        This specifies how to send the messages from in-game to IRC.
        The strings can contain "macros" (or variable substitutions), which
        are specified as "$(macro_name)".
        Currently, these macros are supported:
          $(name)       The name of the player sending the message.
          $(message)    The actual message text.
        Any unrecognized macro will be left in the message verbatim.
        For example, if a user named "mtuser" is saying "Hello!", then:
          "<$(name)> $(message)"
        ...will yield...
          "<mtuser> Hello!"
        ...and...
          "$(name): $(message) $(xyz)"
        ...will yield...
          "mtuser: Hello! $(xyz)"

    mt_irc.message_format_in (string,
     default "<$(name)@IRC> $(message)")
        This specifies how the messages gotten from the IRC channel are
        displayed in-game.
        The strings can contain "macros" (or variable substitutions), which
        are specified as "$(macro_name)".
        Currently, these macros are supported:
          $(name)       The nickname of the user sending the message.
          $(message)    The actual message text.
          $(server)     The IRC server.
          $(port)       The IRC server port.
          $(channel)    The IRC channel.
        In the default configuration, this will yield:
          <mtuser@IRC[#minetest-irc-testing]> Hello!

    mt_irc.debug (boolean, default false)
        Whether to output debug information.

    mt_irc.auto_connect (boolean, default false)
        If true, the bot is connected by default. If false, a player with
         `irc_admin' privilege has to use the /irc_connect command to
         connect to the server.

    mt_irc.auto_connect (boolean, default false)
        If true, players join the channel automatically upon entering the
         game. If false, each user must manually use the /join command to
         join the channel. In any case, the players may use the /part
         command to opt-out of being in the channel.

USAGE
-----
Once the game is connected to the IRC channel, chatting using the 'T' or
 F10 hotkeys will send the messages to the channel, and will be visible
 by anyone. Also, when someone sends a message to the channel, that text
 will be visible in-game.

This mod also adds a few chat commands:

    /msg <nick> <message>
        Sends a private message to the IRC user whose nickname is `nick'.

    /join
        Join the IRC channel.

    /part
        Part the IRC channel.

You can also send private messages from IRC to in-game players, though
 it's a bit tricky.

To do it, you must send a private message to the "proxy" user (set with
 the `mt_irc.server_nick' option above), in the following format:
    >playername message
For example, if there's a player named `mtuser', you can send him/her
 a private message with:
    /msg server_nick >mtuser Hello!

To avoid possible misunderstandings (since all in-game players use the
 same IRC user to converse with you), the "proxy" user will reject any
 private messages that are not in that format, and will send back a
 nice reminder as a private message.


THANKS
------
I'd like to thank the users who supported this mod both on the Minetest
 Forums and on the #minetest channel. In no particular order:

    leo_rockway, VanessaE, OldCoder, sfan5, RealBadAngel, Muadtralk/sdzen,
     Josh, celeron55, KikaRz, and many others I forgot about (sorry!).

LICENSE
-------
This license applies only to the `init.lua' and `config.lua' files.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
                    Version 2, December 2004 

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net> 

 Everyone is permitted to copy and distribute verbatim or modified 
 copies of this license document, and changing it is allowed as long 
 as the name is changed. 

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 

  0. You just DO WHAT THE FUCK YOU WANT TO. 

The files `http.lua', `ltn12.lua', `mime.lua', `smtp.lua', `socket.lua',
 and `url.lua' are part of the luasocket project
 (http://luasocket.luaforge.org/). See `LICENSE-luasocket.txt' for
 licensing information.

The `irc.lua' file and the entire contents of the `irc' directory are part
 of the LuaIRC project (http://luairc.luaforge.org/). See
 `LICENSE-LuaIRC.txt' for licensing information.
