-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

local modpath = minetest.get_modpath(minetest.get_current_modname())

-- Handle mod security if needed
local ie, req_ie = _G, minetest.request_insecure_environment
if req_ie then ie = req_ie() end
if not ie then
	error("The IRC mod requires access to insecure functions in order "..
		"to work.  Please add the irc mod to your secure.trusted_mods "..
		"setting or disable the irc mod.")
end

ie.package.path =
		-- To find LuaIRC's init.lua
		modpath.."/?/init.lua;"
		-- For LuaIRC to find its files
		..modpath.."/?.lua;"
		..ie.package.path

-- The build of Lua that Minetest comes with only looks for libraries under
-- /usr/local/share and /usr/local/lib but LuaSocket is often installed under
-- /usr/share and /usr/lib.
if not rawget(_G, "jit") and package.config:sub(1, 1) == "/" then

	ie.package.path = ie.package.path..
			";/usr/share/lua/5.1/?.lua"..
			";/usr/share/lua/5.1/?/init.lua"

	ie.package.cpath = ie.package.cpath..
			";/usr/lib/lua/5.1/?.so"..
			";/usr/lib64/lua/5.1/?.so"

	ie.package.cpath = "/usr/lib/x86_64-linux-gnu/lua/5.1/?.so;"..ie.package.cpath


end

-- Temporarily set require so that LuaIRC can access it
local old_require = require
require = ie.require

-- Silence warnings about `module` in `ltn12`.
local old_module = rawget(_G, "module")
rawset(_G, "module", ie.module)

local lib = ie.require("irc")

irc = {
	version = "0.2.0",
	connected = false,
	cur_time = 0,
	message_buffer = {},
	recent_message_count = 0,
	joined_players = {},
	modpath = modpath,
	lib = lib,
}

-- Compatibility
rawset(_G, "mt_irc", irc)

local getinfo = debug.getinfo
local warned = { }

local function warn_deprecated(k)
	local info = getinfo(3)
	local loc = info.source..":"..info.currentline
	if warned[loc] then return end
	warned[loc] = true
	print("COLON: "..tostring(k))
	minetest.log("warning", "Deprecated use of colon notation when calling"
			.." method `"..tostring(k).."` at "..loc)
end

-- This is a hack.
setmetatable(irc, {
	__newindex = function(t, k, v)
		if type(v) == "function" then
			local f = v
			v = function(me, ...)
				if rawequal(me, t) then
					warn_deprecated(k)
					return f(...)
				else
					return f(me, ...)
				end
			end
		end
		rawset(t, k, v)
	end,
})

dofile(modpath.."/config.lua")
dofile(modpath.."/messages.lua")
loadfile(modpath.."/hooks.lua")(ie)
dofile(modpath.."/callback.lua")
dofile(modpath.."/chatcmds.lua")
dofile(modpath.."/botcmds.lua")

-- Restore old (safe) functions
require = old_require
rawset(_G, "module", old_module)

if irc.config.enable_player_part then
	dofile(modpath.."/player_part.lua")
else
	setmetatable(irc.joined_players, {__index = function() return true end})
end

minetest.register_privilege("irc_admin", {
	description = "Allow IRC administrative tasks to be performed.",
	give_to_singleplayer = true,
	give_to_admin = true,
})

local stepnum = 0

minetest.register_globalstep(function(dtime) return irc.step(dtime) end)

function irc.step()
	if stepnum == 3 then
		if irc.config.auto_connect then
			irc.connect()
		end
	end
	stepnum = stepnum + 1

	if not irc.connected then return end

	-- Hooks will manage incoming messages and errors
	local good, err = xpcall(function() irc.conn:think() end, debug.traceback)
	if not good then
		print(err)
		return
	end
end


function irc.connect()
	if irc.connected then
		minetest.log("error", "IRC: Ignoring attempt to connect when already connected.")
		return
	end
	irc.conn = irc.lib.new({
		nick = irc.config.nick,
		username = irc.config.username,
		realname = irc.config.realname,
	})
	irc.doHook(irc.conn)

	-- We need to swap the `require` function again since
	-- LuaIRC `require`s `ssl` if `irc.secure` is true.
	old_require = require
	require = ie.require

	local good, message = pcall(function()
		irc.conn:connect({
			host = irc.config.server,
			port = irc.config.port,
			password = irc.config.password,
			timeout = irc.config.timeout,
			reconnect = irc.config.reconnect,
			secure = irc.config.secure
		})
	end)

	require = old_require

	if not good then
		minetest.log("error", ("IRC: Connection error: %s: %s -- Reconnecting in %d seconds...")
					:format(irc.config.server, message, irc.config.reconnect))
		minetest.after(irc.config.reconnect, function() irc.connect() end)
		return
	end

	if irc.config.NSPass then
		irc.conn:queue(irc.msgs.privmsg(
				"NickServ", "IDENTIFY "..irc.config.NSPass))
	end

	irc.conn:join(irc.config.channel, irc.config.key)
	irc.connected = true
	minetest.log("action", "IRC: Connected!")
	minetest.chat_send_all("IRC: Connected!")
end


function irc.disconnect(message)
	if irc.connected then
		--The OnDisconnect hook will clear irc.connected and print a disconnect message
		irc.conn:disconnect(message)
	end
end


function irc.say(to, message)
	if not message then
		message = to
		to = irc.config.channel
	end
	to = to or irc.config.channel

	irc.queue(irc.msgs.privmsg(to, message))
end


function irc.reply(message)
	if not irc.last_from then
		return
	end
	message = message:gsub("[\r\n%z]", " \\n ")
	irc.say(irc.last_from, message)
end

function irc.send(msg)
	if not irc.connected then return end
	irc.conn:send(msg)
end

function irc.queue(msg)
	if not irc.connected then return end
	irc.conn:queue(msg)
end

