---
-- This module holds various constants used by the IRC protocol.
module "irc.constants"

-- protocol constants {{{
IRC_MAX_MSG = 512
-- }}}

-- server replies {{{
replies = {
-- Command responses {{{
 [001] = "RPL_WELCOME",
 [002] = "RPL_YOURHOST",
 [003] = "RPL_CREATED",
 [004] = "RPL_MYINFO",
 [005] = "RPL_BOUNCE",
 [302] = "RPL_USERHOST",
 [303] = "RPL_ISON",
 [301] = "RPL_AWAY",
 [305] = "RPL_UNAWAY",
 [306] = "RPL_NOWAWAY",
 [311] = "RPL_WHOISUSER",
 [312] = "RPL_WHOISSERVER",
 [313] = "RPL_WHOISOPERATOR",
 [317] = "RPL_WHOISIDLE",
 [318] = "RPL_ENDOFWHOIS",
 [319] = "RPL_WHOISCHANNELS",
 [314] = "RPL_WHOWASUSER",
 [369] = "RPL_ENDOFWHOWAS",
 [321] = "RPL_LISTSTART",
 [322] = "RPL_LIST",
 [323] = "RPL_LISTEND",
 [325] = "RPL_UNIQOPIS",
 [324] = "RPL_CHANNELMODEIS",
 [331] = "RPL_NOTOPIC",
 [332] = "RPL_TOPIC",
 [341] = "RPL_INVITING",
 [342] = "RPL_SUMMONING",
 [346] = "RPL_INVITELIST",
 [347] = "RPL_ENDOFINVITELIST",
 [348] = "RPL_EXCEPTLIST",
 [349] = "RPL_ENDOFEXCEPTLIST",
 [351] = "RPL_VERSION",
 [352] = "RPL_WHOREPLY",
 [315] = "RPL_ENDOFWHO",
 [353] = "RPL_NAMREPLY",
 [366] = "RPL_ENDOFNAMES",
 [364] = "RPL_LINKS",
 [365] = "RPL_ENDOFLINKS",
 [367] = "RPL_BANLIST",
 [368] = "RPL_ENDOFBANLIST",
 [371] = "RPL_INFO",
 [374] = "RPL_ENDOFINFO",
 [375] = "RPL_MOTDSTART",
 [372] = "RPL_MOTD",
 [376] = "RPL_ENDOFMOTD",
 [381] = "RPL_YOUREOPER",
 [382] = "RPL_REHASHING",
 [383] = "RPL_YOURESERVICE",
 [391] = "RPL_TIME",
 [392] = "RPL_USERSSTART",
 [393] = "RPL_USERS",
 [394] = "RPL_ENDOFUSERS",
 [395] = "RPL_NOUSERS",
 [200] = "RPL_TRACELINK",
 [201] = "RPL_TRACECONNECTING",
 [202] = "RPL_TRACEHANDSHAKE",
 [203] = "RPL_TRACEUNKNOWN",
 [204] = "RPL_TRACEOPERATOR",
 [205] = "RPL_TRACEUSER",
 [206] = "RPL_TRACESERVER",
 [207] = "RPL_TRACESERVICE",
 [208] = "RPL_TRACENEWTYPE",
 [209] = "RPL_TRACECLASS",
 [210] = "RPL_TRACERECONNECT",
 [261] = "RPL_TRACELOG",
 [262] = "RPL_TRACEEND",
 [211] = "RPL_STATSLINKINFO",
 [212] = "RPL_STATSCOMMANDS",
 [219] = "RPL_ENDOFSTATS",
 [242] = "RPL_STATSUPTIME",
 [243] = "RPL_STATSOLINE",
 [221] = "RPL_UMODEIS",
 [234] = "RPL_SERVLIST",
 [235] = "RPL_SERVLISTEND",
 [221] = "RPL_UMODEIS",
 [251] = "RPL_LUSERCLIENT",
 [252] = "RPL_LUSEROP",
 [253] = "RPL_LUSERUNKNOWN",
 [254] = "RPL_LUSERCHANNELS",
 [255] = "RPL_LUSERME",
 [256] = "RPL_ADMINME",
 [257] = "RPL_ADMINLOC1",
 [258] = "RPL_ADMINLOC2",
 [259] = "RPL_ADMINEMAIL",
 [263] = "RPL_TRYAGAIN",
-- }}}
-- Error codes {{{
 [401] = "ERR_NOSUCHNICK", -- No such nick/channel
 [402] = "ERR_NOSUCHSERVER", -- No such server
 [403] = "ERR_NOSUCHCHANNEL", -- No such channel
 [404] = "ERR_CANNOTSENDTOCHAN", -- Cannot send to channel
 [405] = "ERR_TOOMANYCHANNELS", -- You have joined too many channels
 [406] = "ERR_WASNOSUCHNICK", -- There was no such nickname
 [407] = "ERR_TOOMANYTARGETS", -- Duplicate recipients. No message delivered
 [408] = "ERR_NOSUCHSERVICE", -- No such service
 [409] = "ERR_NOORIGIN", -- No origin specified
 [411] = "ERR_NORECIPIENT", -- No recipient given
 [412] = "ERR_NOTEXTTOSEND", -- No text to send
 [413] = "ERR_NOTOPLEVEL", -- No toplevel domain specified
 [414] = "ERR_WILDTOPLEVEL", -- Wildcard in toplevel domain
 [415] = "ERR_BADMASK", -- Bad server/host mask
 [421] = "ERR_UNKNOWNCOMMAND", -- Unknown command
 [422] = "ERR_NOMOTD", -- MOTD file is missing
 [423] = "ERR_NOADMININFO", -- No administrative info available
 [424] = "ERR_FILEERROR", -- File error
 [431] = "ERR_NONICKNAMEGIVEN", -- No nickname given
 [432] = "ERR_ERRONEUSNICKNAME", -- Erroneus nickname
 [433] = "ERR_NICKNAMEINUSE", -- Nickname is already in use
 [436] = "ERR_NICKCOLLISION", -- Nickname collision KILL
 [437] = "ERR_UNAVAILRESOURCE", -- Nick/channel is temporarily unavailable
 [441] = "ERR_USERNOTINCHANNEL", -- They aren't on that channel
 [442] = "ERR_NOTONCHANNEL", -- You're not on that channel
 [443] = "ERR_USERONCHANNEL", -- User is already on channel
 [444] = "ERR_NOLOGIN", -- User not logged in
 [445] = "ERR_SUMMONDISABLED", -- SUMMON has been disabled
 [446] = "ERR_USERSDISABLED", -- USERS has been disabled
 [451] = "ERR_NOTREGISTERED", -- You have not registered
 [461] = "ERR_NEEDMOREPARAMS", -- Not enough parameters
 [462] = "ERR_ALREADYREGISTERED", -- You may not reregister
 [463] = "ERR_NOPERMFORHOST", -- Your host isn't among the privileged
 [464] = "ERR_PASSWDMISMATCH", -- Password incorrect
 [465] = "ERR_YOUREBANNEDCREEP", -- You are banned from this server
 [466] = "ERR_YOUWILLBEBANNED",
 [467] = "ERR_KEYSET", -- Channel key already set
 [471] = "ERR_CHANNELISFULL", -- Cannot join channel (+l)
 [472] = "ERR_UNKNOWNMODE", -- Unknown mode char
 [473] = "ERR_INVITEONLYCHAN", -- Cannot join channel (+i)
 [474] = "ERR_BANNEDFROMCHAN", -- Cannot join channel (+b)
 [475] = "ERR_BADCHANNELKEY", -- Cannot join channel (+k)
 [476] = "ERR_BADCHANMASK", -- Bad channel mask
 [477] = "ERR_NOCHANMODES", -- Channel doesn't support modes
 [478] = "ERR_BANLISTFULL", -- Channel list is full
 [481] = "ERR_NOPRIVILEGES", -- Permission denied- You're not an IRC operator
 [482] = "ERR_CHANOPRIVSNEEDED", -- You're not channel operator
 [483] = "ERR_CANTKILLSERVER", -- You can't kill a server!
 [484] = "ERR_RESTRICTED", -- Your connection is restricted!
 [485] = "ERR_UNIQOPPRIVSNEEDED", -- You're not the original channel operator
 [491] = "ERR_NOOPERHOST", -- No O-lines for your host
 [501] = "ERR_UMODEUNKNOWNFLAG", -- Unknown MODE flag
 [502] = "ERR_USERSDONTMATCH", -- Can't change mode for other users
-- }}}
-- unused {{{
 [231] = "RPL_SERVICEINFO",
 [232] = "RPL_ENDOFSERVICES",
 [233] = "RPL_SERVICE",
 [300] = "RPL_NONE",
 [316] = "RPL_WHOISCHANOP",
 [361] = "RPL_KILLDONE",
 [362] = "RPL_CLOSING",
 [363] = "RPL_CLOSEEND",
 [373] = "RPL_INFOSTART",
 [384] = "RPL_MYPORTIS",
 [213] = "RPL_STATSCLINE",
 [214] = "RPL_STATSNLINE",
 [215] = "RPL_STATSILINE",
 [216] = "RPL_STATSKLINE",
 [217] = "RPL_STATSQLINE",
 [218] = "RPL_STATSYLINE",
 [240] = "RPL_STATSVLINE",
 [241] = "RPL_STATSLLINE",
 [244] = "RPL_STATSHLINE",
 [246] = "RPL_STATSPING",
 [247] = "RPL_STATSBLINE",
 [250] = "RPL_STATSDLINE",
 [492] = "ERR_NOSERVICEHOST",
-- }}}
-- guesses {{{
 [333] = "RPL_TOPICDATE", -- date the topic was set, in seconds since the epoch
 [505] = "ERR_NOTREGISTERED" -- freenode blocking privmsg from unreged users
-- }}}
}
-- }}}

-- chanmodes {{{
chanmodes = {
 ["@"] = "secret",
 ["*"] = "private",
 ["="] = "public"
}
-- }}}
