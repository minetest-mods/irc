-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

irc.msgs = irc.lib.msgs

function irc.logChat(message)
	minetest.log("action", "IRC CHAT: "..message)
end

function irc.sendLocal(message)
	minetest.chat_send_all(minetest.colorize(irc.config.chat_color, message))
	irc.logChat(message)
end

function irc.playerMessage(name, message)
	return ("<%s> %s"):format(name, message)
end
