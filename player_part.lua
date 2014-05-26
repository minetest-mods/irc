-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


function irc:player_part(name)
	if not self.joined_players[name] then
		minetest.chat_send_player(name, "IRC: You are not in the channel.")
		return
	end
	self.joined_players[name] = nil
	minetest.chat_send_player(name, "IRC: You are now out of the channel.")
end
 
function irc:player_join(name)
	if self.joined_players[name] then
		minetest.chat_send_player(name, "IRC: You are already in the channel.")
		return
	end
	self.joined_players[name] = true
	minetest.chat_send_player(name, "IRC: You are now in the channel.")
end


minetest.register_chatcommand("join", {
	description = "Join the IRC channel",
	privs = {shout=true},
	func = function(name, param)
		irc:player_join(name)
	end
})
 
minetest.register_chatcommand("part", {
	description = "Part the IRC channel",
	privs = {shout=true},
	func = function(name, param)
		irc:player_part(name)
	end
})
 
minetest.register_chatcommand("who", {
	description = "Tell who is currently on the channel",
	privs = {},
	func = function(name, param)
		local s = ""
		for name, _ in pairs(irc.joined_players) do
			s = s..", "..name
		end
		minetest.chat_send_player(name, "Players On Channel:"..s)
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

function irc:sendLocal(message)
        for name, _ in pairs(self.joined_players) do
		minetest.chat_send_player(name, message)
	end
end

