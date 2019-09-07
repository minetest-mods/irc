-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

local ie = ...

-- MIME is part of LuaSocket
local b64e = ie.require("mime").b64

irc.hooks = {}
irc.registered_hooks = {}


local stripped_chars = "[\2\31]"

local function normalize(text)
	-- Strip colors
	text = text:gsub("\3[0-9][0-9,]*", "")

	return text:gsub(stripped_chars, "")
end


function irc.doHook(conn)
	for name, hook in pairs(irc.registered_hooks) do
		for _, func in pairs(hook) do
			conn:hook(name, func)
		end
	end
end


function irc.register_hook(name, func)
	irc.registered_hooks[name] = irc.registered_hooks[name] or {}
	table.insert(irc.registered_hooks[name], func)
end


function irc.hooks.raw(line)
	if irc.config.debug then
		print("RECV: "..line)
	end
end


function irc.hooks.send(line)
	if irc.config.debug then
		print("SEND: "..line)
	end
end


function irc.hooks.chat(msg)
	local channel, text = msg.args[1], msg.args[2]
	if text:sub(1, 1) == string.char(1) then
		irc.conn:invoke("OnCTCP", msg)
		return
	end

	if channel == irc.conn.nick then
		irc.last_from = msg.user.nick
		irc.conn:invoke("PrivateMessage", msg)
	else
		irc.last_from = channel
		irc.conn:invoke("OnChannelChat", msg)
	end
end


local function get_core_version()
	local status = minetest.get_server_status()
	local start_pos = select(2, status:find("version=", 1, true))
	local end_pos = status:find(",", start_pos, true)
	return status:sub(start_pos + 1, end_pos - 1)
end


function irc.hooks.ctcp(msg)
	local text = msg.args[2]:sub(2, -2)  -- Remove ^C
	local args = text:split(' ')
	local command = args[1]:upper()

	local function reply(s)
		irc.queue(irc.msgs.notice(msg.user.nick,
				("\1%s %s\1"):format(command, s)))
	end

	if command == "ACTION" and msg.args[1] == irc.config.channel then
		local action = text:sub(8, -1)
		irc.sendLocal(("* %s@IRC %s"):format(msg.user.nick, action))
	elseif command == "VERSION" then
		reply(("Minetest version %s, IRC mod version %s.")
			:format(get_core_version(), irc.version))
	elseif command == "PING" then
		reply(args[2])
	elseif command == "TIME" then
		reply(os.date())
	end
end


function irc.hooks.channelChat(msg)
	local text = normalize(msg.args[2])

	irc.check_botcmd(msg)

	-- Don't let a user impersonate someone else by using the nick "IRC"
	local fake = msg.user.nick:lower():match("^[il|]rc$")
	if fake then
		irc.sendLocal("<"..msg.user.nick.."@IRC> "..text)
		return
	end

	-- Support multiple servers in a channel better by converting:
	-- "<server@IRC> <player> message" into "<player@server> message"
	-- "<server@IRC> *** player joined/left the game" into "*** player joined/left server"
	-- and "<server@IRC> * player orders a pizza" into "* player@server orders a pizza"
	local foundchat, _, chatnick, chatmessage =
		text:find("^<([^>]+)> (.*)$")
	local foundjoin, _, joinnick =
		text:find("^%*%*%* ([^%s]+) joined the game$")
	local foundleave, _, leavenick =
		text:find("^%*%*%* ([^%s]+) left the game$")
	local foundtimedout, _, timedoutnick =
		text:find("^%*%*%* ([^%s]+) left the game %(Timed out%)$")
	local foundaction, _, actionnick, actionmessage =
		text:find("^%* ([^%s]+) (.*)$")

	if text:sub(1, 5) == "[off]" then
		return
	elseif foundchat then
		irc.sendLocal(("<%s@%s> %s")
				:format(chatnick, msg.user.nick, chatmessage))
	elseif foundjoin then
		irc.sendLocal(("*** %s joined %s")
				:format(joinnick, msg.user.nick))
	elseif foundleave then
		irc.sendLocal(("*** %s left %s")
				:format(leavenick, msg.user.nick))
	elseif foundtimedout then
		irc.sendLocal(("*** %s left %s (Timed out)")
				:format(timedoutnick, msg.user.nick))
	elseif foundaction then
		irc.sendLocal(("* %s@%s %s")
				:format(actionnick, msg.user.nick, actionmessage))
	else
		irc.sendLocal(("<%s@IRC> %s"):format(msg.user.nick, text))
	end
