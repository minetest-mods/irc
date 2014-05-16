-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

local modpath = minetest.get_modpath(minetest.get_current_modname())

package.path =
		package.path..";"
		-- To find LuaIRC's init.lua
		..modpath.."/?/init.lua;"
		-- For LuaIRC to find its files
		..modpath.."/?.lua"

mt_irc = {
	version = "0.2.0",
	connected = false,
	cur_time = 0,
	message_buffer = {},
	recent_message_count = 0,
	joined_players = {},
	modpath = modpath,
	lib = require("irc"),
}
local irc = mt_irc.lib

dofile(modpath.."/config.lua")
dofile(modpath.."/messages.lua")
dofile(modpath.."/hooks.lua")
dofile(modpath.."/callback.lua")
dofile(modpath.."/chatcmds.lua")
dofile(modpath.."/botcmds.lua")
dofile(modpath.."/util.lua")
if mt_irc.config.enable_player_part then
	dofile(modpath.."/player_part.lua")
else
	setmetatable(mt_irc.joined_players, {__index = function(index) return true end})
end

minetest.register_privilege("irc_admin", {
	description = "Allow IRC administrative tasks to be performed.",
	give_to_singleplayer = true
})

local stepnum = 0

minetest.register_globalstep(function(dtime) return mt_irc:step(dtime) end)

function mt_irc:step(dtime)
	if stepnum == 3 then
		if self.config.auto_connect then
			self:connect()
		end
	end
	stepnum = stepnum + 1

	if not self.connected then return end

	-- Hooks will manage incoming messages and errors
	local good, err = xpcall(function() self.conn:think() end, debug.traceback)
	if not good then
		print(err)
		return
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

	self:queue(irc.msgs.privmsg(to, message))
end


function mt_irc:reply(message)
	if not self.last_from then
		return
	end
	self:say(self.last_from, message)
end

function mt_irc:send(msg)
	self.conn:send(msg)
end

function mt_irc:queue(msg)
	self.conn:queue(msg)
end

