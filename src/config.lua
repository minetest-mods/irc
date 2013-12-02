-- This file is licensed under the terms of the BSD 2-clause license.
-- See LICENSE.txt for details.


local config = {}

-------------------------
-- BASIC USER SETTINGS --
-------------------------

-- Nickname (string, default "minetest-"..<server-id>)
--  (<server-id> is a random string of 6 hexidecimal numbers).
config.nick = minetest.setting_get("irc.nick")

-- Server to connect on joinplayer (string, default "irc.freenode.net")
config.server = minetest.setting_get("irc.server") or "irc.freenode.net"

-- Port to connect on joinplayer (number, default 6667)
config.port = tonumber(minetest.setting_get("irc.port")) or 6667

-- NickServ password
config.NSPass = minetest.setting_get("irc.NSPass")

-- SASL password (Blank to disable SASL authentication)
config.SASLPass = minetest.setting_get("irc.SASLPass")

-- Channel to connect on joinplayer (string, default "##mt-irc-mod")
config.channel = minetest.setting_get("irc.channel") or "##mt-irc-mod"

-- Key for the channel (string, default nil)
config.key = minetest.setting_get("irc.key")


-----------------------
-- ADVANCED SETTINGS --
-----------------------

-- Server password (string, default "")
config.password = minetest.setting_get("irc.password")

-- SASL username
config.SASLUser = minetest.setting_get("irc.SASLUser") or config.nick

-- Enable a TLS connection, requires LuaSEC (bool, default false)
config.secure = minetest.setting_getbool("irc.secure")

-- Time between chat updates in seconds (number, default 2.1). Setting this too low can cause "Excess flood" disconnects.
config.interval = tonumber(minetest.setting_get("irc.interval")) or 2.0

-- Underlying socket timeout in seconds (number, default 60.0).
config.timeout = tonumber(minetest.setting_get("irc.timeout")) or 60.0

-- Prefix to use for bot commands (string)
config.command_prefix = minetest.setting_get("irc.command_prefix")

-- Enable debug output (boolean, default false)
config.debug = minetest.setting_getbool("irc.debug")

-- Whether to enable players joining and parting the channel
config.enable_player_part = not minetest.setting_getbool("irc.disable_player_part")

-- Whether to automatically join the channel when player joins
--  (boolean, default true)
config.auto_join = not minetest.setting_getbool("irc.disable_auto_join")

-- Whether to automatically connect to the server on mod load
--  (boolean, default true)
config.auto_connect = not minetest.setting_getbool("irc.disable_auto_connect")

-- Set default server nick if not specified.
if not config.nick then
	local pr = PseudoRandom(os.time())
	-- Workaround for bad distribution in minetest PRNG implementation.
	config.nick = ("MT-%02X%02X%02X"):format(
		pr:next(0, 255),
		pr:next(0, 255),
		pr:next(0, 255)
	)
end

mt_irc.config = config

