-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if mt_irc.connected then
		mt_irc:say("*** "..name.." joined the game")
	end
end)


minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if mt_irc.connected then
		mt_irc:say("*** "..name.." left the game")
	end
end)


minetest.register_on_chat_message(function(name, message)
	if not mt_irc.connected
	   or message:sub(1, 1) == "/"
	   or not mt_irc.joined_players[name]
	   or (not minetest.check_player_privs(name, {shout=true})) then
		return
	end
	mt_irc:queueMsg(mt_irc.msgs.playerMessage(
			mt_irc.config.channel, name, message))
end)


minetest.register_on_shutdown(function()
	mt_irc:disconnect("Game shutting down.")
end)

