-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

irc.msgs = irc.lib.msgs

function irc:sendLocal(message)
	minetest.chat_send_all(message)
end

function irc:playerMessage(name, message)
	return ("<%s> %s"):format(name, message)
end

