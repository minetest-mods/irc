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
			minetest.chat_send_player(name, "Not connected to IRC. Use /irc_connect to connect.")
			return
		end
		local found, _, toname, message = param:find("^([^%s]+)%s(.+)")
		if not found then
			minetest.chat_send_player(name, "Invalid usage, see /help irc_msg.")
			return
		end
		local toname_l = toname:lower()
		local validNick = false
		for nick, user in pairs(irc.conn.channels[irc.config.channel].users) do
			if nick:lower() == toname_l then
				validNick = true
				break
			end
		end
		if toname_l:find("serv$") or toname_l:find("bot$") then
			validNick = false
		end
		if not validNick then
			minetest.chat_send_player(name,
				"You can not message that user. (Hint: They have to be in the channel)")
			return
		end
		irc:say(toname, irc:playerMessage(name, message))
		minetest.chat_send_player(name, "Message sent!")
	end
})


minetest.register_chatcommand("irc_names", {
	params = "",
	description = "List the users in IRC.",
	func = function(name, params)
		if not irc.connected then
			minetest.chat_send_player(name, "Not connected to IRC. Use /irc_connect to connect.")
			return
		end
		local users = { }
		for k, v in pairs(irc.conn.channels[irc.config.channel].users) do
			table.insert(users, k)
		end
		minetest.chat_send_player(name, "Users in IRC: "..table.concat(users, ", "))
	end
})


minetest.register_chatcommand("irc_connect", {
	description = "Connect to the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if irc.connected then
			minetest.chat_send_player(name, "You are already connected to IRC.")
			return
		end
		minetest.chat_send_player(name, "IRC: Connecting...")
		irc:connect()
	end
})


minetest.register_chatcommand("irc_disconnect", {
	params = "[message]",
	description = "Disconnect from the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not irc.connected then
			minetest.chat_send_player(name, "You are not connected to IRC.")
			return
		end
		if params == "" then
			params = "Manual disconnect by "..name
		end
		irc:disconnect(param)
	end
})


minetest.register_chatcommand("irc_reconnect", {
	description = "Reconnect to the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not irc.connected then
			minetest.chat_send_player(name, "You are not connected to IRC.")
			return
		end
		irc:disconnect("Reconnecting...")
		irc:connect()
	end
})


minetest.register_chatcommand("irc_quote", {
	params = "<command>",
	description = "Send a raw command to the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not irc.connected then
			minetest.chat_send_player(name, "You are not connected to IRC.")
			return
		end
		irc:queue(param)
		minetest.chat_send_player(name, "Command sent!")
	end
})


local oldme = minetest.chatcommands["me"].func
minetest.chatcommands["me"].func = function(name, param, ...)
	oldme(name, param, ...)
	irc:say(("* %s %s"):format(name, param))
end

