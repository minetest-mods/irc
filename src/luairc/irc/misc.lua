---
-- Various useful functions that didn't fit anywhere else
-- initialization {{{
local base =      _G
local irc_debug = require 'irc.debug'
local socket =    require 'socket'
local math =      require 'math'
local os =        require 'os'
local string =    require 'string'
local table =     require 'table'
-- }}}

---
-- This module contains various useful functions which didn't fit in any of the
-- other modules.
module 'irc.misc'

-- defaults {{{
DELIM = ' '
PATH_SEP = '/'
ENDIANNESS = "big"
INT_BYTES = 4
-- }}}

-- private functions {{{
--
-- Check for existence of a file. This returns true if renaming a file to
-- itself succeeds. This isn't ideal (I think anyway) but it works here, and
-- lets me not have to bring in LFS as a dependency.
-- @param filename File to check for existence
-- @return True if the file exists, false otherwise
local function exists(filename)
    local _, err = os.rename(filename, filename)
    if not err then return true end
    return not err:find("No such file or directory")
end
-- }}}

-- internal functions {{{
-- _split {{{
--
-- Splits str into substrings based on several options.
-- @param str String to split
-- @param delim String of characters to use as the beginning of substring
--              delimiter
-- @param end_delim String of characters to use as the end of substring
--                  delimiter
-- @param lquotes String of characters to use as opening quotes (quoted strings
--                in str will be considered one substring)
-- @param rquotes String of characters to use as closing quotes
-- @return Array of strings, one for each substring that was separated out
function _split(str, delim, end_delim, lquotes, rquotes)
    -- handle arguments {{{
    delim = "["..(delim or DELIM).."]"
    if end_delim then end_delim = "["..end_delim.."]" end
    if lquotes then lquotes = "["..lquotes.."]" end
    if rquotes then rquotes = "["..rquotes.."]" end
    local optdelim = delim .. "?"
    -- }}}

    local ret = {}
    local instring = false
    while str:len() > 0 do
        -- handle case for not currently in a string {{{
        if not instring then
            local end_delim_ind, lquote_ind, delim_ind
            if end_delim then end_delim_ind = str:find(optdelim..end_delim) end
            if lquotes then lquote_ind = str:find(optdelim..lquotes) end
            local delim_ind = str:find(delim)
            if not end_delim_ind then end_delim_ind = str:len() + 1 end
            if not lquote_ind then lquote_ind = str:len() + 1 end
            if not delim_ind then delim_ind = str:len() + 1 end
            local next_ind = math.min(end_delim_ind, lquote_ind, delim_ind)
            if next_ind == str:len() + 1 then
                table.insert(ret, str)
                break
            elseif next_ind == end_delim_ind then
                -- TODO: hackish here
                if str:sub(next_ind, next_ind) == end_delim:gsub('[%[%]]', '') then
                    table.insert(ret, str:sub(next_ind + 1))
                else
                    table.insert(ret, str:sub(1, next_ind - 1))
                    table.insert(ret, str:sub(next_ind + 2))
                end
                break
            elseif next_ind == lquote_ind then
                table.insert(ret, str:sub(1, next_ind - 1))
                str = str:sub(next_ind + 2)
                instring = true
            else -- last because the top two contain it
                table.insert(ret, str:sub(1, next_ind - 1))
                str = str:sub(next_ind + 1)
            end
        -- }}}
        -- handle case for currently in a string {{{
        else
            local endstr = str:find(rquotes..optdelim)
            table.insert(ret, str:sub(1, endstr - 1))
            str = str:sub(endstr + 2)
            instring = false
        end
        -- }}}
    end
    return ret
end
-- }}}

-- _basename {{{
--
-- Returns the basename of a file (the part after the last directory separator).
-- @param path Path to the file
-- @param sep Directory separator (optional, defaults to PATH_SEP)
-- @return The basename of the file
function _basename(path, sep)
    sep = sep or PATH_SEP
    if not path:find(sep) then return path end
    return socket.skip(2, path:find(".*" .. sep .. "(.*)"))
end
-- }}}

-- _dirname {{{
--
-- Returns the dirname of a file (the part before the last directory separator).
-- @param path Path to the file
-- @param sep Directory separator (optional, defaults to PATH_SEP)
-- @return The dirname of the file
function _dirname(path, sep)
    sep = sep or PATH_SEP
    if not path:find(sep) then return "." end
    return socket.skip(2, path:find("(.*)" .. sep .. ".*"))
end
-- }}}

-- _str_to_int {{{
--
-- Converts a number to a low-level int.
-- @param str String representation of the int
-- @param bytes Number of bytes in an int (defaults to INT_BYTES)
-- @param endian Which endianness to use (big, little, host, network) (defaultsi
--               to ENDIANNESS)
-- @return A string whose first INT_BYTES characters make a low-level int
function _str_to_int(str, bytes, endian)
    bytes = bytes or INT_BYTES
    endian = endian or ENDIANNESS
    local ret = ""
    for i = 0, bytes - 1 do 
        local new_byte = string.char(math.fmod(str / (2^(8 * i)), 256))
        if endian == "big" or endian == "network" then ret = new_byte .. ret
        else ret = ret .. new_byte
        end
    end
    return ret
end
-- }}}

-- _int_to_str {{{
--
-- Converts a low-level int to a number.
-- @param int String whose bytes correspond to the bytes of a low-level int
-- @param endian Endianness of the int argument (defaults to ENDIANNESS)
-- @return String representation of the low-level int argument
function _int_to_str(int, endian)
    endian = endian or ENDIANNESS
    local ret = 0
    for i = 1, int:len() do
        if endian == "big" or endian == "network" then ind = int:len() - i + 1
        else ind = i
        end
        ret = ret + string.byte(int:sub(ind, ind)) * 2^(8 * (i - 1))
    end
    return ret
end
-- }}}

-- _ip_str_to_int {{{
-- TODO: handle endianness here
--
-- Converts a string IP address to a low-level int.
-- @param ip_str String representation of an IP address
-- @return Low-level int representation of that IP address
function _ip_str_to_int(ip_str)
    local i = 3
    local ret = 0
    for num in ip_str:gmatch("%d+") do
        ret = ret + num * 2^(i * 8)                  
        i = i - 1
    end
    return ret
end
-- }}}

-- _ip_int_to_str {{{
-- TODO: handle endianness here
--
-- Converts an int to a string IP address.
-- @param ip_int Low-level int representation of an IP address
-- @return String representation of that IP address
function _ip_int_to_str(ip_int)
    local ip = {}
    for i = 3, 0, -1 do
        local new_num = math.floor(ip_int / 2^(i * 8))
        table.insert(ip, new_num)
        ip_int = ip_int - new_num * 2^(i * 8)
    end 
    return table.concat(ip, ".")
end
-- }}}

-- _get_unique_filename {{{
--
-- Returns a unique filename.
-- @param filename Filename to start with
-- @return Filename (same as the one we started with, except possibly with some
--         numbers appended) which does not currently exist on the filesystem
function _get_unique_filename(filename)
    if not exists(filename) then return filename end

    local count = 1
    while true do
        if not exists(filename .. "." .. count) then
            return filename .. "." .. count
        end
        count = count + 1
    end
end
-- }}}

-- _try_call {{{
--
-- Call a function, if it exists.
-- @param fn Function to try to call
-- @param ... Arguments to fn
-- @return The return values of fn, if it was successfully called
function _try_call(fn, ...)
    if base.type(fn) == "function" then
        return fn(...)
    end
end
-- }}}

-- _try_call_warn {{{
--
-- Same as try_call, but complain if the function doesn't exist.
-- @param msg Warning message to use if the function doesn't exist
-- @param fn Function to try to call
-- @param ... Arguments to fn
-- @return The return values of fn, if it was successfully called
function _try_call_warn(msg, fn, ...)
    if base.type(fn) == "function" then
        return fn(...)
    else
        irc_debug._warn(msg)
    end
end
-- }}}

-- _value_iter {{{
--
-- Iterator to iterate over just the values of a table.
function _value_iter(state, arg, pred)
    for k, v in base.pairs(state) do
        if arg == v then arg = k end
    end
    local key, val = base.next(state, arg)
    if not key then return end

    if base.type(pred) == "function" then
        while not pred(val) do
            key, val = base.next(state, key)
            if not key then return end
        end
    end
    return val
end
-- }}}

-- _parse_user {{{
--
-- Gets the various parts of a full username.
-- @param user A usermask (i.e. returned in the from field of a callback)
-- @return nick
-- @return username (if it exists)
-- @return hostname (if it exists)
function _parse_user(user)
    local found, bang, nick = user:find("^([^!]*)!")
    if found then
        user = user:sub(bang + 1)
    else
        return user
    end
    local found, equals = user:find("^.=")
    if found then
        user = user:sub(3)
    end
    local found, at, username = user:find("^([^@]*)@")
    if found then
        return nick, username, user:sub(at + 1)
    else
        return nick, user
    end
end
-- }}}
-- }}}
