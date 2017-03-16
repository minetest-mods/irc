-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

-- Note: This file does NOT conatin every chat command, only general ones.
-- Feature-specific commands (like /join) are in their own files.


minetest.register_chatcommand("irc_msg", {
	params = "<name> <message>",
	description = "Send a private message to an IRC user",
	privs = {shout=true},
	func = function(name, param)
		if not irc.connected then
			return false, "Not connected to IRC. Use /irc_connect to connect."
		end
		local found, _, toname, message = param:find("^([^%s]+)%s(.+)")
		if not found then
			return false, "Invalid usage, see /help irc_msg."
		end
		local toname_l = toname:lower()
		local validNick = false
		local hint = "They have to be in the channel"
		for nick in pairs(irc.conn.channels[irc.config.channel].users) do
			if nick:lower() == toname_l then
				validNick = true
				break
			end
		end
		if toname_l:find("serv$") or toname_l:find("bot$") then
			hint = "it looks like a bot or service"
			validNick = false
		end
		if not validNick then
			return false, "You can not message that user. ("..hint..")"
		end
		irc.say(toname, irc.playerMessage(name, message))
		return true, "Message sent!"
	end
})


minetest.register_chatcommand("irc_names", {
	params = "",
	description = "List the users in IRC.",
	func = function()
		if not irc.connected then
			return false, "Not connected to IRC. Use /irc_connect to connect."
		end
		local users = { }
		for nick in pairs(irc.conn.channels[irc.config.channel].users) do
			table.insert(users, nick)
		end
		return true, "Users in IRC: "..table.concat(users, ", ")
	end
})


minetest.register_chatcommand("irc_connect", {
	description = "Connect to the IRC server.",
	privs = {irc_admin=true},
	func = function(name)
		if irc.connected then
			return false, "You are already connected to IRC."
		end
		minetest.chat_send_player(name, "IRC: Connecting...")
		irc.connect()
	end
})


minetest.register_chatcommand("irc_disconnect", {
	params = "[message]",
	description = "Disconnect from the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not irc.connected then
			return false, "Not connected to IRC. Use /irc_connect to connect."
		end
		if param == "" then
			param = "Manual disconnect by "..name
		end
		irc.disconnect(param)
	end
})


minetest.register_chatcommand("irc_reconnect", {
	description = "Reconnect to the IRC server.",
	privs = {irc_admin=true},
	func = function(name)
		if not irc.connected then
			return false, "Not connected to IRC. Use /irc_connect to connect."
		end
		minetest.chat_send_player(name, "IRC: Reconnecting...")
		irc.disconnect("Reconnecting...")
		irc.connect()
	end
})


minetest.register_chatcommand("irc_quote", {
	params = "<command>",
	description = "Send a raw command to the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not irc.connected then
			return false, "Not connected to IRC. Use /irc_connect to connect."
		end
		irc.queue(param)
		minetest.chat_send_player(name, "Command sent!")
	end
})


local oldme = minetest.chatcommands["me"].func
-- luacheck: ignore
minetest.chatcommands["me"].func = function(name, param, ...)
	irc.say(("* %s %s"):format(name, param))
	return oldme(name, param, ...)
end

if irc.config.send_kicks and minetest.chatcommands["kick"] then
	local oldkick = minetest.chatcommands["kick"].func
	-- luacheck: ignore
	minetest.chatcommands["kick"].func = function(name, param, ...)
		local plname, reason = param:match("^(%S+)%s*(.*)$")
		if not plname then
			return false, "Usage: /kick player [reason]"
		end
		irc.say(("*** Kicked %s.%s"):format(name,
				reason~="" and " Reason: "..reason or ""))
		return oldkick(name, param, ...)
	end
end
