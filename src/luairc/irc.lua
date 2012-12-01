---
-- Implementation of the main LuaIRC module

-- initialization {{{
local base =      _G
local constants = require 'irc.constants'
local ctcp =      require 'irc.ctcp'
local c =         ctcp._ctcp_quote
local irc_debug = require 'irc.debug'
local message =   require 'irc.message'
local misc =      require 'irc.misc'
local socket =    require 'socket'
local os =        require 'os'
local string =    require 'string'
local table =     require 'table'
-- }}}

---
-- LuaIRC - IRC framework written in Lua
-- @release 0.3
module 'irc'

-- constants {{{
_VERSION = 'LuaIRC 0.3'
-- }}}

-- classes {{{
local Channel = base.require 'irc.channel'
-- }}}

-- local variables {{{
local irc_sock = nil
local rsockets = {}
local wsockets = {}
local rcallbacks = {}
local wcallbacks = {}
local icallbacks = {
    whois = {},
    serverversion = {},
    servertime = {},
    ctcp_ping = {},
    ctcp_time = {},
    ctcp_version = {},
}
local requestinfo = {whois = {}}
local handlers = {}
local ctcp_handlers = {}
local user_handlers = {}
local serverinfo = {}
local ip = nil
-- }}}

-- defaults {{{
TIMEOUT = 60          -- connection timeout
NETWORK = "localhost" -- default network
PORT = 6667           -- default port
NICK = "luabot"       -- default nick
USERNAME = "LuaIRC"   -- default username
REALNAME = "LuaIRC"   -- default realname
DEBUG = false         -- whether we want extra debug information
OUTFILE = nil         -- file to send debug output to - nil is stdout
-- }}}

-- private functions {{{
-- main_loop_iter {{{
local function main_loop_iter()
    if #rsockets == 0 and #wsockets == 0 then return false end
    local rready, wready, err = socket.select(rsockets, wsockets)
    if err then irc_debug._err(err); return false; end

    for _, sock in base.ipairs(rready) do
        local cb = socket.protect(rcallbacks[sock])
        local ret, err = cb(sock)
        if not ret then
            irc_debug._warn("socket error: " .. err)
            _unregister_socket(sock, 'r')
        end
    end

    for _, sock in base.ipairs(wready) do
        local cb = socket.protect(wcallbacks[sock])
        local ret, err = cb(sock)
        if not ret then
            irc_debug._warn("socket error: " .. err)
            _unregister_socket(sock, 'w')
        end
    end

    return true
end
-- }}}

-- begin_main_loop {{{
local function begin_main_loop()
    while main_loop_iter() do end
end
-- }}}

-- incoming_message {{{
local function incoming_message(sock)
    local raw_msg = socket.try(sock:receive())
    irc_debug._message("RECV", raw_msg)
    local msg = message._parse(raw_msg)
    misc._try_call_warn("Unhandled server message: " .. msg.command,
                        handlers["on_" .. msg.command:lower()],
                        (misc._parse_user(msg.from)), base.unpack(msg.args))
    return true
end
-- }}}

-- callback {{{
local function callback(name, ...)
    return misc._try_call(user_handlers[name], ...)
end
-- }}}
-- }}}

