-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


function mt_irc:sendLocal(message)
	minetest.chat_send_all(message)
end

function mt_irc:queueMsg(message)
	table.insert(self.message_buffer, message)
end

function mt_irc:sendMsg(message)
	self.conn:send(message)
end

mt_irc.msgs = {}

function mt_irc.msgs.privmsg(to, message)
	return ("PRIVMSG %s :%s"):format(to, message)
end

function mt_irc.msgs.notice(to, message)
	return ("NOTICE %s :%s"):format(to, message)
end

function mt_irc.msgs.action(to, message)
	return ("PRIVMSG %s :%cACTION %s%c")
		:format(to, string.char(1), message, string.char(1))
end

function mt_irc.msgs.playerMessage(to, name, message)
	return mt_irc.msgs.privmsg(to, ("<%s> %s"):format(name, message))
end

-- TODO Add more message types

