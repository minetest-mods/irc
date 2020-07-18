-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if irc.connected and irc.config.send_join_part then
		irc.say("*** "..name.." joined the game")
	end
end)


minetest.register_on_leaveplayer(function(player, timed_out)
	local name = player:get_player_name()
	if irc.connected and irc.config.send_join_part then
		irc.say("*** "..name.." left the game"..
				(timed_out and " (Timed out)" or ""))
	end
end)


minetest.register_on_chat_message(function(name, message)
	if not irc.connected
	   or message:sub(1, 1) == "/"
	   or message:sub(1, 5) == "[off]"
	   or not irc.joined_players[name]
	   or (not minetest.check_player_privs(name, {shout=true})) then
		return
	end
	local nl = message:find("\n", 1, true)
	if nl then
		message = message:sub(1, nl - 1)
	end
	irc.say(irc.playerMessage(name, minetest.strip_colors(message)))
end)


minetest.register_on_shutdown(function()
	irc.disconnect("Game shutting down.")
end)

