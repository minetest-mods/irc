-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


mt_irc = {
	version = "0.2.0",  -- Also update CMakeLists.txt
	connected = false,
	cur_time = 0,
	message_buffer = {},
	recent_message_count = 0,
	joined_players = {},
	modpath = minetest.get_modpath(minetest.get_current_modname()),
}

-- To find LuaIRC and LuaSocket
package.path = mt_irc.modpath.."/?/init.lua;"
		..mt_irc.modpath.."/irc/?.lua;"
		..mt_irc.modpath.."/?.lua;"
		..package.path
package.cpath = mt_irc.modpath.."/lib?.so;"
		..mt_irc.modpath.."/?.dll;"
		..package.cpath

local irc = require('irc')

dofile(mt_irc.modpath.."/config.lua")
dofile(mt_irc.modpath.."/messages.lua")
dofile(mt_irc.modpath.."/hooks.lua")
dofile(mt_irc.modpath.."/callback.lua")
dofile(mt_irc.modpath.."/chatcmds.lua")
dofile(mt_irc.modpath.."/botcmds.lua")
dofile(mt_irc.modpath.."/util.lua")
if mt_irc.config.enable_player_part then
	dofile(mt_irc.modpath.."/player_part.lua")
else
	setmetatable(mt_irc.joined_players, {__index = function(index) return true end})
end

minetest.register_privilege("irc_admin", {
	description = "Allow IRC administrative tasks to be performed.",
	give_to_singleplayer = true
})


minetest.register_globalstep(function(dtime) return mt_irc:step(dtime) end)

function mt_irc:step(dtime)
	if not self.connected then return end

	-- Tick down the recent message count
	self.cur_time = self.cur_time + dtime
	if self.cur_time >= self.config.interval then
		if self.recent_message_count > 0 then
			self.recent_message_count = self.recent_message_count - 1
		end
		self.cur_time = self.cur_time - self.config.interval
	end

	-- Hooks will manage incoming messages and errors
	if not pcall(function() self.conn:think() end) then
		return
	end

	-- Send messages in the buffer
	if #self.message_buffer > 10 then
		minetest.log("error", "IRC: Message buffer overflow, clearing.")
		self.message_buffer = {}
	elseif #self.message_buffer > 0 then
		for i=1, #self.message_buffer do
			if self.recent_message_count > 4 then break end
			self.recent_message_count = self.recent_message_count + 1
			local msg = table.remove(self.message_buffer, 1) --Pop the first message
			self:send(msg)
		end
	end
end


function mt_irc:connect()
	if self.connected then
		minetest.log("error", "IRC: Ignoring attempt to connect when already connected.")
		return
	end
	self.conn = irc.new({
		nick = self.config.nick,
		username = "Minetest",
		realname = "Minetest",
	})
	self:doHook(self.conn)
	good, message = pcall(function()
		self.conn:connect({
			host = self.config.server,
			port = self.config.port,
			pass = self.config.password,
			timeout = self.config.timeout,
			secure = self.config.secure
		})
	end)

	if not good then
		minetest.log("error", ("IRC: Connection error: %s: %s -- Reconnecting in ten minutes...")
					:format(self.config.server, message))
		minetest.after(600, function() self:connect() end)
		return
	end

	if self.config.NSPass then
		self:say("NickServ", "IDENTIFY "..self.config.NSPass)
	end

	self.conn:join(self.config.channel, self.config.key)
	self.connected = true
	minetest.log("action", "IRC: Connected!")
	minetest.chat_send_all("IRC: Connected!")
end


function mt_irc:disconnect(message)
	if self.connected then
		--The OnDisconnect hook will clear self.connected and print a disconnect message
		self.conn:disconnect(message)
	end
end


function mt_irc:say(to, message)
	if not message then
		message = to
		to = self.config.channel
	end
	to = to or self.config.channel

	self:queueMsg(self.msgs.privmsg(to, message))
end


function mt_irc:reply(message)
	if not self.last_from then
		return
	end
	self:say(self.last_from, message)
end

function mt_irc:send(line)
	self.conn:send(line)
end


if mt_irc.config.auto_connect then
	mt_irc:connect()
end

