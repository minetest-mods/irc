#! /bin/sh

# ONLY FOR MAINTAINER USE!!

cd "`dirname "$0"`";
dir="`pwd`";
cd ..;

"$dir/zipmod.sh";

echo cp -f dists/* ~/Dropbox/Public/minetest/mods/;
cp -f dists/* ~/Dropbox/Public/minetest/mods/;
