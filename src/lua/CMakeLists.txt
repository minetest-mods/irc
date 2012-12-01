
# :mode=cmake:noTabs=true:tabSize=4:

set(LUA_SRCS
    lapi.c lcode.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c
    lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c
    lundump.c lvm.c lzio.c
    lauxlib.c lbaselib.c ldblib.c liolib.c lmathlib.c loslib.c ltablib.c
    lstrlib.c loadlib.c linit.c
)

add_library(lua_lib ${LUA_SRCS})
set_target_properties(lua_lib
    PROPERTIES
    OUTPUT_NAME lua51-minetest-irc
)
