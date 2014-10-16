-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

local modpath = minetest.get_modpath(minetest.get_current_modname())

package.path =
		-- To find LuaIRC's init.lua
		modpath.."/?/init.lua;"
		-- For LuaIRC to find its files
		..modpath.."/?.lua;"
		..package.path

-- The build of Lua that Minetest comes with only looks for libraries under
-- /usr/local/share and /usr/local/lib but LuaSocket is often installed under
-- /usr/share and /usr/lib.
if not rawget(_G, "jit") and package.config:sub(1, 1) == "/" then
	package.path = package.path..
			";/usr/share/lua/5.1/?.lua"..
			";/usr/share/lua/5.1/?/init.lua"
	package.cpath = package.cpath..
			";/usr/lib/lua/5.1/?.so"
end

irc = {
	version = "0.2.0",
	connected = false,
	cur_time = 0,
	message_buffer = {},
	recent_message_count = 0,
	joined_players = {},
	modpath = modpath,
	lib = require("irc"),
}

-- Compatibility
mt_irc = irc

dofile(modpath.."/config.lua")
dofile(modpath.."/messages.lua")
dofile(modpath.."/hooks.lua")
dofile(modpath.."/callback.lua")
dofile(modpath.."/chatcmds.lua")
dofile(modpath.."/botcmds.lua")
if irc.config.enable_player_part then
	dofile(modpath.."/player_part.lua")
else
	setmetatable(irc.joined_players, {__index = function(index) return true end})
end

minetest.register_privilege("irc_admin", {
	description = "Allow IRC administrative tasks to be performed.",
	give_to_singleplayer = true
})

local stepnum = 0

minetest.register_globalstep(function(dtime) return irc:step(dtime) end)

function irc:step(dtime)
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


function irc:connect()
	if self.connected then
		minetest.log("error", "IRC: Ignoring attempt to connect when already connected.")
		return
	end
	self.conn = irc.lib.new({
		nick = self.config.nick,
		username = "Minetest",
		realname = "Minetest",
	})
	self:doHook(self.conn)
	local good, message = pcall(function()
		self.conn:connect({
			host = self.config.server,
			port = self.config.port,
			password = self.config.password,
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


function irc:disconnect(message)
	if self.connected then
		--The OnDisconnect hook will clear self.connected and print a disconnect message
		self.conn:disconnect(message)
	end
end


-- Split messages into smaller messages of this size to avoid cutting
-- off large messages at the end.
-- Note: RFC 2812 specifies a maximum of 512 characters per "line"
-- (that includes the command, parameter(s), and the "\r\n" at the
-- end). We just use a smaller number to avoid having to compute the
-- actual max length ourselves, and because it makes it a nice round
-- number :)
local MESSAGE_CHUNK_SIZE = 400

-- Maximum message size processed.
local MESSAGE_MAX_SIZE = MESSAGE_CHUNK_SIZE * 4

function irc:say(to, message)
	if not message then
		message = to
		to = self.config.channel
	end
	to = to or self.config.channel

	message = message:sub(1, MESSAGE_MAX_SIZE)

	-- Split the message into MESSAGE_CHUNK_SIZE chunks and queue each
	-- chunk as a separate message. The message is split into at most
	-- MAX_CHUNKS chunks. The rest of the message is dropped to prevent
	-- flooding and/or locking up the server.
	local msglen = #message
	for pos = 1, msglen, MESSAGE_CHUNK_SIZE do
		-- If we have more text to show, indicate so by appending an
		-- ellipsis to this line.
		local endl = (pos <= (msglen - MESSAGE_CHUNK_SIZE)) and "\2[…more…]\2" or ""
		self:queue(irc.msgs.privmsg(to,
				message:sub(pos, pos + MESSAGE_CHUNK_SIZE - 1)..endl))
	end
end


function irc:reply(message)
	if not self.last_from then
		return
	end
	message = message:gsub("[\r\n%z]", " \\n ")
	self:say(self.last_from, message)
end

function irc:send(msg)
	if not self.connected then return end
	self.conn:send(msg)
end

function irc:queue(msg)
	if not self.connected then return end
	self.conn:queue(msg)
end

