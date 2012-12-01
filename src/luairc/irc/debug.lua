---
-- Basic debug output
-- initialization {{{
local base = _G
local io =   require 'io'
-- }}}

---
-- This module implements a few useful debug functions for use throughout the
-- rest of the code.
module 'irc.debug'

-- defaults {{{
COLOR = true
-- }}}

-- local variables {{{
local ON = false
local outfile = io.output()
-- }}}

-- internal functions {{{
-- _message {{{
--
-- Output a debug message.
-- @param msg_type Arbitrary string corresponding to the type of message
-- @param msg      Message text
-- @param color    Which terminal code to use for color output (defaults to
--                 dark gray)
function _message(msg_type, msg, color)
    if ON then
        local endcolor = ""
        if COLOR and outfile == io.stdout then
            color = color or "\027[1;30m"
            endcolor = "\027[0m"
        else
            color = ""
            endcolor = ""
        end
        outfile:write(color .. msg_type .. ": " .. msg .. endcolor .. "\n")
    end
end
-- }}}

-- _err {{{
--
-- Signal an error. Writes the error message to the screen in red and calls
-- error().
-- @param msg Error message
-- @see error
function _err(msg)
    _message("ERR", msg, "\027[0;31m")
    base.error(msg, 2)
end
-- }}}

-- _warn {{{
--
-- Signal a warning. Writes the warning message to the screen in yellow.
-- @param msg Warning message
function _warn(msg)
    _message("WARN", msg, "\027[0;33m")
end
-- }}}
-- }}}

-- public functions {{{
-- enable {{{
---
-- Turns on debug output.
function enable()
    ON = true
end
-- }}}

-- disable {{{
---
-- Turns off debug output.
function disable()
    ON = false
end
-- }}}

-- set_output {{{
---
-- Redirects output to a file rather than stdout.
-- @param file File to write debug output to
function set_output(file)
    outfile = base.assert(io.open(file))
end
-- }}}
-- }}}
