#!/usr/bin/env lua

local irc = require 'irc'
irc.DEBUG = true

local nick = "doylua"

local envs = {}

local function create_env()
    return {
        _VERSION =      _VERSION,
        assert =         assert,
        collectgarbage = collectgarbage,
        error =          error,
        getfenv =        getfenv,
        getmetatable =   getmetatable,
        ipairs =         ipairs,
        loadstring =     loadstring,
        next =           next,
        pairs =          pairs,
        pcall =          pcall,
        rawequal =       rawequal,
        rawget =         rawget,
        rawset =         rawset,
        select =         select,
        setfenv =        setfenv,
        setmetatable =   setmetatable,
        tonumber =       tonumber,
        tostring =       tostring,
        type =           type,
        unpack =         unpack,
        xpcall =         xpcall,
        coroutine =      coroutine,
        math =           math,
        string =         string,
        table =          table,
    }
end

local commands = {
    eval = function(target, from, code)
        code = code:gsub("^=", "return ")
        local fn, err = loadstring(code)
        if not fn then
            irc.say(target, from .. ": Error loading code: " .. code .. err:match(".*(:.-)$"))
            return
        else
            setfenv(fn, envs[from])
            local result = {pcall(fn)}
            local success = table.remove(result, 1)
            if not success then
                irc.say(target, from .. ": Error running code: " .. code .. result[1]:match(".*(:.-)$"))
            else
                if result[1] == nil then
                    irc.say(target, from .. ": nil")
                else
                    irc.say(target, from .. ": " .. table.concat(result, ", "))
                end
            end
        end
    end,
    clear = function(target, from)
        irc.say(target, from .. ": Clearing your environment")
        envs[from] = create_env()
    end,
    help = function(target, from, arg)
        if arg == "" or not arg then
            irc.say(target, from .. ": Commands: !clear, !eval, !help")
        elseif arg == "eval" then
            irc.say(target, from .. ": Evaluates a Lua statement in your own persistent environment")
        elseif arg == "clear" then
            irc.say(target, from .. ": Clears your personal environment")
        end
    end
}

irc.register_callback("connect", function()
    irc.join("#doytest")
end)

irc.register_callback("channel_msg", function(channel, from, message)
    message = message:gsub("^" .. nick .. "[:,>] ", "!eval ")
    local is_cmd, cmd, arg = message:match("^(!)([%w_]+) ?(.-)$")
    if is_cmd and commands[cmd] then
        envs[from] = envs[from] or create_env()
        commands[cmd](channel.name, from, arg)
    end
end)

irc.register_callback("private_msg", function(from, message)
    message = message:gsub("^" .. nick .. "[:,>] ", "!eval ")
    local is_cmd, cmd, arg = message:match("^(!)([%w_]+) ?(.-)$")
    envs[from] = envs[from] or create_env()
    if is_cmd and commands[cmd] then
        commands[cmd](from, from, arg)
    else
        commands["eval"](from, from, message)
    end
end)

irc.register_callback("nick_change", function(from, old_nick)
    if envs[old_nick] and not envs[from] then
        envs[from] = envs[old_nick]
        envs[old_nick] = nil
    end
end)

irc.connect{network = "irc.freenode.net", nick = nick, pass = "doylua"}
