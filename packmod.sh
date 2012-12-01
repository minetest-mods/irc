#! /bin/sh

echo "Detecting directories...";
if [ -f "CMakeLists.txt" ]; then
    srcdir=".";
    bindir="Build";
elif [ -f "../CMakeLists.txt" ]; then
    srcdir="..";
    bindir=".";
else
    echo "Error: Couldn't find CMakeLists.txt." >&2;
    exit 1;
fi

if [ -e "$bindir/src/luasocket/libluasocket.dll" ]; then
    lib="$bindir/src/luasocket/libluasocket.dll;
elif [ -e "$bindir/src/luasocket/libluasocket.so" ]; then
    lib="$bindir/src/luasocket/libluasocket.so;
else
    echo "Error: Couldn't find luasocket lib." >&2;
    echo "       Did you compile before running this script?" >&2;
    exit 1;
fi

version="`cat "$srcdir/CMakeLists.txt" \
    | grep 'MINETEST_IRC_VERSION' \
    | sed -e 's/^set(MINETEST_IRC_VERSION \([^)]*\)/\1/'`";

mkdir "$srcdir/irc-$version";

files_luairc="\
$srcdir/src/luairc/irc.lua
$srcdir/src/luairc/irc/channel.lua
$srcdir/src/luairc/irc/constants.lua
$srcdir/src/luairc/irc/ctcp.lua
$srcdir/src/luairc/irc/dcc.lua
$srcdir/src/luairc/irc/debug.lua
$srcdir/src/luairc/irc/message.lua
$srcdir/src/luairc/irc/misc.lua
";

files_luasocket="\
$srcdir/src/luasocket/ftp.lua
$srcdir/src/luasocket/http.lua
$srcdir/src/luasocket/ltn12.lua
$srcdir/src/luasocket/mime.lua
$srcdir/src/luasocket/smtp.lua
$srcdir/src/luasocket/socket.lua
$srcdir/src/luasocket/tp.lua
$srcdir/src/luasocket/url.lua
$lib
";

files="\
$srcdir/src/init.lua
$files_luairc
$files_luasocket
";

oIFS="$IFS";
IFS='
';

echo "Copying files...";
for file in $files; do
    IFS="$oIFS";
    cp "$file" "$srcdir/irc-$version/";
done

echo "Operation completed successfully!";
exit 0;
