
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


INSTALLING
----------
Unpack the archive and put the `irc' directory in any of the directories
 where Minetest looks for mods. For more information, see:
    http://wiki.minetest.net/wiki/Installing_mods


SETTINGS
--------
All settings are changed directly in the script. If any of these settings
 are either nil or false, the default value is used.

    SERVER (string, default "irc.freenode.net")
        This is the IRC server the mod connects to.

    CHANNEL (string, default "#minetest-irc-testing")
        The IRC channel to join.

    DTIME (number, default 0.2)
        This is the time in seconds between updates in the connection.
        In order not to block the game, the mod must periodically "poll"
        the connection to both send messages to, and receive messages
        from the channel. A high value means slower connection to IRC,
        but possibly better response from the game. A low value means
        the mod "polls" the connection more often, but can make the
        game hang. It allows fractional values.


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
