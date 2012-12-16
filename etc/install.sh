#! /bin/sh

# ONLY FOR MAINTAINER USE!!

destdir="$HOME/.minetest/games/testing/mods/irc";

echo rm -fr "\"$destdir\"";
rm -fr "$destdir";

echo cp -fr Build/irc "\"$destdir\"";
cp -fr Build/irc "$destdir";
