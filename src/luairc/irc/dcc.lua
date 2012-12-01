---
-- Implementation of the DCC protocol
-- initialization {{{
local base =      _G
local irc =       require 'irc'
local ctcp =      require 'irc.ctcp'
local c =         ctcp._ctcp_quote
local irc_debug = require 'irc.debug'
local misc =      require 'irc.misc'
local socket =    require 'socket'
local coroutine = require 'coroutine'
local io =        require 'io'
local string =    require 'string'
-- }}}

---
-- This module implements the DCC protocol. File transfers (DCC SEND) are
-- handled, but DCC CHAT is not, as of yet.
module 'irc.dcc'

-- defaults {{{
FIRST_PORT = 1028
LAST_PORT = 5000
-- }}}

-- private functions {{{
-- debug_dcc {{{
--
-- Prints a debug message about DCC events similar to irc.debug.warn, etc.
-- @param msg Debug message
local function debug_dcc(msg)
    irc_debug._message("DCC", msg, "\027[0;32m")
end
-- }}}

-- send_file {{{
--
-- Sends a file to a remote user, after that user has accepted our DCC SEND
-- invitation
-- @param sock        Socket to send the file on
-- @param file        Lua file object corresponding to the file we want to send
-- @param packet_size Size of the packets to send the file in
local function send_file(sock, file, packet_size)
    local bytes = 0
    while true do
        local packet = file:read(packet_size)
        if not packet then break end
        bytes = bytes + packet:len()
        local index = 1
        while true do
            local skip = false
            sock:send(packet, index)
            local new_bytes, err = sock:receive(4)
            if not new_bytes then
                if err == "timeout" then
                    skip = true
                else
                    irc_debug._warn(err)
                    break
                end
            else
                new_bytes = misc._int_to_str(new_bytes)
            end
            if not skip then
                if new_bytes ~= bytes then
                    index = packet_size - bytes + new_bytes + 1
                else
                    break
                end
            end
        end
        coroutine.yield(true)
    end
    debug_dcc("File completely sent")
    file:close()
    sock:close()
    irc._unregister_socket(sock, 'w')
    return true
end
-- }}}

-- handle_connect {{{
--
-- Handle the connection attempt by a remote user to get our file. Basically
-- just swaps out the server socket we were listening on for a client socket
-- that we can send data on
-- @param ssock Server socket that the remote user connected to
-- @param file  Lua file object corresponding to the file we want to send
-- @param packet_size Size of the packets to send the file in
local function handle_connect(ssock, file, packet_size)
    debug_dcc("Offer accepted, beginning to send")
    packet_size = packet_size or 1024
    local sock = ssock:accept()
    sock:settimeout(0.1)
    ssock:close()
    irc._unregister_socket(ssock, 'r')
    irc._register_socket(sock, 'w',
                         coroutine.wrap(function(s)
                             return send_file(s, file, packet_size)
                         end))
    return true
end
-- }}}

-- accept_file {{{
--
-- Accepts a file from a remote user which has offered it to us.
-- @param sock        Socket to receive the file on
-- @param file        Lua file object corresponding to the file we want to save
-- @param packet_size Size of the packets to receive the file in
local function accept_file(sock, file, packet_size)
    local bytes = 0
    while true do
        local packet, err, partial_packet = sock:receive(packet_size)
        if not packet and err == "timeout" then packet = partial_packet end
        if not packet then break end
        if packet:len() == 0 then break end
        bytes = bytes + packet:len()
        sock:send(misc._str_to_int(bytes))
        file:write(packet)
        coroutine.yield(true)
    end
    debug_dcc("File completely received")
    file:close()
    sock:close()
    irc._unregister_socket(sock, 'r')
    return true
end
-- }}}
-- }}}

-- internal functions {{{
-- _accept {{{
--
-- Accepts a file offer from a remote user. Called when the on_dcc callback
-- retuns true.
-- @param filename    Name to save the file as
-- @param address     IP address of the remote user in low level int form
-- @param port        Port to connect to at the remote user
-- @param packet_size Size of the packets the remote user will be sending
function _accept(filename, address, port, packet_size)
    debug_dcc("Accepting a DCC SEND request from " ..  address .. ":" .. port)
    packet_size = packet_size or 1024
    local sock = base.assert(socket.tcp())
    base.assert(sock:connect(address, port))
    sock:settimeout(0.1)
    local file = base.assert(io.open(misc._get_unique_filename(filename), "w"))
    irc._register_socket(sock, 'r',
                         coroutine.wrap(function(s)
                             return accept_file(s, file, packet_size)
                         end))
end
-- }}}
-- }}}

-- public functions {{{
-- send {{{
---
-- Offers a file to a remote user.
-- @param nick     User to offer the file to
-- @param filename Filename to offer
-- @param port     Port to accept connections on (optional, defaults to
--                 choosing an available port between FIRST_PORT and LAST_PORT
--                 above)
function send(nick, filename, port)
    port = port or FIRST_PORT
    local sock
    repeat
        sock = base.assert(socket.tcp())
        err, msg = sock:bind('*', port)
        port = port + 1
    until msg ~= "address already in use" and port <= LAST_PORT + 1
    port = port - 1
    base.assert(err, msg)
    base.assert(sock:listen(1))
    local ip = misc._ip_str_to_int(irc.get_ip())
    local file, err = io.open(filename)
    if not file then
        irc_debug._warn(err)
        sock:close()
        return
    end
    local size = file:seek("end")
    file:seek("set")
    irc._register_socket(sock, 'r',
                         coroutine.wrap(function(s)
                             return handle_connect(s, file)
                         end))
    filename = misc._basename(filename)
    if filename:find(" ") then filename = '"' .. filename .. '"' end
    debug_dcc("Offering " .. filename .. " to " .. nick .. " from " ..
              irc.get_ip() .. ":" .. port)
    irc.send("PRIVMSG", nick, c("DCC", "SEND", filename, ip, port, size))
end
-- }}}
-- }}}
