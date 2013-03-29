-- IRC Mod for Minetest
-- By Diego Martínez <kaeza@users.sf.net>
--
-- This mod allows to tie a Minetest server to an IRC channel.
--
-- This program is free software. It comes without any warranty, to
-- the extent permitted by applicable law. You can redistribute it
-- and/or modify it under the terms of the Do What The Fuck You Want
-- To Public License, Version 2, as published by Sam Hocevar. See
-- http://sam.zoy.org/wtfpl/COPYING for more details.
--

-- *************************
-- ** BASIC USER SETTINGS **
-- *************************

-- Server to connect on joinplayer (string, default "irc.freenode.net")
mt_irc.server = minetest.setting_get("mt_irc.server");

-- Port to connect on joinplayer (number, default 6667)
mt_irc.port = tonumber(minetest.setting_get("mt_irc.port"));

-- Channel to connect on joinplayer (string, default "##mt-irc-mod")
mt_irc.channel = minetest.setting_get("mt_irc.channel");

-- ***********************
-- ** ADVANCED SETTINGS **
-- ***********************

-- Time between chat updates in seconds (number, default 0.2).
mt_irc.dtime = tonumber(minetest.setting_get("mt_irc.dtime"));

-- Underlying socket timeout in seconds (number, default 1.0).
mt_irc.timeout = tonumber(minetest.setting_get("mt_irc.timeout"));

-- Nickname when using single conection (string, default "minetest-"..<server-id>);
--  (<server-id> is the server IP address packed as a 32 bit integer).
mt_irc.server_nick = minetest.setting_get("mt_irc.server_nick");

-- Password to use when using single connection (string, default "")
mt_irc.password = minetest.setting_get("mt_irc.password");

-- The format of messages sent to IRC server (string, default "<$(name)> $(message)")
-- See `README.txt' for the macros supported here.
mt_irc.message_format_out = minetest.setting_get("mt_irc.message_format_out") or "<$(name)> $(message)";

-- The format of messages sent to IRC server (string, default "<$(name)@IRC> $(message)")
-- See `README.txt' for the macros supported here.
mt_irc.message_format_in = minetest.setting_get("mt_irc.message_format_in") or "<$(name)@IRC> $(message)";

-- Enable debug output (boolean, default false)
mt_irc.debug = not minetest.setting_getbool("mt_irc.disable_debug");

-- Whether to automatically join the channed when player joins
--  (boolean, default true)
mt_irc.auto_join = not minetest.setting_getbool("mt_irc.disable_auto_join");

-- Whether to automatically connect to the server on mod load
--  (boolean, default true) 
mt_irc.auto_connect = not minetest.setting_getbool("mt_irc.disable_auto_connect");