end


function irc.hooks.pm(msg)
	-- Trim prefix if it is found
	local text = msg.args[2]
	local prefix = irc.config.command_prefix
	if prefix and text:sub(1, #prefix) == prefix then
		text = text:sub(#prefix + 1)
	end
	irc.bot_command(msg, text)
end


function irc.hooks.kick(channel, target, prefix, reason)
	if target == irc.conn.nick then
		minetest.chat_send_all("IRC: kicked from "..channel.." by "..prefix.nick..".")
		irc.disconnect("Kicked")
	else
		irc.sendLocal(("-!- %s was kicked from %s by %s [%s]")
				:format(target, channel, prefix.nick, reason))
	end
end


function irc.hooks.notice(user, target, message)
	if user.nick and target == irc.config.channel then
		irc.sendLocal("-"..user.nick.."@IRC- "..message)
	end
end


function irc.hooks.mode(user, target, modes, ...)
	local by = ""
	if user.nick then
		by = " by "..user.nick
	end
	local options = ""
	if select("#", ...) > 0 then
		options = " "
	end
	options = options .. table.concat({...}, " ")
	minetest.chat_send_all(("-!- mode/%s [%s%s]%s")
			:format(target, modes, options, by))
end


function irc.hooks.nick(user, newNick)
	irc.sendLocal(("-!- %s is now known as %s")
			:format(user.nick, newNick))
end


function irc.hooks.join(user, channel)
	irc.sendLocal(("-!- %s joined %s")
			:format(user.nick, channel))
end


function irc.hooks.part(user, channel, reason)
	reason = reason or ""
	irc.sendLocal(("-!- %s has left %s [%s]")
			:format(user.nick, channel, reason))
end


function irc.hooks.quit(user, reason)
	irc.sendLocal(("-!- %s has quit [%s]")
			:format(user.nick, reason))
end


function irc.hooks.disconnect(_, isError)
	irc.connected = false
	if isError then
		minetest.log("error",  "IRC: Error: Disconnected, reconnecting in one minute.")
		minetest.chat_send_all("IRC: Error: Disconnected, reconnecting in one minute.")
		minetest.after(60, irc.connect, irc)
	else
		minetest.log("action", "IRC: Disconnected.")
		minetest.chat_send_all("IRC: Disconnected.")
	end
end


function irc.hooks.preregister(conn)
	if not (irc.config["sasl.user"] and irc.config["sasl.pass"]) then return end
	local authString = b64e(
		("%s\x00%s\x00%s"):format(
		irc.config["sasl.user"],
		irc.config["sasl.user"],
		irc.config["sasl.pass"])
	)
	conn:send("CAP REQ sasl")
	conn:send("AUTHENTICATE PLAIN")
	conn:send("AUTHENTICATE "..authString)
	conn:send("CAP END")
end


irc.register_hook("PreRegister",     irc.hooks.preregister)
irc.register_hook("OnRaw",           irc.hooks.raw)
irc.register_hook("OnSend",          irc.hooks.send)
irc.register_hook("DoPrivmsg",       irc.hooks.chat)
irc.register_hook("OnPart",          irc.hooks.part)
irc.register_hook("OnKick",          irc.hooks.kick)
irc.register_hook("OnJoin",          irc.hooks.join)
irc.register_hook("OnQuit",          irc.hooks.quit)
irc.register_hook("NickChange",      irc.hooks.nick)
irc.register_hook("OnCTCP",          irc.hooks.ctcp)
irc.register_hook("PrivateMessage",  irc.hooks.pm)
irc.register_hook("OnNotice",        irc.hooks.notice)
irc.register_hook("OnChannelChat",   irc.hooks.channelChat)
irc.register_hook("OnModeChange",    irc.hooks.mode)
irc.register_hook("OnDisconnect",    irc.hooks.disconnect)

