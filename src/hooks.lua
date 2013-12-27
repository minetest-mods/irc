-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


mt_irc.hooks = {}
mt_irc.registered_hooks = {}


-- TODO: Add proper conversion from CP1252 to UTF-8.
local stripped_chars = { }
for c = 127, 255 do
	table.insert(stripped_chars, string.char(c))
end
stripped_chars = "["..table.concat(stripped_chars, "").."]"

local function normalize(text)
	return text:gsub(stripped_chars, "")
end


function mt_irc:doHook(conn)
	for name, hook in pairs(self.registered_hooks) do
		for _, func in pairs(hook) do
			conn:hook(name, func)
		end
	end
end


function mt_irc:register_hook(name, func)
	self.registered_hooks[name] = self.registered_hooks[name] or {}
	table.insert(self.registered_hooks[name], func)
end


function mt_irc.hooks.raw(line)
	if mt_irc.config.debug then
		print("RECV: "..line)
	end
end


function mt_irc.hooks.send(line)
	if mt_irc.config.debug then
		print("SEND: "..line)
	end
end


function mt_irc.hooks.chat(user, channel, message)

	message = normalize(message)

	-- Strip bold, underline, and colors
	message = message:gsub('\2', '')
	message = message:gsub('\31', '')
	message = message:gsub('\3[0-9][0-9,]*', '')

	if string.sub(message, 1, 1) == string.char(1) then
		mt_irc.conn:invoke("OnCTCP", user, channel, message)
		return
	end

	if channel == mt_irc.conn.nick then
		mt_irc.last_from = user.nick
		mt_irc.conn:invoke("PrivateMessage", user, message)
	else
		mt_irc.last_from = channel
		mt_irc.conn:invoke("OnChannelChat", user, channel, message)
	end
end


function mt_irc.hooks.ctcp(user, channel, message)
	message = message:sub(2, -2)  -- Remove ^C
	local args = message:split(' ')
	local command = args[1]:upper()

	local function reply(s)
		mt_irc:queueMsg("NOTICE %s :\1%s %s\1", user.nick, command, s)
	end

	if command == "ACTION" and channel ~= mt_irc.conn.nick then
		local action = message:sub(8, -1)
		mt_irc:sendLocal(("* %s@IRC %s"):format(user.nick, action))
	elseif command == "VERSION" then
		reply("Minetest IRC mod "..mt_irc.version)
	elseif command == "PING" then
		reply(args[2])
	elseif command == "TIME" then
		reply(os.date())
	end
end


function mt_irc.hooks.channelChat(user, channel, message)
	-- Support multiple servers in a channel better by converting:
	-- "<server@IRC> <player> message" into "<player@server> message"
	-- "<server@IRC> *** player joined/left the game" into "*** player@server joined/left the game"
	-- and "<server@IRC> * player orders a pizza" into "* player@server orders a pizza"
	local foundchat, _, chatnick, chatmessage =
		message:find("^<([^>]+)> (.*)$")
	local foundjoin, _, joinnick =
		message:find("^%*%*%* ([^%s]+) joined the game$")
	local foundleave, _, leavenick =
		message:find("^%*%*%* ([^%s]+) left the game$")
	local foundaction, _, actionnick, actionmessage =
		message:find("^%* ([^%s]+) (.*)$")

	if mt_irc:check_botcmd(user, channel, message) then
		return
	elseif message:sub(1, 5) == "[off]" then
		return
	elseif foundchat then
		mt_irc:sendLocal(("<%s@%s> %s")
				:format(chatnick, user.nick, chatmessage))
	elseif foundjoin then
		mt_irc:sendLocal(("*** %s@%s joined the game")
				:format(joinnick, user.nick))
	elseif foundleave then
		mt_irc:sendLocal(("*** %s@%s left the game")
				:format(leavenick, user.nick))
	elseif foundaction then
		mt_irc:sendLocal(("* %s@%s %s")
				:format(actionnick, user.nick, actionmessage))
	else
		mt_irc:sendLocal(("<%s@IRC> %s"):format(user.nick, message))
	end
end


