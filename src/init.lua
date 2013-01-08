
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

local MODPATH = minetest.get_modpath("irc");

mt_irc = { };

dofile(MODPATH.."/config.lua");

mt_irc.cur_time = 0;
mt_irc.buffered_messages = { };
mt_irc.connected_players = { };
mt_irc.modpath = MODPATH;

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
mt_irc.channel = (mt_irc.channel or "##mt-irc-mod");
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

mt_irc.part = function ( name )
    if (not mt_irc.connected_players[name]) then
        minetest.chat_send_player(name, "IRC: You are not in the channel.");
        return;
    end
    mt_irc.connected_players[name] = false;
    minetest.chat_send_player(name, "IRC: You are now out of the channel.");
    --irc.send(mt_irc.channel, name.." is no longer in the channel.");
    irc.send(name.." is no longer in the channel.");
end

mt_irc.join = function ( name )
    local function do_join ( name )
        if (mt_irc.connected_players[name]) then
            minetest.chat_send_player(name, "IRC: You are already in the channel.");
            return;
        end
        mt_irc.connected_players[name] = true;
        mt_irc.join(mt_irc.channel);
        minetest.chat_send_player(name, "IRC: You are now in the channel.");
    end
    if (not pcall(do_join, name)) then
        mt_irc.connected_players[name] = false;
    end
end

mt_irc.connect = function ( )
    mt_irc.connect_ok = irc.connect({
        network = mt_irc.server;
        port = mt_irc.port;
        nick = mt_irc.server_nick;
        pass = mt_irc.password;
        timeout = mt_irc.timeout;
        channel = mt_irc.channel;
    });
    if (not mt_irc.connect_ok) then
        local s = "DEBUG: irc.connect failed";
        minetest.debug(s);
        minetest.chat_send_all(s);
        return;
    end
    while (not mt_irc.got_motd) do
        irc.poll();
    end

    minetest.register_globalstep(function ( dtime )
        if (not mt_irc.connect_ok) then return; end
        if (not mt_irc.players_connected) then
            for _,player in ipairs(minetest.get_connected_players()) do
                mt_irc.connected_players[player:get_player_name()] = mt_irc.auto_join;
            end
        end
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
            --local plys = minetest.get_connected_players();
            --if ((#plys <= 0) and (minetest.is_singleplayer())) then
            --    minetest.after(1.0, function ( )
            --        irc.quit("Closing.");
            --    end)
            --end
        end
    end);
end

mt_irc.say = function ( to, msg )
    if (not msg) then
        msg = to;
        to = mt_irc.channel;
    end
    to = to or mt_irc.channel;
    msg = msg or "";
    irc.say(to, msg);
end

mt_irc.irc = irc;

dofile(MODPATH.."/callback.lua");
dofile(MODPATH.."/chatcmds.lua");
dofile(MODPATH.."/botcmds.lua");
dofile(MODPATH.."/friends.lua");

if (mt_irc.auto_connect) then
    mt_irc.connect()
end
