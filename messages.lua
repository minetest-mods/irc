-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.

mt_irc.msgs = mt_irc.lib.msgs

function mt_irc:sendLocal(message)
	minetest.chat_send_all(message)
end

function mt_irc:playerMessage(name, message)
	return ("<%s> %s"):format(name, message)
end

