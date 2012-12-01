
# :mode=cmake:noTabs=true:tabSize=4:

set(TO_SOCKET_SHARE
    http.lua
    url.lua
    tp.lua
    ftp.lua
    smtp.lua
)

set(TO_TOP_SHARE
    compat51.lua
    ltn12.lua
    socket.lua
    mime.lua
)

set(LUASOCKET_SRCS
    compat51.c
    luasocket.c
    timeout.c
    buffer.c
    io.c
    auxiliar.c
    options.c
    inet.c
    tcp.c
    udp.c
    except.c
    select.c
    usocket.c
    buffer.c
    auxiliar.c
    options.c
    timeout.c
    io.c
    usocket.c
    unix.c
    mime.c
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_library(luasocket_lib MODULE ${LUASOCKET_SRCS})
set_target_properties(luasocket_lib
    PROPERTIES
    OUTPUT_NAME luasocket
    COMPILE_FLAGS "-Wall -Werror"
)
