
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
            name=name;
            message=msg;
        };
        local text = mt_irc.message_format_out:expandvars(t);
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
        mt_irc.connect();
        minetest.chat_send_player(name, "IRC: You are now connected.");
        irc.say(mt_irc.channel, name.." joined the channel.");
    end;
});

minetest.register_chatcommand("irc_disconnect", {
    params = "";
    description = "Disconnect from the IRC server";
    privs = { irc_admin=true; };
    func = function ( name, param )
        if (not mt_irc.connect_ok) then
            minetest.chat_send_player(name, "IRC: You are not connected.");
            return;
        end
        irc.quit("Manual BOT Disconnection");
        minetest.chat_send_player(name, "IRC: You are now disconnected.");
        mt_irc.connect_ok = false;
    end;
});

minetest.register_chatcommand("irc_reconnect", {
    params = "";
    description = "Reconnect to the IRC server";
    privs = { irc_admin=true; };
    func = function ( name, param )
        if (mt_irc.connect_ok) then
            irc.quit("Reconnecting BOT...");
            minetest.chat_send_player(name, "IRC: Reconnecting bot...");
            mt_irc.got_motd = true;
            mt_irc.connect_ok = false;
        end
        mt_irc.connect();
    end;
});

minetest.register_chatcommand("join", {
    params = "";
    description = "Join the IRC channel";
    privs = { shout=true; };
    func = function ( name, param )
        mt_irc.join(name);
    end;
});

minetest.register_chatcommand("part", {
    params = "";
    description = "Part the IRC channel";
    privs = { shout=true; };
    func = function ( name, param )
        mt_irc.part(name);
    end;
});

minetest.register_chatcommand("me", {
	params = "<action>";
	description = "chat action (eg. /me orders a pizza)";
	privs = { shout=true };
	func = function(name, param)
        minetest.chat_send_all("* "..name.." "..param);
        irc.say(mt_irc.channel, "* "..name.." "..param);
	end,
})

minetest.register_chatcommand("who", {
    -- TODO: This duplicates code from !who
    params = "";
    description = "Tell who is currently on the channel";
    privs = { shout=true; };
    func = function ( name, param )
        local s = "";
        for k, v in pairs(mt_irc.connected_players) do
            if (v) then
                s = s.." "..k;
            end
        end
        minetest.chat_send_player(name, "Players On Channel:"..s);
    end;
});
