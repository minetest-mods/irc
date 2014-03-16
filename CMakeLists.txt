
# :mode=cmake:

cmake_minimum_required(VERSION 2.8)

project(MINETEST_IRC C)

# Also update init.lua
set(MINETEST_IRC_VERSION 0.2.0)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(LUA_SRCS
	src/lua/lapi.c
	src/lua/lcode.c
	src/lua/ldebug.c
	src/lua/ldo.c
	src/lua/ldump.c
	src/lua/lfunc.c
	src/lua/lgc.c
	src/lua/llex.c
	src/lua/lmem.c
	src/lua/lobject.c
	src/lua/lopcodes.c
	src/lua/lparser.c
	src/lua/lstate.c
	src/lua/lstring.c
	src/lua/ltable.c
	src/lua/ltm.c
	src/lua/lundump.c
	src/lua/lvm.c
	src/lua/lzio.c
	src/lua/lauxlib.c
	src/lua/lbaselib.c
	src/lua/ldblib.c
	src/lua/liolib.c
	src/lua/lmathlib.c
	src/lua/loslib.c
	src/lua/ltablib.c
	src/lua/lstrlib.c
	src/lua/loadlib.c
	src/lua/linit.c
)

set(LUASOCKET_SRCS
	src/luasocket/compat51.c
	src/luasocket/luasocket.c
	src/luasocket/timeout.c
	src/luasocket/buffer.c
	src/luasocket/io.c
	src/luasocket/auxiliar.c
	src/luasocket/options.c
	src/luasocket/inet.c
	src/luasocket/tcp.c
	src/luasocket/udp.c
	src/luasocket/except.c
	src/luasocket/select.c
	src/luasocket/mime.c
)

if(WIN32)
	list(APPEND LUASOCKET_SRCS src/luasocket/wsocket.c)
	set(LUASOCKET_EXTRA_LIBS -lwininet)
else()
	list(APPEND LUASOCKET_SRCS src/luasocket/usocket.c src/luasocket/unix.c)
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/lua)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/luasocket)

add_library(luasocket_lib MODULE ${LUASOCKET_SRCS} ${LUA_SRCS})

set_target_properties(luasocket_lib PROPERTIES
	OUTPUT_NAME luasocket)

if(WIN32)
	# When using MinGW32, CMake prefixes DLLs with "lib". Force remove
	#  this prefix regardless of compiler.
	set_target_properties(luasocket_lib PROPERTIES
		PREFIX "")
	if (NOT MSVC) # GCC?
		# The `-fPIC' flag generates a warning on MinGW32, which combined
		#  with `-Werror' makes that an error though `-fPIC' is ignored.
		#  We use `-fno-PIC' to avoid that.
		set_target_properties(luasocket_lib PROPERTIES
			COMPILE_FLAGS "-fno-PIC -Wall -Werror")
	endif()
	find_library(ws2_32_lib NAMES ws2_32)
	target_link_libraries(luasocket_lib ${ws2_32_lib})
else() # Possibly Unix
	set_target_properties(luasocket_lib PROPERTIES
		COMPILE_FLAGS "-Wall -Werror")
endif()

set(dir ${CMAKE_CURRENT_BINARY_DIR}/irc/)

if(WIN32)
	set(lib "${CMAKE_CURRENT_BINARY_DIR}/luasocket.dll")
else()
	set(lib "${CMAKE_CURRENT_BINARY_DIR}/libluasocket.so")
endif()

add_custom_target(pack_mod ALL
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}

	# LuaIRC
	COMMAND ${CMAKE_COMMAND} -E make_directory ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy_directory src/LuaIRC ${dir}/irc

	# luasocket
	COMMAND ${CMAKE_COMMAND} -E make_directory ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/ftp.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/http.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/ltn12.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/mime.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/smtp.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/socket.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/tp.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/url.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/luasocket/LICENSE.txt ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy ${lib} ${dir}

	# IRC mod
	COMMAND ${CMAKE_COMMAND} -E make_directory ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/init.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/hooks.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/messages.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/config.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/callback.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/chatcmds.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/botcmds.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/player_part.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/util.lua ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy README.txt ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/API.txt ${dir}
	COMMAND ${CMAKE_COMMAND} -E copy src/LICENSE.txt ${dir}
)

