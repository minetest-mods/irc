-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


mt_irc.hooks = {}
mt_irc.registered_hooks = {}


-- TODO: Add proper conversion from CP1252 to UTF-8.
local stripped_chars = {"\2", "\31"}
for c = 127, 255 do
	table.insert(stripped_chars, string.char(c))
end
stripped_chars = "["..table.concat(stripped_chars, "").."]"

local function normalize(text)
	-- Strip colors
	text = text:gsub("\3[0-9][0-9,]*", "")

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


function mt_irc.hooks.chat(msg)
	local channel, text = msg.args[1], msg.args[2]
	if text:sub(1, 1) == string.char(1) then
		mt_irc.conn:invoke("OnCTCP", msg)
		return
	end

	if channel == mt_irc.conn.nick then
		mt_irc.last_from = msg.user.nick
		mt_irc.conn:invoke("PrivateMessage", msg)
	else
		mt_irc.last_from = channel
		mt_irc.conn:invoke("OnChannelChat", msg)
	end
end


function mt_irc.hooks.ctcp(msg)
	local text = msg.args[2]:sub(2, -2)  -- Remove ^C
	local args = text:split(' ')
	local command = args[1]:upper()

	local function reply(s)
		mt_irc:queue(irc.msgs.notice(msg.user.nick,
				("\1%s %s\1"):format(command, s)))
	end

	if command == "ACTION" and msg.args[1] == mt_irc.config.channel then
		local action = text:sub(8, -1)
		mt_irc:sendLocal(("* %s@IRC %s"):format(msg.user.nick, action))
	elseif command == "VERSION" then
		reply(("Minetest IRC mod version %s.")
			:format(mt_irc.version))
	elseif command == "PING" then
		reply(args[2])
	elseif command == "TIME" then
		reply(os.date())
	end
end


function mt_irc.hooks.channelChat(msg)
	local text = normalize(msg.args[2])

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
	local foundaction, _, actionnick, actionmessage =
		text:find("^%* ([^%s]+) (.*)$")

	mt_irc:check_botcmd(msg)

	if text:sub(1, 5) == "[off]" then
		return
	elseif foundchat then
		mt_irc:sendLocal(("<%s@%s> %s")
				:format(chatnick, msg.user.nick, chatmessage))
	elseif foundjoin then
		mt_irc:sendLocal(("*** %s joined %s")
				:format(joinnick, msg.user.nick))
	elseif foundleave then
		mt_irc:sendLocal(("*** %s left %s")
				:format(leavenick, msg.user.nick))
	elseif foundaction then
		mt_irc:sendLocal(("* %s@%s %s")
				:format(actionnick, msg.user.nick, actionmessage))
	else
		mt_irc:sendLocal(("<%s@IRC> %s"):format(msg.user.nick, text))
	end
end


function mt_irc.hooks.pm(msg)
	-- Trim prefix if it is found
	local text = msg.args[2]
	local prefix = mt_irc.config.command_prefix
	if prefix and text:sub(1, #prefix) == prefix then
		text = text:sub(#prefix + 1)
	end
	mt_irc:bot_command(msg, text)
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
	if user.nick and target == mt_irc.config.channel then
		mt_irc:sendLocal("-"..user.nick.."@IRC- "..message)
	end
end


function mt_irc.hooks.mode(user, target, modes, ...)
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
mt_irc:register_hook("DoPrivmsg",       mt_irc.hooks.chat)
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

