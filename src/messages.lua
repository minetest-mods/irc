-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


function mt_irc:sendLocal(message)
	minetest.chat_send_all(message)
end

mt_irc.msgs = irc.msgs

function mt_irc:playerMessage(name, message)
	return ("<%s> %s"):format(name, message)
end

