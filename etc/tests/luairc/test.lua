#!/usr/bin/lua

local irc = require "irc"
local dcc = require "irc.dcc"

irc.DEBUG = true

local ip_prog = io.popen("get_ip")
local ip = ip_prog:read()
ip_prog:close()
irc.set_ip(ip)

local function print_state()
    for chan in irc.channels() do
        print(chan..": Channel ops: "..table.concat(chan:ops(), " "))
        print(chan..": Channel voices: "..table.concat(chan:voices(), " "))
        print(chan..": Channel normal users: "..table.concat(chan:users(), " "))
        print(chan..": All channel members: "..table.concat(chan:members(), " "))
    end
end

local function on_connect()
    print("Joining channel #doytest...")
    irc.join("#doytest")
    print("Joining channel #doytest2...")
    irc.join("#doytest2")
end
irc.register_callback("connect", on_connect)

local function on_me_join(chan)
    print("Join to " .. chan .. " complete.")
    print(chan .. ": Channel type: " .. chan.chanmode)
    if chan.topic.text and chan.topic.text ~= "" then
        print(chan .. ": Channel topic: " .. chan.topic.text)
        print("  Set by " .. chan.topic.user ..
              " at " .. os.date("%c", chan.topic.time))
    end
    irc.act(chan.name, "is here")
    print_state()
end
irc.register_callback("me_join", on_me_join)

local function on_join(chan, user)
    print("I saw a join to " .. chan)
    if tostring(user) ~= "doylua" then
        irc.say(tostring(chan), "Hi, " .. user)
    end
    print_state()
end
irc.register_callback("join", on_join)

local function on_part(chan, user, part_msg)
    print("I saw a part from " .. chan .. " saying " .. part_msg)
    print_state()
end
irc.register_callback("part", on_part)

local function on_nick_change(new_nick, old_nick)
    print("I saw a nick change: "  ..  old_nick .. " -> " .. new_nick)
    print_state()
end
irc.register_callback("nick_change", on_nick_change)

local function on_kick(chan, user)
    print("I saw a kick in " .. chan)
    print_state()
end
irc.register_callback("kick", on_kick)

local function on_quit(chan, user)
    print("I saw a quit from " .. chan)
    print_state()
end
irc.register_callback("quit", on_quit)

local function whois_cb(cb_data)
    print("WHOIS data for " .. cb_data.nick)
    if cb_data.user then print("Username: " .. cb_data.user) end
    if cb_data.host then print("Host: " .. cb_data.host) end
    if cb_data.realname then print("Realname: " .. cb_data.realname) end
    if cb_data.server then print("Server: " .. cb_data.server) end
    if cb_data.serverinfo then print("Serverinfo: " .. cb_data.serverinfo) end
    if cb_data.away_msg then print("Awaymsg: " .. cb_data.away_msg) end
    if cb_data.is_oper then print(nick .. "is an IRCop") end
    if cb_data.idle_time then print("Idletime: " .. cb_data.idle_time) end
    if cb_data.channels then
        print("Channel list for " .. cb_data.nick .. ":")
        for _, channel in ipairs(cb_data.channels) do print(channel) end
    end
end

local function serverversion_cb(cb_data)
    print("VERSION data for " .. cb_data.server)
    print("Version: " .. cb_data.version)
    print("Comments: " .. cb_data.comments)
end

local function ping_cb(cb_data)
    print("CTCP PING for " .. cb_data.nick)
    print("Roundtrip time: " .. cb_data.time .. "s")
end

local function time_cb(cb_data)
    print("CTCP TIME for " .. cb_data.nick)
    print("Localtime: " .. cb_data.time)
end

local function version_cb(cb_data)
    print("CTCP VERSION for " .. cb_data.nick)
    print("Version: " .. cb_data.version)
end

local function stime_cb(cb_data)
    print("TIME for " .. cb_data.server)
    print("Server time: " .. cb_data.time)
end

local function on_channel_msg(chan, from, msg)
    if from == "doy" then
        if msg == "leave" then
            irc.part(chan.name)
            return
        elseif msg:sub(1, 3) == "op " then
            chan:op(msg:sub(4))
            return
        elseif msg:sub(1, 5) == "deop " then
            chan:deop(msg:sub(6))
            return
        elseif msg:sub(1, 6) == "voice " then
            chan:voice(msg:sub(7))
            return
        elseif msg:sub(1, 8) == "devoice " then
            chan:devoice(msg:sub(9))
            return
        elseif msg:sub(1, 5) == "kick " then
            chan:kick(msg:sub(6))
            return
        elseif msg:sub(1, 5) == "send " then
            dcc.send(from, msg:sub(6))
            return
        elseif msg:sub(1, 6) == "whois " then
            irc.whois(whois_cb, msg:sub(7))
            return
        elseif msg:sub(1, 8) == "sversion" then
            irc.server_version(serverversion_cb)
            return
        elseif msg:sub(1, 5) == "ping " then
            irc.ctcp_ping(ping_cb, msg:sub(6))
            return
        elseif msg:sub(1, 5) == "time " then
            irc.ctcp_time(time_cb, msg:sub(6))
            return
        elseif msg:sub(1, 8) == "version " then
            irc.ctcp_version(version_cb, msg:sub(9))
            return
        elseif msg:sub(1, 5) == "stime" then
            irc.server_time(stime_cb)
            return
        elseif msg:sub(1, 6) == "trace " then
            irc.trace(trace_cb, msg:sub(7))
            return
        elseif msg:sub(1, 5) == "trace" then
            irc.trace(trace_cb)
            return
        end
    end
    if from ~= "doylua" then
        irc.say(chan.name, from .. ": " .. msg)
    end
end
irc.register_callback("channel_msg", on_channel_msg)

local function on_private_msg(from, msg)
    if from == "doy" then
        if msg == "leave" then
            irc.quit("gone")
            return
        elseif msg:sub(1, 5) == "send " then
            dcc.send(from, msg:sub(6))
            return
        end
    end
    if from ~= "doylua" then
        irc.say(from, msg)
    end
end
irc.register_callback("private_msg", on_private_msg)

local function on_channel_act(chan, from, msg)
    irc.act(chan.name, "jumps on " .. from)
end
irc.register_callback("channel_act", on_channel_act)

local function on_private_act(from, msg)
    irc.act(from, "jumps on you")
end
irc.register_callback("private_act", on_private_act)

local function on_op(chan, from, nick)
    print(nick .. " was opped in " .. chan .. " by " .. from)
    print_state()
end
irc.register_callback("op", on_op)

local function on_deop(chan, from, nick)
    print(nick .. " was deopped in " .. chan .. " by " .. from)
    print_state()
end
irc.register_callback("deop", on_deop)

local function on_voice(chan, from, nick)
    print(nick .. " was voiced in " .. chan .. " by " .. from)
    print_state()
end
irc.register_callback("voice", on_voice)

local function on_devoice(chan, from, nick)
    print(nick .. " was devoiced in " .. chan .. " by " .. from)
    print_state()
end
irc.register_callback("devoice", on_devoice)

local function on_dcc_send()
    return true
end
irc.register_callback("dcc_send", on_dcc_send)

irc.connect{network = "irc.freenode.net", nick = "doylua"}
