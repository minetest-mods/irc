-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


mt_irc.config = {}

local function setting(stype, name, default)
	local value
	if stype == "bool" then
		value = minetest.setting_getbool("irc."..name)
	elseif stype == "string" then
		value = minetest.setting_get("irc."..name)
	elseif stype == "number" then
		value = tonumber(minetest.setting_get("irc."..name))
	end
	if value == nil then
		value = default
	end
	mt_irc.config[name] = value
end

-------------------------
-- BASIC USER SETTINGS --
-------------------------

setting("string", "nick") -- Nickname (default "MT-<hash>", <hash> 6 random hexidecimal characters)
setting("string", "server", "irc.freenode.net") -- Server to connect on joinplayer
setting("number", "port", 6667) -- Port to connect on joinplayer
setting("string", "NSPass") -- NickServ password
setting("string", "SASLUser", mt_irc.config.nick) -- SASL username
setting("string", "SASLPass") -- SASL password
setting("string", "channel", "##mt-irc-mod") -- Channel to join
setting("string", "key") -- Key for the channel

-----------------------
-- ADVANCED SETTINGS --
-----------------------

setting("string", "password") -- Server password
setting("bool",   "secure", false) -- Enable a TLS connection, requires LuaSEC
setting("number", "interval", 2) -- Time between chat updates in seconds. Setting this too low can cause "Excess flood" disconnects.
setting("number", "timeout", 60) -- Underlying socket timeout in seconds.
setting("string", "command_prefix") -- Prefix to use for bot commands
setting("bool",   "debug", false) -- Enable debug output
setting("bool",   "enable_player_part", true) -- Whether to enable players joining and parting the channel
setting("bool",   "auto_join", true) -- Whether to automatically show players in the channel when they join
setting("bool",   "auto_connect", true) -- Whether to automatically connect to the server on mod load

-- Generate a random nickname if one isn't specified.
if not mt_irc.config.nick then
	local pr = PseudoRandom(os.time())
	-- Workaround for bad distribution in minetest PRNG implementation.
	mt_irc.config.nick = ("MT-%02X%02X%02X"):format(
		pr:next(0, 255),
		pr:next(0, 255),
		pr:next(0, 255)
	)
end

