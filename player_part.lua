-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


function irc.player_part(name)
	if not irc.joined_players[name] then
		return false, "You are not in the channel"
	end
	irc.joined_players[name] = nil
	return true, "You left the channel"
end

function irc.player_join(name)
	if irc.joined_players[name] then
		return false, "You are already in the channel"
	elseif not minetest.get_player_by_name(name) then
		return false, "You need to be in-game to join the channel"
	end
	irc.joined_players[name] = true
	return true, "You joined the channel"
end


minetest.register_chatcommand("join", {
	description = "Join the IRC channel",
	privs = {shout=true},
	func = function(name)
		return irc.player_join(name)
	end
})

minetest.register_chatcommand("part", {
	description = "Part the IRC channel",
	privs = {shout=true},
	func = function(name)
		return irc.player_part(name)
	end
})

minetest.register_chatcommand("who", {
	description = "Tell who is currently on the channel",
	privs = {},
	func = function()
		local out, n = { }, 0
		for plname in pairs(irc.joined_players) do
			n = n + 1
			out[n] = plname
		end
		table.sort(out)
		return true, n.." player(s) in channel: "..table.concat(out, ", ")
	end
})


minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	irc.joined_players[name] = irc.config.auto_join
end)


minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	irc.joined_players[name] = nil
end)

function irc.sendLocal(message)
	for name, _ in pairs(irc.joined_players) do
		minetest.chat_send_player(name,
					minetest.colorize(irc.config.chat_color, message))
	end
	irc.logChat(message)
end
