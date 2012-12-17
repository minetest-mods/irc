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
mt_irc.connected_players = { };

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
mt_irc.timeout = (mt_irc.timeout or 60.0);
mt_irc.message_format_out = (mt_irc.message_format_out or "<$(nick)> $(message)");
mt_irc.message_format_in = (mt_irc.message_format_in or "<$(name)@IRC[$(channel)]> $(message)");
if (mt_irc.connect_on_join == nil) then mt_irc.connect_on_join = false; end
if (mt_irc.connect_on_load == nil) then mt_irc.connect_on_load = false; end

minetest.register_privilege("irc_admin", {
    description = "Allow IRC administrative tasks to be performed.";
    give_to_singleplayer = true;
});

minetest.register_globalstep(function ( dtime )
    if (not mt_irc.connect_ok) then return; end
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
--Source of flooding in these lines
--However, bot will not connect to a channel but can PM across minetest and IRC to users ust fine.
-- if (#plys <= 0) then -- Just in case :)
--            irc.quit("Closing.");
--        end
    end
end);

minetest.register_on_joinplayer(function ( player )

    irc.register_callback("connect", function ( )
        irc.join(mt_irc.channel);
        irc.say(mt_irc.channel, "*** "..player:get_player_name().." joined the game");
    end);

    irc.register_callback("channel_msg", function ( channel, from, message )
        if (not mt_irc.connect_ok) then return; end
        local t = {
            name=(from or "<BUG:no one is saying this>");
            message=(message or "<BUG:there is no message>");
            server=mt_irc.server;
            port=mt_irc.port;
            channel=mt_irc.channel;
        };
        local text = mt_irc.message_format_in:gsub("%$%(([^)]+)%)", t)
        for k, v in pairs(mt_irc.connected_players) do
            if (v) then minetest.chat_send_player(k, text); end
        end
    end);
    
    irc.register_callback("private_msg", function ( from, message )
        if (not mt_irc.connect_ok) then return; end
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
        if (not mt_irc.connected_players[player_to]) then
            irc.say(from, "User `"..player_to.."' is not connected to IRC.");
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
        if (not mt_irc.connect_ok) then return; end
    end);

    mt_irc.connected_players[player:get_player_name()] = mt_irc.connect_on_join;

end);

minetest.register_on_leaveplayer(function ( player )
    if (not mt_irc.connect_ok) then return; end
    local name = player:get_player_name();
    mt_irc.connected_players[name] = false;
    irc.say(mt_irc.channel, "*** "..name.." left the game");
end);

minetest.register_on_chat_message(function ( name, message )
    if (not mt_irc.connected_players[name]) then
        minetest.chat_send_player(name, "IRC: You are not connected. Please use /join");
        return;
    end
    if (not mt_irc.connect_ok) then return; end
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
        if (not mt_irc.connect_ok) then
            minetest.chat_send_player(name, "IRC: You are not connected use /irc_connect.");
            return;
        end
        local pos = param:find(" ", 1, true);
        if (not pos) then return; end
        local name = param:sub(1, pos - 1);
        local msg = param:sub(pos + 1);
        local t = {
            name=nick;
            message=msg;
        };
        local text = mt_irc.message_format_out:gsub("%$%(([^)]+)%)", t)
        irc.send("PRIVMSG", name, text);
    end;
});

minetest.register_chatcommand("irc_connect", {
    params = "";
    description = "Connect to the IRC server";
    privs = { irc_admin=true; };
    func = function ( name, param )
        if (mt_irc.connect_ok) then
            minetest.chat_send_player(name, "IRC: You are already connected.");
            return;
        end
        mt_irc.connect_ok = pcall(irc.connect, {
            network = mt_irc.server;
            port = mt_irc.port;
            nick = mt_irc.server_nick;
            pass = mt_irc.password;
            timeout = mt_irc.timeout;
            channel = mt_irc.channel;
        });
        minetest.chat_send_player(name, "IRC: You are now connected.");
        irc.say(mt_irc.channel, name.." joined the channel.");
    end;
});

minetest.register_chatcommand("join", {
    params = "";
    description = "Join the IRC channel";
    privs = { shout=true; };
    func = function ( name, param )
        if (mt_irc.connected_players[name]) then
            minetest.chat_send_player(name, "IRC: You are already in the channel.");
            return;
        end
        mt_irc.connected_players[name] = true;
-- Best way I could get bot to autojoin channel was to add the irc.join function here.
-- Bot won't connect until the first user joins.  The bot will not disconect if last player leaves.
        irc.join(mt_irc.channel);
        minetest.chat_send_player(name, "IRC: You are now in the channel.");
    end;
});

minetest.register_chatcommand("part", {
    params = "";
    description = "Part the IRC channel";
    privs = { shout=true; };
    func = function ( name, param )
        if (not mt_irc.connected_players[name]) then
            minetest.chat_send_player(name, "IRC: You are not in the channel.");
            return;
        end
        mt_irc.connected_players[name] = false;
        minetest.chat_send_player(name, "IRC: You are now out of the channel.");
        irc.say(mt_irc.channel, name.." is no longer in the channel.");
    end;
});

if (mt_irc.connect_on_load) then
    mt_irc.connect_ok = pcall(irc.connect, {
        network = mt_irc.server;
        port = mt_irc.port;
        nick = mt_irc.server_nick;
        pass = mt_irc.password;
        timeout = mt_irc.timeout;
        channel = mt_irc.channel;
    });
end
