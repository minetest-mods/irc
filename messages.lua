-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

irc.msgs = irc.lib.msgs

function irc:logChat(message, name)
	if name then
		name = " to "..name
	else
		name = ""
	end
	minetest.log("action", "IRC CHAT"..name..": "..message)
end

function irc:sendLocal(message)
	minetest.chat_send_all(message)
	irc:logChat(message)
end

function irc:playerMessage(name, message)
	return ("<%s> %s"):format(name, message)
end
