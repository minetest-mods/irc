
mt_irc.bot_commands = { };

mt_irc.bot_help = function ( from, cmdname )
	local cmd = mt_irc.bot_commands[cmdname];
	if (not cmd) then
		irc.say(from, "Unknown command `"..cmdname.."'");
		return;
	end
	local usage = "Usage: !"..cmdname;
	if (cmd.params) then usage = usage.." "..cmd.params; end
	irc.say(from, usage);
	if (cmd.description) then irc.say(from, "	"..cmd.description); end
end

mt_irc.register_bot_command = function ( name, def )
	if ((not def.func) or (type(def.func) ~= "function")) then
		error("Wrong bot command definition", 2);
	end
	mt_irc.bot_commands[name] = def;
end

mt_irc.register_bot_command("help", {
	params = "[<command>]";
	description = "Get help about a command";
	func = function ( from, args )
		if (args ~= "") then
			mt_irc.bot_help(from, args);
		else
			local cmdlist = "Available commands:";
			for name,cmd in pairs(mt_irc.bot_commands) do
				cmdlist = cmdlist.." "..name;
			end
			irc.say(from, cmdlist);
			irc.say(from, "Use `!help <command name>' to get help about a specific command.");
		end
	end;
});

mt_irc.register_bot_command("who", {
	params = nil;
	description = "Tell who is playing";
	func = function ( from, args )
		local s = "";
		for k, v in pairs(mt_irc.connected_players) do
			if (v) then
				s = s.." "..k;
			end
		end
		irc.say(from, "Players On Channel:"..s);
	end;
});

mt_irc.register_bot_command("whereis", {
	params = "<player>";
	description = "Tell the location of <player>";
	func = function ( from, args )
		if (args == "") then
			mt_irc.bot_help(from, "whereis");
			return;
		end
		local list = minetest.env:get_objects_inside_radius({x=0,y=0,z=0}, 100000);
		for _, obj in ipairs(list) do
			if (obj:is_player() and (obj:get_player_name() == args)) then
				local fmt = "Player %s is at (%.2f,%.2f,%.2f)";
				local pos = obj:getpos();
				irc.say(from, fmt:format(args, pos.x, pos.y, pos.z));
				return;
			end
		end
		irc.say(from, "There's No player named `"..args.."'");
	end;
});

local starttime = os.time();

mt_irc.register_bot_command("uptime", {
	params = "";
	description = "Tell how much time the server has been up";
	privs = { shout=true; };
	func = function ( name, param )
		local t = os.time();
		local diff = os.difftime(t, starttime);
		local fmt = "Server has been running for %d:%02d:%02d";
		irc.say(name, fmt:format(
			math.floor(diff / 60 / 60),
			math.mod(math.floor(diff / 60), 60),
			math.mod(math.floor(diff), 60)
		));
	end;
});
