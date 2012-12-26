
minetest.register_chatcommand("msg", {
    params = "<name> <message>";
    description = "Send a private message to an IRC user";
    privs = { shout=true; };
    func = function ( name, param )
        if (not mt_irc.connect_ok) then
            minetest.chat_send_player(name, "IRC: You are not connected use /irc_connect.");
            return;
        end
        local pos = param:find(" ", 1, true);
        if (not pos) then return; end
        local name = param:sub(1, pos - 1);
        local msg = param:sub(pos + 1);
        local t = {
            name=name;
            message=msg;
        };
        local text = mt_irc.message_format_out:gsub("%$%(([^)]+)%)", t)
        irc.send("PRIVMSG", name, text);
    end;
});

minetest.register_chatcommand("irc_connect", {
    params = "";
    description = "Connect to the IRC server";
    privs = { irc_admin=true; };
    func = function ( name, param )
        if (mt_irc.connect_ok) then
            minetest.chat_send_player(name, "IRC: You are already connected.");
            return;
        end
        mt_irc.connect();
        minetest.chat_send_player(name, "IRC: You are now connected.");
        irc.say(mt_irc.channel, name.." joined the channel.");
    end;
});

minetest.register_chatcommand("join", {
    params = "";
    description = "Join the IRC channel";
    privs = { shout=true; };
    func = function ( name, param )
        mt_irc.join(name);
    end;
});

minetest.register_chatcommand("part", {
    params = "";
    description = "Part the IRC channel";
    privs = { shout=true; };
    func = function ( name, param )
        mt_irc.part(name);
    end;
});

minetest.register_chatcommand("me", {
	params = "<action>";
	description = "chat action (eg. /me orders a pizza)";
	privs = { shout=true };
	func = function(name, param)
        minetest.chat_send_all("* "..name.." "..param);
        irc.say(mt_irc.channel, "* "..name.." "..param);
	end,
})