-- internal message handlers {{{
-- command handlers {{{
-- on_nick {{{
function handlers.on_nick(from, new_nick)
    for chan in channels() do
        chan:_change_nick(from, new_nick)
    end
    callback("nick_change", new_nick, from)
end
-- }}}

-- on_join {{{
function handlers.on_join(from, chan)
    base.assert(serverinfo.channels[chan],
                "Received join message for unknown channel: " .. chan)
    if serverinfo.channels[chan].join_complete then
        serverinfo.channels[chan]:_add_user(from)
        callback("join", serverinfo.channels[chan], from)
    end
end
-- }}}

-- on_part {{{
function handlers.on_part(from, chan, part_msg)
    -- don't assert on chan here, since we get part messages for ourselves
    -- after we remove the channel from the channel list
    if not serverinfo.channels[chan] then return end
    if serverinfo.channels[chan].join_complete then
        serverinfo.channels[chan]:_remove_user(from)
        callback("part", serverinfo.channels[chan], from, part_msg)
    end
end
-- }}}

-- on_mode {{{
function handlers.on_mode(from, to, mode_string, ...)
    local dir = mode_string:sub(1, 1)
    mode_string = mode_string:sub(2)
    local args = {...}

    if to:sub(1, 1) == "#" then
        -- handle channel mode requests {{{
        base.assert(serverinfo.channels[to],
                    "Received mode change for unknown channel: " .. to)
        local chan = serverinfo.channels[to]
        local ind = 1
        for i = 1, mode_string:len() do
            local mode = mode_string:sub(i, i)
            local target = args[ind]
            -- channel modes other than op/voice will be implemented as
            -- information request commands
            if mode == "o" then -- channel op {{{
                chan:_change_status(target, dir == "+", "o")
                callback(({["+"] = "op", ["-"] = "deop"})[dir],
                         chan, from, target)
                ind = ind + 1
                -- }}}
            elseif mode == "v" then -- voice {{{
                chan:_change_status(target, dir == "+", "v")
                callback(({["+"] = "voice", ["-"] = "devoice"})[dir],
                         chan, from, target)
                ind = ind + 1
                -- }}}
            end
        end
        -- }}}
    elseif from == to then
        -- handle user mode requests {{{
        -- TODO: make users more easily accessible so this is actually
        -- reasonably possible
        for i = 1, mode_string:len() do
            local mode = mode_string:sub(i, i)
            if mode == "i" then -- invisible {{{
                -- }}}
            elseif mode == "s" then -- server messages {{{
                -- }}}
            elseif mode == "w" then -- wallops messages {{{
                -- }}}
            elseif mode == "o" then -- ircop {{{
                -- }}}
            end
        end
        -- }}}
    end
end
-- }}}

-- on_topic {{{
function handlers.on_topic(from, chan, new_topic)
    base.assert(serverinfo.channels[chan],
                "Received topic message for unknown channel: " .. chan)
    serverinfo.channels[chan]._topic.text = new_topic
    serverinfo.channels[chan]._topic.user = from
    serverinfo.channels[chan]._topic.time = os.time()
    if serverinfo.channels[chan].join_complete then
        callback("topic_change", serverinfo.channels[chan])
    end
end
-- }}}

-- on_invite {{{
function handlers.on_invite(from, to, chan)
    callback("invite", from, chan)
end
-- }}}

-- on_kick {{{
function handlers.on_kick(from, chan, to)
    base.assert(serverinfo.channels[chan],
                "Received kick message for unknown channel: " .. chan)
    if serverinfo.channels[chan].join_complete then
        serverinfo.channels[chan]:_remove_user(to)
        callback("kick", serverinfo.channels[chan], to, from)
    end
end
-- }}}

-- on_privmsg {{{
function handlers.on_privmsg(from, to, msg)
    local msgs = ctcp._ctcp_split(msg)
    for _, v in base.ipairs(msgs) do
        local msg = v.str
        if v.ctcp then
            -- ctcp message {{{
            local words = misc._split(msg)
            local received_command = words[1]
            local cb = "on_" .. received_command:lower()
            table.remove(words, 1)
            -- not using try_call here because the ctcp specification requires
            -- an error response to nonexistant commands
            if base.type(ctcp_handlers[cb]) == "function" then
                ctcp_handlers[cb](from, to, table.concat(words, " "))
            else
                notice(from, c("ERRMSG", received_command, ":Unknown query"))
            end
            -- }}}
        else
            -- normal message {{{
            if to:sub(1, 1) == "#" then
                base.assert(serverinfo.channels[to],
                            "Received channel msg from unknown channel: " .. to)
                callback("channel_msg", serverinfo.channels[to], from, msg)
            else
                callback("private_msg", from, msg)
            end
            -- }}}
        end
    end
end
-- }}}

-- on_notice {{{
function handlers.on_notice(from, to, msg)
    local msgs = ctcp._ctcp_split(msg)
    for _, v in base.ipairs(msgs) do
        local msg = v.str
        if v.ctcp then
            -- ctcp message {{{
            local words = misc._split(msg)
            local command = words[1]:lower()
            table.remove(words, 1)
            misc._try_call_warn("Unknown CTCP message: " .. command,
                                ctcp_handlers["on_rpl_"..command], from, to,
                                table.concat(words, ' '))
            -- }}}
        else
            -- normal message {{{
            if to:sub(1, 1) == "#" then
                base.assert(serverinfo.channels[to],
                            "Received channel msg from unknown channel: " .. to)
                callback("channel_notice", serverinfo.channels[to], from, msg)
            else
                callback("private_notice", from, msg)
            end
            -- }}}
        end
    end
end
-- }}}

-- on_quit {{{
function handlers.on_quit(from, quit_msg)
    for name, chan in base.pairs(serverinfo.channels) do
        chan:_remove_user(from)
    end
    callback("quit", from, quit_msg)
end
-- }}}

-- on_ping {{{
-- respond to server pings to make sure it knows we are alive
function handlers.on_ping(from, respond_to)
    send("PONG", respond_to)
end
-- }}}
-- }}}

-- server replies {{{
-- on_rpl_topic {{{
-- catch topic changes
function handlers.on_rpl_topic(from, chan, topic)
    base.assert(serverinfo.channels[chan],
                "Received topic information about unknown channel: " .. chan)
    serverinfo.channels[chan]._topic.text = topic
end
-- }}}

-- on_rpl_notopic {{{
function handlers.on_rpl_notopic(from, chan)
    base.assert(serverinfo.channels[chan],
                "Received topic information about unknown channel: " .. chan)
    serverinfo.channels[chan]._topic.text = ""
end
-- }}}

-- on_rpl_topicdate {{{
-- "topic was set by <user> at <time>"
function handlers.on_rpl_topicdate(from, chan, user, time)
    base.assert(serverinfo.channels[chan],
                "Received topic information about unknown channel: " .. chan)
    serverinfo.channels[chan]._topic.user = user
    serverinfo.channels[chan]._topic.time = base.tonumber(time)
end
-- }}}

-- on_rpl_namreply {{{
-- handles a NAMES reply
function handlers.on_rpl_namreply(from, chanmode, chan, userlist)
    base.assert(serverinfo.channels[chan],
                "Received user information about unknown channel: " .. chan)
    serverinfo.channels[chan]._chanmode = constants.chanmodes[chanmode]
    local users = misc._split(userlist)
    for k,v in base.ipairs(users) do
        if v:sub(1, 1) == "@" or v:sub(1, 1) == "+" then
            local nick = v:sub(2)
            serverinfo.channels[chan]:_add_user(nick, v:sub(1, 1))
        else
            serverinfo.channels[chan]:_add_user(v)
        end
    end
end
-- }}}

-- on_rpl_endofnames {{{
-- when we get this message, the channel join has completed, so call the
-- external cb
function handlers.on_rpl_endofnames(from, chan)
    base.assert(serverinfo.channels[chan],
                "Received user information about unknown channel: " .. chan)
    if not serverinfo.channels[chan].join_complete then
        callback("me_join", serverinfo.channels[chan])
        serverinfo.channels[chan].join_complete = true
    end
end
-- }}}

-- on_rpl_welcome {{{
function handlers.on_rpl_welcome(from)
    serverinfo = {
        connected = false,
        connecting = true,
        channels = {}
    }
end
-- }}}

-- on_rpl_yourhost {{{
function handlers.on_rpl_yourhost(from, msg)
    serverinfo.host = from
end
-- }}}

-- on_rpl_motdstart {{{
function handlers.on_rpl_motdstart(from)
    serverinfo.motd = ""
end
-- }}}

-- on_rpl_motd {{{
function handlers.on_rpl_motd(from, motd)
    serverinfo.motd = (serverinfo.motd or "") .. motd .. "\n"
end
-- }}}

-- on_rpl_endofmotd {{{
function handlers.on_rpl_endofmotd(from)
    if not serverinfo.connected then
        serverinfo.connected = true
        serverinfo.connecting = false
        callback("connect")
    end
end
-- }}}

-- on_rpl_whoisuser {{{
function handlers.on_rpl_whoisuser(from, nick, user, host, star, realname)
    local lnick = nick:lower()
    requestinfo.whois[lnick].nick = nick
    requestinfo.whois[lnick].user = user
    requestinfo.whois[lnick].host = host
    requestinfo.whois[lnick].realname = realname
end
-- }}}

-- on_rpl_whoischannels {{{
function handlers.on_rpl_whoischannels(from, nick, channel_list)
    nick = nick:lower()
    if not requestinfo.whois[nick].channels then
        requestinfo.whois[nick].channels = {}
    end
    for _, channel in base.ipairs(misc._split(channel_list)) do
        table.insert(requestinfo.whois[nick].channels, channel)
    end
end
-- }}}

-- on_rpl_whoisserver {{{
function handlers.on_rpl_whoisserver(from, nick, server, serverinfo)
    nick = nick:lower()
    requestinfo.whois[nick].server = server
    requestinfo.whois[nick].serverinfo = serverinfo
end
-- }}}

-- on_rpl_away {{{
function handlers.on_rpl_away(from, nick, away_msg)
    nick = nick:lower()
    if requestinfo.whois[nick] then
        requestinfo.whois[nick].away_msg = away_msg
    end
end
-- }}}

-- on_rpl_whoisoperator {{{
function handlers.on_rpl_whoisoperator(from, nick)
    requestinfo.whois[nick:lower()].is_oper = true
end
-- }}}

-- on_rpl_whoisidle {{{
function handlers.on_rpl_whoisidle(from, nick, idle_seconds)
    requestinfo.whois[nick:lower()].idle_time = idle_seconds
end
-- }}}

-- on_rpl_endofwhois {{{
function handlers.on_rpl_endofwhois(from, nick)
    nick = nick:lower()
    local cb = table.remove(icallbacks.whois[nick], 1)
    cb(requestinfo.whois[nick])
    requestinfo.whois[nick] = nil
    if #icallbacks.whois[nick] > 0 then send("WHOIS", nick)
    else icallbacks.whois[nick] = nil
    end
end
-- }}}

-- on_rpl_version {{{
function handlers.on_rpl_version(from, version, server, comments)
    local cb = table.remove(icallbacks.serverversion[server], 1)
    cb({version = version, server = server, comments = comments})
    if #icallbacks.serverversion[server] > 0 then send("VERSION", server)
    else icallbacks.serverversion[server] = nil
    end
end
-- }}}

-- on_rpl_time {{{
function on_rpl_time(from, server, time)
    local cb = table.remove(icallbacks.servertime[server], 1)
    cb({time = time, server = server})
    if #icallbacks.servertime[server] > 0 then send("TIME", server)
    else icallbacks.servertime[server] = nil
    end
end
-- }}}
-- }}}

-- ctcp handlers {{{
-- requests {{{
-- on_action {{{
function ctcp_handlers.on_action(from, to, message)
    if to:sub(1, 1) == "#" then
        base.assert(serverinfo.channels[to],
                    "Received channel msg from unknown channel: " .. to)
        callback("channel_act", serverinfo.channels[to], from, message)
    else
        callback("private_act", from, message)
    end
end
-- }}}

-- on_dcc {{{
-- TODO: can we not have this handler be registered unless the dcc module is
-- loaded?
function ctcp_handlers.on_dcc(from, to, message)
    local type, argument, address, port, size = base.unpack(misc._split(message, " ", nil, '"', '"'))
    address = misc._ip_int_to_str(address)
    if type == "SEND" then
        if callback("dcc_send", from, to, argument, address, port, size) then
            dcc._accept(argument, address, port)
        end
    elseif type == "CHAT" then
        -- TODO: implement this? do people ever use this?
    end
end
-- }}}

-- on_version {{{
function ctcp_handlers.on_version(from, to)
    notice(from, c("VERSION", _VERSION .. " running under " .. base._VERSION .. " with " .. socket._VERSION))
end
-- }}}

-- on_errmsg {{{
function ctcp_handlers.on_errmsg(from, to, message)
    notice(from, c("ERRMSG", message, ":No error has occurred"))
end
-- }}}

-- on_ping {{{
function ctcp_handlers.on_ping(from, to, timestamp)
    notice(from, c("PING", timestamp))
end
-- }}}

-- on_time {{{
function ctcp_handlers.on_time(from, to)
    notice(from, c("TIME", os.date()))
end
-- }}}
-- }}}

-- responses {{{
-- on_rpl_action {{{
-- actions are handled the same, notice or not
ctcp_handlers.on_rpl_action = ctcp_handlers.on_action
-- }}}

-- on_rpl_version {{{
function ctcp_handlers.on_rpl_version(from, to, version)
    local lfrom = from:lower()
    local cb = table.remove(icallbacks.ctcp_version[lfrom], 1)
    cb({version = version, nick = from})
    if #icallbacks.ctcp_version[lfrom] > 0 then say(from, c("VERSION"))
    else icallbacks.ctcp_version[lfrom] = nil
    end
end
-- }}}

-- on_rpl_errmsg {{{
function ctcp_handlers.on_rpl_errmsg(from, to, message)
    callback("ctcp_error", from, to, message)
end
-- }}}

-- on_rpl_ping {{{
function ctcp_handlers.on_rpl_ping(from, to, timestamp)
    local lfrom = from:lower()
    local cb = table.remove(icallbacks.ctcp_ping[lfrom], 1)
    cb({time = os.time() - timestamp, nick = from})
    if #icallbacks.ctcp_ping[lfrom] > 0 then say(from, c("PING", os.time()))
    else icallbacks.ctcp_ping[lfrom] = nil
    end
end
-- }}}

-- on_rpl_time {{{
function ctcp_handlers.on_rpl_time(from, to, time)
    local lfrom = from:lower()
    local cb = table.remove(icallbacks.ctcp_time[lfrom], 1)
    cb({time = time, nick = from})
    if #icallbacks.ctcp_time[lfrom] > 0 then say(from, c("TIME"))
    else icallbacks.ctcp_time[lfrom] = nil
    end
end
-- }}}
-- }}}
-- }}}
-- }}}

