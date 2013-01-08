
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

local irc = require("irc");

minetest.register_on_joinplayer(function ( player )

    mt_irc.say(mt_irc.channel, "*** "..player:get_player_name().." joined the game");
    mt_irc.connected_players[player:get_player_name()] = mt_irc.auto_join;

end);

irc.register_callback("connect", function ( )
    mt_irc.got_motd = true;
    irc.join(mt_irc.channel);
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

local function bot_command ( from, message )

    local pos = message:find(" ", 1, true);
    local cmd, args;
    if (pos) then
        cmd = message:sub(1, pos - 1);
        args = message:sub(pos + 1);
    else
        cmd = message;
        args = "";
    end

    if (not mt_irc.bot_commands[cmd]) then
        mt_irc.say(from, "Unknown command `"..cmd.."'. Try `!help'.");
        return;
    end

    mt_irc.bot_commands[cmd].func(from, args);

end

irc.register_callback("private_msg", function ( from, message )
    if (not mt_irc.connect_ok) then return; end
    local player_to;
    local msg;
    if (message:sub(1, 1) == ">") then
        local pos = message:find(" ", 1, true);
        if (not pos) then return; end
        player_to = message:sub(2, pos - 1);
        msg = message:sub(pos + 1);
    elseif (message:sub(1, 1) == "!") then
        bot_command(from, message:sub(2));
        return;
    else
        irc.say(from, 'Message not sent! Please use "!help" to see possible commands.');
        irc.say(from, '    Or use the ">playername Message" syntax to send a private message.');
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

irc.register_callback("kick", function ( chaninfo, to, from )
    minetest.chat_send_all("IRC: Bot was kicked by "..from..". Reconnecting bot in 5 seconds...");
    mt_irc.got_motd = false;
    mt_irc.connect_ok = false;
    irc.quit("Kicked");
    minetest.after(5, mt_irc.connect);
end);

irc.register_callback("nick_change", function ( from, old_nick )
    if (not mt_irc.connect_ok) then return; end
end);

minetest.register_on_leaveplayer(function ( player )
    local name = player:get_player_name();
    mt_irc.connected_players[name] = false;
    if (not mt_irc.connect_ok) then return; end
    irc.say(mt_irc.channel, "*** "..name.." left the game");
end);

minetest.register_on_chat_message(function ( name, message )
    if (not mt_irc.connect_ok) then return; end
    if (message:sub(1, 1) == "/") then return; end
    if (not mt_irc.connected_players[name]) then
        --minetest.chat_send_player(name, "IRC: You are not connected. Please use /join");
        return;
    end
    local privs = minetest.get_player_privs(name); 
    if (not privs.shout) then
        minetest.chat_send_player(name, "IRC: No shout priv");
        irc.say(mt_irc.channel, "DEBUG: message from unpriviledged player: "..name);
        return;
    end
    if (not mt_irc.buffered_messages) then
        mt_irc.buffered_messages = { };
    end
    mt_irc.buffered_messages[#mt_irc.buffered_messages + 1] = {
        name = name;
        message = message;
    };
end);

minetest.register_on_shutdown(function ( )
    irc.quit("Game shutting down.");
    for n = 1, 5 do
        irc.poll();
    end
end);

irc.handlers.on_error = function (from, respond_to)
    minetest.chat_send_all("IRC: Ping timeout. Reconnecting bot in 5 seconds...");
    mt_irc.got_motd = false;
    mt_irc.connect_ok = false;
    irc.quit("Ping timeout");
    minetest.after(5, mt_irc.connect);
end
