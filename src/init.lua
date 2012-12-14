
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

local MODPATH = minetest.get_modpath("irc");

mt_irc = { };

dofile(MODPATH.."/config.lua");

mt_irc.cur_time = 0;
mt_irc.buffered_messages = { };

package.path = MODPATH.."/?.lua;"..package.path;
package.cpath = MODPATH.."/lib?.so;"..MODPATH.."/?.dll;"..package.cpath;

local irc = require 'irc';

irc.DEBUG = ((mt_irc.debug and true) or false);

-- Set defaults if not specified.
if (not mt_irc.server_nick) then
    local pr = PseudoRandom(os.time());
    -- Workaround for bad distribution in minetest PRNG implementation.
    local fmt = "minetest-%02X%02X%02X%02X";
    mt_irc.server_nick = fmt:format(
        pr:next(0, 255),
        pr:next(0, 255),
        pr:next(0, 255),
        pr:next(0, 255)
    );
end
mt_irc.server = (mt_irc.server or "irc.freenode.net");
mt_irc.port = (mt_irc.port or 6667);
mt_irc.channel = (mt_irc.channel or "#minetest-irc-testing");
mt_irc.dtime = (mt_irc.dtime or 0.2);
mt_irc.message_format_out = (mt_irc.message_format_out or "<$(nick)> $(message)");
mt_irc.message_format_in = (mt_irc.message_format_in or "<$(name)@IRC[$(channel)]> $(message)");

minetest.register_globalstep(function ( dtime )
    mt_irc.cur_time = mt_irc.cur_time + dtime;
    if (mt_irc.cur_time >= mt_irc.dtime) then
        if (mt_irc.buffered_messages) then
            for _, msg in ipairs(mt_irc.buffered_messages) do
                local t = {
                    name=(msg.name or "<BUG:no one is saying this>");
                    message=(msg.message or "<BUG:there is no message>");
                };
                local text = mt_irc.message_format_out:gsub("%$%(([^)]+)%)", t)
                irc.say(mt_irc.channel, text);
            end
            mt_irc.buffered_messages = nil;
        end
        irc.poll();
        mt_irc.cur_time = mt_irc.cur_time - mt_irc.dtime;
        local plys = minetest.get_connected_players();
        if (#plys <= 0) then -- Just in case :)
            irc.quit("Closing.");
        end
    end
end);

local function strltrim ( s )
    return s:gsub("^[[:space:]]*", "");
end

minetest.register_on_joinplayer(function ( player )

    if (not mt_irc.connect_ok) then 
        minetest.chat_send_player(player:get_player_name(), "IRC: Failed to connect to server.");
        return;
    end

    irc.register_callback("connect", function ( )
        irc.join(mt_irc.channel);
        irc.say(mt_irc.channel, "*** "..player:get_player_name().." joined the game");
    end);
    
    irc.register_callback("channel_msg", function ( channel, from, message )
        local t = {
            name=(from or "<BUG:no one is saying this>");
            message=(message or "<BUG:there is no message>");
            server=mt_irc.server;
            port=mt_irc.port;
            channel=mt_irc.channel;
        };
        local text = mt_irc.message_format_in:gsub("%$%(([^)]+)%)", t)
        minetest.chat_send_all(text);
    end);
    
    irc.register_callback("private_msg", function ( from, message )
        local player_to;
        local msg;
        if (message:sub(1, 1) == ">") then
            local pos = message:find(" ", 1, true);
            if (not pos) then return; end
            player_to = message:sub(2, pos - 1);
            msg = message:sub(pos + 1);
        else
            irc.say(from, 'Please use the ">username message" syntax.');
            return;
        end
        local t = {
            name=(from or "<BUG:no one is saying this>");
            message=(msg or "<BUG:there is no message>");
            server=mt_irc.server;
            port=mt_irc.port;
            channel=mt_irc.channel;
        };
        local text = mt_irc.message_format_in:gsub("%$%(([^)]+)%)", t)
        minetest.chat_send_player(player_to, "PRIVATE: "..text);
    end);
    
    irc.register_callback("nick_change", function ( from, old_nick )
    end);

end);

minetest.register_on_leaveplayer(function ( player )
    irc.say(mt_irc.channel, "*** "..player:get_player_name().." left the game");
end);

minetest.register_on_chat_message(function ( name, message )
    if (not mt_irc.buffered_messages) then
        mt_irc.buffered_messages = { };
    end
    mt_irc.buffered_messages[#mt_irc.buffered_messages + 1] = {
        name = name;
        message = message;
    };
end);

minetest.register_chatcommand("msg", {
    params = "<name> <message>";
    description = "Send a private message to an IRC user";
    privs = { shout=true; };
    func = function ( name, param )
        local pos = param:find(" ", 1, true);
        if (not pos) then return; end
        local nick = param:sub(1, pos - 1);
        local msg = param:sub(pos + 1);
        local t = {
            name=nick;
            message=msg;
        };
        local text = mt_irc.message_format_out:gsub("%$%(([^)]+)%)", t)
        irc.send("PRIVMSG", nick, text);
    end;
});

mt_irc.connect_ok = pcall(irc.connect, {
    network = mt_irc.server;
    port = mt_irc.port;
    nick = mt_irc.server_nick;
    pass = mt_irc.password;
    timeout = mt_irc.timeout;
});