-- module functions {{{
-- socket handling functions {{{
-- _register_socket {{{
--
-- Register a socket to listen on.
-- @param sock LuaSocket socket object
-- @param mode 'r' if the socket is for reading, 'w' if for writing
-- @param cb   Callback to call when the socket is ready for reading/writing.
--             It will be called with the socket as the single argument.
function _register_socket(sock, mode, cb)
    local socks, cbs
    if mode == 'r' then
        socks = rsockets
        cbs = rcallbacks
    else
        socks = wsockets
        cbs = wcallbacks
    end
    base.assert(not cbs[sock], "socket already registered")
    table.insert(socks, sock)
    cbs[sock] = cb
end
-- }}}

-- _unregister_socket {{{
--
-- Remove a previously registered socket.
-- @param sock Socket to unregister
-- @param mode 'r' to unregister it for reading, 'w' for writing
function _unregister_socket(sock, mode)
    local socks, cbs
    if mode == 'r' then
        socks = rsockets
        cbs = rcallbacks
    else
        socks = wsockets
        cbs = wcallbacks
    end
    for i, v in base.ipairs(socks) do
        if v == sock then table.remove(socks, i); break; end
    end
    cbs[sock] = nil
end
-- }}}
-- }}}
-- }}}

-- public functions {{{
-- server commands {{{
-- connect {{{
---
-- Start a connection to the irc server.
-- @param args Table of named arguments containing connection parameters.
--             Defaults are the all-caps versions of these parameters given
--             at the top of the file, and are overridable by setting them
--             as well, i.e. <pre>irc.NETWORK = irc.freenode.net</pre>
--             Possible options are:
--             <ul>
--             <li><i>network:</i>  address of the irc network to connect to
--                                  (default: 'localhost')</li>
--             <li><i>port:</i>     port to connect to
--                                  (default: '6667')</li>
--             <li><i>pass:</i>     irc server password
--                                  (default: don't send)</li>
--             <li><i>nick:</i>     nickname to connect as
--                                  (default: 'luabot')</li>
--             <li><i>username:</i> username to connect with
--                                  (default: 'LuaIRC')</li>
--             <li><i>realname:</i> realname to connect with
--                                  (default: 'LuaIRC')</li>
--             <li><i>timeout:</i>  amount of time in seconds to wait before
--                                  dropping an idle connection
--                                  (default: '60')</li>
--             </ul>
function connect(args)
    local network = args.network or NETWORK
    local port = args.port or PORT
    local nick = args.nick or NICK
    local username = args.username or USERNAME
    local realname = args.realname or REALNAME
    local timeout = args.timeout or TIMEOUT
    serverinfo.connecting = true
    if OUTFILE then irc_debug.set_output(OUTFILE) end
    if DEBUG then irc_debug.enable() end
    irc_sock = base.assert(socket.connect(network, port))
    irc_sock:settimeout(timeout)
    _register_socket(irc_sock, 'r', incoming_message)
    if args.pass then send("PASS", args.pass) end
    send("NICK", nick)
    send("USER", username, get_ip(), network, realname)
    begin_main_loop()
end
-- }}}

-- quit {{{
---
-- Close the connection to the irc server.
-- @param message Quit message (optional, defaults to 'Leaving')
function quit(message)
    message = message or "Leaving"
    send("QUIT", message)
    serverinfo.connected = false
end
-- }}}

-- join {{{
---
-- Join a channel.
-- @param channel Channel to join
function join(channel)
    if not channel then return end
    serverinfo.channels[channel] = Channel.new(channel)
    send("JOIN", channel)
end
-- }}}

-- part {{{
---
-- Leave a channel.
-- @param channel Channel to leave
function part(channel)
    if not channel then return end
    serverinfo.channels[channel] = nil
    send("PART", channel)
end
-- }}}

-- say {{{
---
-- Send a message to a user or channel.
-- @param name User or channel to send the message to
-- @param message Message to send
function say(name, message)
    if not name then return end
    message = message or ""
    send("PRIVMSG", name, message)
end
-- }}}

-- notice {{{
---
-- Send a notice to a user or channel.
-- @param name User or channel to send the notice to
-- @param message Message to send
function notice(name, message)
    if not name then return end
    message = message or ""
    send("NOTICE", name, message)
end
-- }}}

-- act {{{
---
-- Perform a /me action.
-- @param name User or channel to send the action to
-- @param action Action to send
function act(name, action)
    if not name then return end
    action = action or ""
    send("PRIVMSG", name, c("ACTION", action))
end
-- }}}
-- }}}

-- information requests {{{
-- server_version {{{
---
-- Request the version of the IRC server you are currently connected to.
-- @param cb Callback to call when the information is available. The single
--           table parameter to this callback will contain the fields:
--           <ul>
--           <li><i>server:</i>   the server which responded to the request</li>
--           <li><i>version:</i>  the server version</li>
--           <li><i>comments:</i> other data provided by the server</li>
--           </ul>
function server_version(cb)
    -- apparently the optional server parameter isn't supported for servers
    -- which you are not directly connected to (freenode specific?)
    local server = serverinfo.host
    if not icallbacks.serverversion[server] then
        icallbacks.serverversion[server] = {cb}
        send("VERSION", server)
    else
        table.insert(icallbacks.serverversion[server], cb)
    end
end
-- }}}

-- whois {{{
-- TODO: allow server parameter (to get user idle time)
---
-- Request WHOIS information about a given user.
-- @param cb Callback to call when the information is available. The single
--           table parameter to this callback may contain any or all of the
--           fields:
--           <ul>
--           <li><i>nick:</i>       the nick that was passed to this function
--                                  (this field will always be here)</li>
--           <li><i>user:</i>       the IRC username of the user</li>
--           <li><i>host:</i>       the user's hostname</li>
--           <li><i>realname:</i>   the IRC realname of the user</li>
--           <li><i>server:</i>     the IRC server the user is connected to</li>
--           <li><i>serverinfo:</i> arbitrary information about the above
--                                  server</li>
--           <li><i>awaymsg:</i>    set to the user's away message if they are
--                                  away</li>
--           <li><i>is_oper:</i>    true if the user is an IRCop</li>
--           <li><i>idle_time:</i>  amount of time the user has been idle</li>
--           <li><i>channels:</i>   array containing the channels the user has
--                                  joined</li>
--           </ul>
-- @param nick User to request WHOIS information about
function whois(cb, nick)
    nick = nick:lower()
    requestinfo.whois[nick] = {}
    if not icallbacks.whois[nick] then
        icallbacks.whois[nick] = {cb}
        send("WHOIS", nick)
    else
        table.insert(icallbacks.whois[nick], cb)
    end
end
-- }}}

-- server_time {{{
---
-- Request the current time of the server you are connected to.
-- @param cb Callback to call when the information is available. The single
--           table parameter to this callback will contain the fields:
--           <ul>
--           <li><i>server:</i> the server which responded to the request</li>
--           <li><i>time:</i>   the time reported by the server</li>
--           </ul>
function server_time(cb)
    -- apparently the optional server parameter isn't supported for servers
    -- which you are not directly connected to (freenode specific?)
    local server = serverinfo.host
    if not icallbacks.servertime[server] then
        icallbacks.servertime[server] = {cb}
        send("TIME", server)
    else
        table.insert(icallbacks.servertime[server], cb)
    end
end
-- }}}
-- }}}

-- ctcp commands {{{
-- ctcp_ping {{{
---
-- Send a CTCP ping request.
-- @param cb Callback to call when the information is available. The single
--           table parameter to this callback will contain the fields:
--           <ul>
--           <li><i>nick:</i> the nick which responded to the request</li>
--           <li><i>time:</i> the roundtrip ping time, in seconds</li>
--           </ul>
-- @param nick User to ping
function ctcp_ping(cb, nick)
    nick = nick:lower()
    if not icallbacks.ctcp_ping[nick] then
        icallbacks.ctcp_ping[nick] = {cb}
        say(nick, c("PING", os.time()))
    else
        table.insert(icallbacks.ctcp_ping[nick], cb)
    end
end
-- }}}

-- ctcp_time {{{
---
-- Send a localtime request.
-- @param cb Callback to call when the information is available. The single
--           table parameter to this callback will contain the fields:
--           <ul>
--           <li><i>nick:</i> the nick which responded to the request</li>
--           <li><i>time:</i> the localtime reported by the remote client</li>
--           </ul>
-- @param nick User to request the localtime from
function ctcp_time(cb, nick)
    nick = nick:lower()
    if not icallbacks.ctcp_time[nick] then
        icallbacks.ctcp_time[nick] = {cb}
        say(nick, c("TIME"))
    else
        table.insert(icallbacks.ctcp_time[nick], cb)
    end
end
-- }}}

-- ctcp_version {{{
---
-- Send a client version request.
-- @param cb Callback to call when the information is available. The single
--           table parameter to this callback will contain the fields:
--           <ul>
--           <li><i>nick:</i>    the nick which responded to the request</li>
--           <li><i>version:</i> the version reported by the remote client</li>
--           </ul>
-- @param nick User to request the client version from
function ctcp_version(cb, nick)
    nick = nick:lower()
    if not icallbacks.ctcp_version[nick] then
        icallbacks.ctcp_version[nick] = {cb}
        say(nick, c("VERSION"))
    else
        table.insert(icallbacks.ctcp_version[nick], cb)
    end
end
-- }}}
-- }}}

-- callback functions {{{
-- register_callback {{{
---
-- Register a user function to be called when a specific event occurs.
-- @param name Name of the event
-- @param fn   Function to call when the event occurs, or nil to clear the
--             callback for this event
-- @return Value of the original callback for this event (or nil if no previous
--         callback had been set)
function register_callback(name, fn)
    local old_handler = user_handlers[name]
    user_handlers[name] = fn
    return old_handler
end
-- }}}
-- }}}

-- misc functions {{{
-- send {{{
-- TODO: CTCP quoting should be explicit, this table thing is quite ugly (if
-- convenient)
---
-- Send a raw IRC command.
-- @param command String containing the raw IRC command
-- @param ...     Arguments to the command. Each argument is either a string or
--                an array. Strings are sent literally, arrays are CTCP quoted
--                as a group. The last argument (if it exists) is preceded by
--                a : (so it may contain spaces).
function send(command, ...)
    if not serverinfo.connected and not serverinfo.connecting then return end
    local message = command
    for i, v in base.ipairs({...}) do
        if i == #{...} then
            v = ":" .. v
        end
        message = message .. " " .. v
    end
    message = ctcp._low_quote(message)
    -- we just truncate for now. -2 to account for the \r\n
    message = message:sub(1, constants.IRC_MAX_MSG - 2)
    irc_debug._message("SEND", message)
    irc_sock:send(message .. "\r\n")
end
-- }}}

-- get_ip {{{
---
-- Get the local IP address for the server connection.
-- @return A string representation of the local IP address that the IRC server
--         connection is communicating on
function get_ip()
    return (ip or irc_sock:getsockname())
end
-- }}}

-- set_ip {{{
---
-- Set the local IP manually (to allow for NAT workarounds)
-- @param new_ip IP address to set
function set_ip(new_ip)
    ip = new_ip
end
-- }}}

-- channels {{{
-- TODO: @see doesn't currently work for files/modules
---
-- Iterate over currently joined channels.
-- channels() is an iterator function for use in for loops.
-- For example, <pre>for chan in irc.channels() do print(chan:name) end</pre>
-- @see irc.channel
function channels()
    return function(state, arg)
               return misc._value_iter(state, arg,
                                       function(v)
                                           return v.join_complete
                                       end)
           end,
           serverinfo.channels,
           nil
end
-- }}}
-- }}}
-- }}}
