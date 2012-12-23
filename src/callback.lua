
minetest.register_on_joinplayer(function ( player )

    irc.say(mt_irc.channel, "*** "..player:get_player_name().." joined the game");

end);

irc.register_callback("connect", function ( )
    irc.join(mt_irc.channel);
    for _,player in ipairs(minetest.get_connected_players()) do
        mt_irc.connected_players[player:get_player_name()] = mt_irc.connect_on_join;
    end
end);

irc.register_callback("channel_msg", function ( channel, from, message )
    if (not mt_irc.connect_ok) then return; end
    local t = {
        name=(from or "<BUG:no one is saying this>");
        message=(message or "<BUG:there is no message>");
        server=mt_irc.server;
        port=mt_irc.port;
        channel=mt_irc.channel;
    };
    local text = mt_irc.message_format_in:gsub("%$%(([^)]+)%)", t)
    for k, v in pairs(mt_irc.connected_players) do
        if (v) then minetest.chat_send_player(k, text); end
    end
end);

mt_irc.bot_commands = {
    help = {
        func = function ( from, args )
            irc.say(from, "HELP:");
            irc.say(from, ">username message");
            irc.say(from, "  Send private message <message> to <username>");
            irc.say(from, "!who");
            irc.say(from, "  Return list of players currently in-game");
            irc.say(from, "!help");
            irc.say(from, "  Show this help message");
        end;
    };
    who = {
        func = function ( from, args )
            local s = "";
            for k, v in pairs(mt_irc.connected_players) do
                if (v) then
                    s = s.." "..k;
                end
            end
            irc.say(from, "Players On Channel:"..s);
        end;
    };
    whereis = {
        -- !whereis PLAYER
        func = function ( from, args )
            if (args == "") then
                irc.say(from, "Usage: !whereis PLAYER");
                return;
            end
            local list = minetest.env:get_objects_inside_radius({x=0,y=0,z=0}, 100000);
            for _, obj in ipairs(list) do
                if (obj:is_player() and (obj:get_player_name() == args)) then
                    local fmt = "Player %s is at (%.2f,%.2f,%.2f)";
                    local pos = obj:getpos();
                    irc.say(from, fmt:format(args, pos.x, pos.y, pos.z));
                end
            end
        end;
    };
};

local function bot_command ( from, message )

    local pos = message:find(" ", 1, true);
    local cmd, args;
    if (pos) then
        cmd = message:sub(1, pos - 1);
        args = message:sub(pos + 1);
    else
        cmd = message;
        args = "";
    end

    if (not mt_irc.bot_commands[cmd]) then
        irc.say(from, "Unknown command `"..cmd.."'. Try `!help'.");
    end

    mt_irc.bot_commands[cmd].func(from, args);

end

irc.register_callback("private_msg", function ( from, message )
    if (not mt_irc.connect_ok) then return; end
    local player_to;
    local msg;
    if (message:sub(1, 1) == ">") then
        local pos = message:find(" ", 1, true);
        if (not pos) then return; end
        player_to = message:sub(2, pos - 1);
        msg = message:sub(pos + 1);
    elseif (message:sub(1, 1) == "!") then
        bot_command(from, message:sub(2));
        return;
    else
        irc.say(from, 'Message not sent! Please use "!help" to see possible commands.');
        return;
    end
    if (not mt_irc.connected_players[player_to]) then
        irc.say(from, "User `"..player_to.."' is not connected to IRC.");
        return;
    end
    local t = {
        name=(from or "<BUG:no one is saying this>");
        message=(msg or "<BUG:there is no message>");
        server=mt_irc.server;
        port=mt_irc.port;
        channel=mt_irc.channel;
    };
    local text = mt_irc.message_format_in:gsub("%$%(([^)]+)%)", t)
    minetest.chat_send_player(player_to, "PRIVATE: "..text);
end);

irc.register_callback("nick_change", function ( from, old_nick )
    if (not mt_irc.connect_ok) then return; end
end);

minetest.register_on_leaveplayer(function ( player )
    local name = player:get_player_name();
    mt_irc.connected_players[name] = false;
    if (not mt_irc.connect_ok) then return; end
    irc.say(mt_irc.channel, "*** "..name.." left the game");
end);

minetest.register_on_chat_message(function ( name, message )
    if (not mt_irc.connected_players[name]) then
        minetest.chat_send_player(name, "IRC: You are not connected. Please use /join");
        return;
    end
    if (not mt_irc.connect_ok) then return; end
    if (not mt_irc.buffered_messages) then
        mt_irc.buffered_messages = { };
    end
    mt_irc.buffered_messages[#mt_irc.buffered_messages + 1] = {
        name = name;
        message = message;
    };
end);
