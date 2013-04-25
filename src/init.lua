
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

minetest.register_privilege("irc_admin", {
	description = "Allow IRC administrative tasks to be performed.";
	give_to_singleplayer = true;
});

minetest.register_globalstep(function(dtime)
	if (not mt_irc.connect_ok) then return end
	mt_irc.cur_time = mt_irc.cur_time + dtime
	if (mt_irc.cur_time >= mt_irc.dtime) then
		if (mt_irc.buffered_messages) then
			for _, msg in ipairs(mt_irc.buffered_messages) do
				local t = {
					name=(msg.name or "<BUG:no one is saying this>"),
					message=(msg.message or "<BUG:there is no message>")
				}
				local text = mt_irc.message_format_out:expandvars(t)
				irc.say(mt_irc.channel, text)
			end
			mt_irc.buffered_messages = nil
		end
		irc.poll()
		mt_irc.cur_time = mt_irc.cur_time - mt_irc.dtime
	end
end)

mt_irc.part = function ( name )
	if (not mt_irc.connected_players[name]) then
		minetest.chat_send_player(name, "IRC: You are not in the channel.");
		return;
	end
	mt_irc.connected_players[name] = nil;
	minetest.chat_send_player(name, "IRC: You are now out of the channel.");
end

mt_irc.join = function ( name )
	if (mt_irc.connected_players[name]) then
		minetest.chat_send_player(name, "IRC: You are already in the channel.");
		return;
	end
	mt_irc.connected_players[name] = true;
	minetest.chat_send_player(name, "IRC: You are now in the channel.");
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
end

mt_irc.say = function ( to, msg )
	if (not msg) then
		msg = to;
		to = mt_irc.channel;
	end
	to = to or mt_irc.channel;
	msg = msg or "";
	local msg2 = mt_irc._callback("msg_out", true, to, msg);
	if ((type(msg2) == "boolean") and (not msg2)) then
		return;
	elseif (msg2 ~= nil) then
		msg = tostring(msg);
	end
	irc.say(to, msg);
end

mt_irc.irc = irc;

-- Misc helpers

-- Requested by Exio
string.expandvars = function ( s, vars )
	return s:gsub("%$%(([^)]+)%)", vars);
end

dofile(MODPATH.."/callback.lua");
dofile(MODPATH.."/chatcmds.lua");
dofile(MODPATH.."/botcmds.lua");
dofile(MODPATH.."/friends.lua");

if (mt_irc.auto_connect) then
	mt_irc.connect()
end
