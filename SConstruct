
vars = Variables(None, ARGUMENTS)

vars.AddVariables(
	PathVariable("prefix", "Installation prefix", "build",
			PathVariable.PathIsDirCreate)
)

env = Environment(variables = vars)

Help(vars.GenerateHelpText(env))

env.VariantDir("$prefix", "src", 0)

lua_srcs = Split("""
	$prefix/lua/lapi.c
	$prefix/lua/lcode.c
	$prefix/lua/ldebug.c
	$prefix/lua/ldo.c
	$prefix/lua/ldump.c
	$prefix/lua/lfunc.c
	$prefix/lua/lgc.c
	$prefix/lua/llex.c
	$prefix/lua/lmem.c
	$prefix/lua/lobject.c
	$prefix/lua/lopcodes.c
	$prefix/lua/lparser.c
	$prefix/lua/lstate.c
	$prefix/lua/lstring.c
	$prefix/lua/ltable.c
	$prefix/lua/ltm.c
	$prefix/lua/lundump.c
	$prefix/lua/lvm.c
	$prefix/lua/lzio.c
	$prefix/lua/lauxlib.c
	$prefix/lua/lbaselib.c
	$prefix/lua/ldblib.c
	$prefix/lua/liolib.c
	$prefix/lua/lmathlib.c
	$prefix/lua/loslib.c
	$prefix/lua/ltablib.c
	$prefix/lua/lstrlib.c
	$prefix/lua/loadlib.c
	$prefix/lua/linit.c
""")

luasocket_srcs = Split("""
	$prefix/luasocket/compat51.c
	$prefix/luasocket/luasocket.c
	$prefix/luasocket/timeout.c
	$prefix/luasocket/buffer.c
	$prefix/luasocket/io.c
	$prefix/luasocket/auxiliar.c
	$prefix/luasocket/options.c
	$prefix/luasocket/inet.c
	$prefix/luasocket/tcp.c
	$prefix/luasocket/udp.c
	$prefix/luasocket/except.c
	$prefix/luasocket/select.c
	$prefix/luasocket/mime.c
""")

luasocket_libs = []
env.MergeFlags("-Wall -Werror")

if env["PLATFORM"] == "win32":
	luasocket_srcs += ["$prefix/luasocket/wsocket.c"]
	luasocket_libs += ["wininet", "ws2_32"]
	if "mingw" in env['CC']:
		# The '-fPIC' flag generates a warning on MinGW32, which combined
		#  with '-Werror' makes that an error though '-fPIC' is ignored.
		#  We use '-fno-PIC' to avoid that.
		env.MergeFlags("-fno-PIC")
else:
	luasocket_srcs += ["$prefix/luasocket/usocket.c",
			"$prefix/luasocket/unix.c"]


luasocket_out = env.LoadableModule(
	target = "$prefix/luasocket",
	source = luasocket_srcs + lua_srcs,
	LIBS = luasocket_libs,
	CPPPATH = ["src/luasocket/", "src/lua/"]
)


env.InstallAs("$prefix/irc/irc", "src/LuaIRC")
env.Install("$prefix/irc", Glob("src/luasocket/*.lua"))
env.Install("$prefix/irc", Glob("src/*.lua"))
env.Install("$prefix/irc", Glob("src/*.txt"))
env.Install("$prefix/irc", "README.txt")
env.Install("$prefix/irc", luasocket_out)

env.Alias("pack", "$prefix/irc")
env.Clean("pack", "$prefix/irc")

