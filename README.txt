
IRC Mod for Minetest
(C) 2012 Diego Martínez <kaeza@users.sf.net>

INTRODUCTION
------------
This mod is just a glue between luasocket, LuaIRC, and Minetest. It
 provides a two-way communication between the in-game chat, and an
 arbitrary IRC channel. 

Note: This mod is currently a work-in-progress, and is only tested under
       Ubuntu 12.04 with Minetest 0.4.3 and 0.4.4-dev. Testers for other
       platforms are welcome.


COMPILING
---------
Make sure you have CMake (http://cmake.org/), and of course, a C compiler,
 on your system before proceeding.

Under Windows: (note: untested)
  - Open a command prompt and CD to the minetest-irc directory.
  - Create a directory named "Build", and CD into it:
      md Build
      cd Build
  - Run CMake to generate the build system (see your CMake docs for more
     information about command line options).
      cmake ..
  - Use the build tool for the generated build system to compile the
     native library. For example, if using Microsoft Visual Studio, open
     the generated workspace and build from there. If using make, just run
     "make" from within the Build directory.
  - Use the packmod.bat batch file to copy the files into a ready to use
     mod directory named `irc'.

Under Linux:
  - From a terminal, CD to the minetest-irc directory.
  - Create a directory named "Build", and CD into it:
      mkdir Build
      cd Build
  - Run CMake to generate the build system (see your CMake docs for more
     information about command line options).
      cmake ..
  - Use the build tool for the generated build system to compile the
     native library. For example, if using Code::Blocks, open the generated
     workspace and build from there. If using `make', just run "make" from
     within the Build directory.
  - Again use the build tool to invoke the `pack_mod' target. For example,
     if using `make', run "make pack_mod" from within the build directory.
     This will create an `irc-mod/irc' directory inside the build directory.
     This `irc' directory will be ready to be deployed to your Minetest mods
     directory. [Currently, there's a problem when compiling for GCC/MinGW32:
     the library will be named `libluasocket.dll', but the mod looks for
     `luasocket.dll'. There is a temporary fix to make the mod also search
     for `libluasocket.dll'.]

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

-- Enable debug output (boolean, default false)
mt_irc.debug = true;

LICENSE
-------
This license applies only to my code (in init.lua).

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

The `irc.lua' file and the entire content of the `irc' directory are part
 of the LuaIRC project (http://luairc.luaforge.org/). See
 `LICENSE-LuaIRC.txt' for licensing information.
