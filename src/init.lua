-- IRC Mod for Minetest
-- (C) 2012 Diego Martínez <kaeza@users.sf.net>
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
-- ** BEGIN USER SETTINGS **
-- *************************

-- Server to connect on joinplayer (string, default "irc.freenode.net")
local SERVER = "irc.freenode.net";

-- Channel to connect on joinplayer (string, default "#minetest-irc-testing")
local CHANNEL = "#minetest-irc-testing";

-- Time between chat updates in seconds (number, default 0.2).
local DTIME = 0.5;

-- Enable debug output (boolean, default false)
local DEBUG = true;

local SERVER_NICK = "mt_game";

-- ***********************
-- ** END USER SETTINGS **
-- ***********************

-- **********************************************************************
-- ** DO NOT EDIT ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING!!! **
-- **********************************************************************


local MODPATH = minetest.get_modpath("irc");

package.path = MODPATH.."/?.lua;"..package.path;
package.cpath = MODPATH.."/lib?.so;"..MODPATH.."/?.dll;"..package.cpath;

local irc = require 'irc';

irc.DEBUG = ((DEBUG and true) or false);

-- This could be made local.
mt_irc = {
    cur_time = 0;
    buffered_messages = { };
};

SERVER = (SERVER or "irc.freenode.net");
CHANNEL = (CHANNEL or "#minetest-irc-testing");
DTIME = (DTIME or 0.2);

minetest.register_globalstep(function ( dtime )
    mt_irc.cur_time = mt_irc.cur_time + dtime;
    if (mt_irc.cur_time >= DTIME) then
        if (mt_irc.buffered_messages) then
            for _, t in ipairs(mt_irc.buffered_messages) do
                irc.say(CHANNEL, "[GAME:"..t.name.."]: "..(t.message or ""));
            end
            mt_irc.buffered_messages = nil;
        end
        irc.poll();
        mt_irc.cur_time = mt_irc.cur_time - DTIME;
        local plys = minetest.get_connected_players();
        if (#plys <= 0) then -- Just in case :)
            irc.quit("Closing.");
        end
    end
end);

minetest.register_on_joinplayer(function ( player )

    minetest.chat_send_all("PLAYER JOINED: "..player:get_player_name());

    irc.register_callback("connect", function ( )
        irc.join(CHANNEL);
    end);
    
    irc.register_callback("channel_msg", function ( channel, from, message )
        minetest.chat_send_all(from.."[IRC:"..channel.."]: "..message);
    end);

    irc.register_callback("private_msg", function ( from, message )
    end);

    irc.register_callback("action", function ( from, message )
    end);

    irc.register_callback("nick_change", function ( from, old_nick )
    end);

end);

minetest.register_on_leaveplayer(function ( player )
    irc.say(CHANNEL, "*** "..player:get_player_name().." left the game");
end);

minetest.register_on_chat_message(function ( name, message )
    print("***DEBUG: CHAT: "..name.."|"..message);
    if (not mt_irc.buffered_messages) then
        mt_irc.buffered_messages = { };
    end
    mt_irc.buffered_messages[#mt_irc.buffered_messages + 1] = {
        name = name;
        message = message;
    };
end);

minetest.register_chatcommand("me", {
	params = "<action>";
	description = "chat action (eg. /me orders a pizza)";
	privs = {shout=true};
	func = function(name, param)
		minetest.chat_send_all("* "..name.." "..param);
		irc.say(CHANNEL, "* "..name.." "..param);
	end;
})

irc.connect({
    network = SERVER;
    nick = SERVER_NICK;
    pass = "";
    timeout = 1.0;
});