function mt_irc.hooks.pm(user, message)
	-- Trim prefix if it is found
	local prefix = mt_irc.config.command_prefix
	if prefix and message:sub(1, #prefix) == prefix then
		message = message:sub(#prefix + 1)
	end
	mt_irc:bot_command(user, message)
end


function mt_irc.hooks.kick(channel, target, prefix, reason)
	if target == mt_irc.conn.nick then
		minetest.chat_send_all("IRC: kicked from "..channel.." by "..prefix.nick..".")
		mt_irc:disconnect("Kicked")
	else
		mt_irc:sendLocal(("-!- %s was kicked from %s by %s [%s]")
				:format(target, channel, prefix.nick, reason))
	end
end


function mt_irc.hooks.notice(user, target, message)
	if not user.nick then return end --Server NOTICEs
	if target == mt_irc.conn.nick then return end
	mt_irc:sendLocal("--"..user.nick.."@IRC-- "..message)
end


function mt_irc.hooks.mode(user, target, modes, ...)
	local by = ""
	if user.nick then
		by = " by "..user.nick
	end
	local options = ""
	for _, option in pairs({...}) do
		options = options.." "..option
	end
	minetest.chat_send_all(("-!- mode/%s [%s%s]%s")
			:format(target, modes, options, by))
end


function mt_irc.hooks.nick(user, newNick)
	mt_irc:sendLocal(("-!- %s is now known as %s")
			:format(user.nick, newNick))
end


function mt_irc.hooks.join(user, channel)
	mt_irc:sendLocal(("-!- %s joined %s")
			:format(user.nick, channel))
end


function mt_irc.hooks.part(user, channel, reason)
	reason = reason or ""
	mt_irc:sendLocal(("-!- %s has left %s [%s]")
			:format(user.nick, channel, reason))
end


function mt_irc.hooks.quit(user, reason)
	mt_irc:sendLocal(("-!- %s has quit [%s]")
			:format(user.nick, reason))
end


function mt_irc.hooks.disconnect(message, isError)
	mt_irc.connected = false
	if isError then
		minetest.log("error",  "IRC: Error: Disconnected, reconnecting in one minute.")
		minetest.chat_send_all("IRC: Error: Disconnected, reconnecting in one minute.")
		minetest.after(60, mt_irc.connect, mt_irc)
	else
		minetest.log("action", "IRC: Disconnected.")
		minetest.chat_send_all("IRC: Disconnected.")
	end
end


function mt_irc.hooks.preregister(conn)
	if not (mt_irc.config.SASLUser and mt_irc.config.SASLPass) then return end
	local authString = mt_irc.b64e(
		("%s\x00%s\x00%s"):format(
		mt_irc.config.SASLUser,
		mt_irc.config.SASLUser,
		mt_irc.config.SASLPass)
	)
	conn:send("CAP REQ sasl")
	conn:send("AUTHENTICATE PLAIN")
	conn:send("AUTHENTICATE "..authString)
	--LuaIRC will send CAP END
end


mt_irc:register_hook("PreRegister",     mt_irc.hooks.preregister)
mt_irc:register_hook("OnRaw",           mt_irc.hooks.raw)
mt_irc:register_hook("OnSend",          mt_irc.hooks.send)
mt_irc:register_hook("OnChat",          mt_irc.hooks.chat)
mt_irc:register_hook("OnPart",          mt_irc.hooks.part)
mt_irc:register_hook("OnKick",          mt_irc.hooks.kick)
mt_irc:register_hook("OnJoin",          mt_irc.hooks.join)
mt_irc:register_hook("OnQuit",          mt_irc.hooks.quit)
mt_irc:register_hook("NickChange",      mt_irc.hooks.nick)
mt_irc:register_hook("OnCTCP",          mt_irc.hooks.ctcp)
mt_irc:register_hook("PrivateMessage",  mt_irc.hooks.pm)
mt_irc:register_hook("OnNotice",        mt_irc.hooks.notice)
mt_irc:register_hook("OnChannelChat",   mt_irc.hooks.channelChat)
mt_irc:register_hook("OnModeChange",    mt_irc.hooks.mode)
mt_irc:register_hook("OnDisconnect",    mt_irc.hooks.disconnect)

