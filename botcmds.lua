
irc.bot_commands = {}

-- From RFC1459:
-- "Because of IRC’s scandanavian origin, the characters {}| are
--  considered to be the lower case equivalents of the characters
--  []\, respectively."
local irctolower = { ["["]="{", ["\\"]="|", ["]"]="}" }

local function irclower(s)
	return (s:lower():gsub("[%[%]\\]", irctolower))
end

local function nickequals(nick1, nick2)
	return irclower(nick1) == irclower(nick2)
end

function irc.check_botcmd(msg)
	local prefix = irc.config.command_prefix
	local nick = irc.conn.nick
	local text = msg.args[2]
	local nickpart = text:sub(1, #nick)
	local suffix = text:sub(#nick+1, #nick+2)

	-- First check for a nick prefix
	if nickequals(nickpart, nick)
			and (suffix == ": " or suffix == ", ") then
		irc.bot_command(msg, text:sub(#nick + 3))
		return true
	-- Then check for the configured prefix
	elseif prefix and text:sub(1, #prefix):lower() == prefix:lower() then
		irc.bot_command(msg, text:sub(#prefix + 1))
		return true
	end
	return false
end


function irc.bot_command(msg, text)
	-- Remove leading whitespace
	text = text:match("^%s*(.*)")
	if text:sub(1, 1) == "@" then
		local _, _, player_to, message = text:find("^.([^%s]+)%s(.+)$")
		if not player_to then
			return
		elseif not minetest.get_player_by_name(player_to) then
			irc.reply("User '"..player_to.."' is not in the game.")
			return
		elseif not irc.joined_players[player_to] then
			irc.reply("User '"..player_to.."' is not using IRC.")
			return
		end
		minetest.chat_send_player(player_to,
				minetest.colorize(irc.config.pm_color,
				"PM from "..msg.user.nick.."@IRC: "..message, false))
		irc.reply("Message sent!")
		return
	end
	local pos = text:find(" ", 1, true)
	local cmd, args
	if pos then
		cmd = text:sub(1, pos - 1)
		args = text:sub(pos + 1)
	else
		cmd = text
		args = ""
	end

	if not irc.bot_commands[cmd] then
		irc.reply("Unknown command '"..cmd.."'. Try 'help'."
			.." Or use @playername <message> to send a private message")
		return
	end

	local _, message = irc.bot_commands[cmd].func(msg.user, args)
	if message then
		irc.reply(message)
	end
end


function irc.register_bot_command(name, def)
	if (not def.func) or (type(def.func) ~= "function") then
		error("Erroneous bot command definition. def.func missing.", 2)
	elseif name:sub(1, 1) == "@" then
		error("Erroneous bot command name. Command name begins with '@'.", 2)
	end
	irc.bot_commands[name] = def
end


irc.register_bot_command("help", {
	params = "<command>",
	description = "Get help about a command",
	func = function(_, args)
		if args == "" then
			local cmdlist = { }
			for name in pairs(irc.bot_commands) do
				cmdlist[#cmdlist+1] = name
			end
			return true, "Available commands: "..table.concat(cmdlist, ", ")
					.." -- Use 'help <command name>' to get"
					.." help about a specific command."
		end

		local cmd = irc.bot_commands[args]
		if not cmd then
			return false, "Unknown command '"..args.."'."
		end

		return true, ("Usage: %s%s %s -- %s"):format(
				irc.config.command_prefix or "",
				args,
				cmd.params or "<no parameters>",
				cmd.description or "<no description>")
	end
})


irc.register_bot_command("list", {
	params = "",
	description = "List available commands.",
	func = function()
		return false, "The `list` command has been merged into `help`."
				.." Use `help` with no arguments to get a list."
	end
})


irc.register_bot_command("whereis", {
	params = "<player>",
	description = "Tell the location of <player>",
	func = function(_, args)
		if args == "" then
			return false, "Player name required."
		end
		local player = minetest.get_player_by_name(args)
		if not player then
			return false, "There is no player named '"..args.."'"
		end
		local fmt = "Player %s is at (%.2f,%.2f,%.2f)"
		local pos = player:get_pos()
		return true, fmt:format(args, pos.x, pos.y, pos.z)
	end
})


local starttime = os.time()
irc.register_bot_command("uptime", {
	description = "Tell how much time the server has been up",
	func = function()
		local cur_time = os.time()
		local diff = os.difftime(cur_time, starttime)
		local fmt = "Server has been running for %d:%02d:%02d"
		return true, fmt:format(
			math.floor(diff / 60 / 60),
			math.floor(diff / 60) % 60,
			math.floor(diff) % 60
		)
	end
})


irc.register_bot_command("players", {
	description = "List the players on the server",
	func = function()
		local players = minetest.get_connected_players()
		local names = {}
		for _, player in pairs(players) do
			table.insert(names, player:get_player_name())
		end
		return true, "Connected players: "
				..table.concat(names, ", ")
	end
})

