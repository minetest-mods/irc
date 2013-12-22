
mt_irc.bot_commands = {}

function mt_irc:check_botcmd(user, target, message)
	local prefix = mt_irc.config.command_prefix
	local nick = mt_irc.conn.nick:lower()
	local nickpart = message:sub(1, #nick + 2):lower()

	-- First check for a nick prefix
	if nickpart == nick..": " or
	   nickpart == nick..", " then
		self:bot_command(user, message:sub(#nick + 3))
		return true
	-- Then check for the configured prefix
	elseif prefix and message:sub(1, #prefix):lower() == prefix:lower() then
		self:bot_command(user, message:sub(#prefix + 1))
		return true
	end
	return false
end


function mt_irc:bot_command(user, message)
	if message:sub(1, 1) == "@" then
		local found, _, player_to, message = message:find("^.([^%s]+)%s(.+)$")
		if not mt_irc.joined_players[player_to] then
			mt_irc:reply("User '"..player_to.."' has parted.")
			return
		elseif not minetest.get_player_by_name(player_to) then
			mt_irc:reply("User '"..player_to.."' is not in the game.")
			return
		end
		minetest.chat_send_player(player_to,
				"PM from "..user.nick.."@IRC: "..message, false)
		mt_irc:reply("Message sent!")
		return
	end
	local pos = message:find(" ", 1, true)
	local cmd, args
	if pos then
		cmd = message:sub(1, pos - 1)
		args = message:sub(pos + 1)
	else
		cmd = message
		args = ""
	end
 
	if not self.bot_commands[cmd] then
		self:reply("Unknown command '"..cmd.."'. Try 'list'."
			.." Or use @playername <message> to send a private message")
		return
	end
 
	self.bot_commands[cmd].func(user, args)
end


function mt_irc:register_bot_command(name, def)
	if (not def.func) or (type(def.func) ~= "function") then
		error("Erroneous bot command definition. def.func missing.", 2)
	elseif name:sub(1, 1) == "@" then
		error("Erroneous bot command name. Command name begins with '@'.", 2)
	end
	self.bot_commands[name] = def
end


mt_irc:register_bot_command("help", {
	params = "<command>",
	description = "Get help about a command",
	func = function(user, args)
		if args == "" then
			mt_irc:reply("No command name specified. Use 'list' for a list of commands")
			return
		end

		local cmd = mt_irc.bot_commands[args]
		if not cmd then
			mt_irc:reply("Unknown command '"..cmdname.."'.")
			return
		end

		mt_irc:reply(("Usage: %c%s %s -- %s"):format(
				mt_irc.config.command_prefix,
				args,
				cmd.params or "<no parameters>",
				cmd.description or "<no description>"))
	end
})


mt_irc:register_bot_command("list", {
	params = "",
	description = "List available commands.",
	func = function(user, args)
		local cmdlist = "Available commands: "
		for name, cmd in pairs(mt_irc.bot_commands) do
			cmdlist = cmdlist..name..", "
		end
		mt_irc:reply(cmdlist.." -- Use 'help <command name>' to get"
			.." help about a specific command.")
	end
})


mt_irc:register_bot_command("whereis", {
	params = "<player>",
	description = "Tell the location of <player>",
	func = function(user, args)
		if args == "" then
			mt_irc:bot_help(user, "whereis")
			return
		end
		local player = minetest.env:get_player_by_name(args)
		if player then
			local fmt = "Player %s is at (%.2f,%.2f,%.2f)"
			local pos = player:getpos()
			mt_irc:reply(fmt:format(args, pos.x, pos.y, pos.z))
			return
		end
		mt_irc:reply("There is no player named '"..args.."'")
	end
})


local starttime = os.time()
mt_irc:register_bot_command("uptime", {
	description = "Tell how much time the server has been up",
	func = function(user, args)
		local cur_time = os.time()
		local diff = os.difftime(cur_time, starttime)
		local fmt = "Server has been running for %d:%02d:%02d"
		mt_irc:reply(fmt:format(
			math.floor(diff / 60 / 60),
			math.mod(math.floor(diff / 60), 60),
			math.mod(math.floor(diff), 60)
		))
	end
})


mt_irc:register_bot_command("players", {
	description = "List the players on the server",
	func = function(user, args)
		local players = minetest.get_connected_players()
		local names = {}
		for _, player in pairs(players) do
			table.insert(names, player:get_player_name())
		end
		mt_irc:reply("Connected players: "
				..table.concat(names, ", "))
	end
})

