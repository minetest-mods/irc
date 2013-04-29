mt_irc.bot_commands = {}


function mt_irc:bot_command(user, message)
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
		self:say(user.nick, "Unknown command '"..cmd.."'. Try `!help'."
			.." Or use @playername <message> to send a private message")
		return
	end
 
	self.bot_commands[cmd].func(user, args)
end


function mt_irc:register_bot_command(name, def)
	if (not def.func) or (type(def.func) ~= "function") then
		error("Erroneous bot command definition. def.func missing.", 2)
	end
	self.bot_commands[name] = def
end


mt_irc:register_bot_command("help", {
	params = "<command>",
	description = "Get help about a command",
	func = function(user, args)
		if args == "" then
			mt_irc:say(user.nick, "No command name specified. Use 'list' for a list of cammands")
			return
		end

		local cmd = mt_irc.bot_commands[args]
		if not cmd then
			mt_irc:say(user.nick, "Unknown command '"..cmdname.."'.")
			return
		end

		local usage = ("Usage: %c%s %s -- %s"):format(
				mt_irc.config.command_prefix,
				args,
				cmd.params or "<no parameters>",
				cmd.description or "<no description>")
		mt_irc:say(user.nick, usage)		
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
		mt_irc:say(user.nick, cmdlist
			.." -- Use 'help <command name>' to get help about a specific command.")
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
			mt_irc:say(user.nick, fmt:format(args, pos.x, pos.y, pos.z))
			return
		end
		mt_irc:say(user.nick, "There is No player named '"..args.."'")
	end
})


local starttime = os.time()
mt_irc:register_bot_command("uptime", {
	description = "Tell how much time the server has been up",
	func = function(user, args)
		local cur_time = os.time()
		local diff = os.difftime(cur_time, starttime)
		local fmt = "Server has been running for %d:%02d:%02d"
		mt_irc:say(user.nick, fmt:format(
			math.floor(diff / 60 / 60),
			math.mod(math.floor(diff / 60), 60),
			math.mod(math.floor(diff), 60)
		))
	end
})

