#! /bin/sh

mkdir -p Build  \
&& cd Build     \
&& cmake ..     \
&& make         \
&& cd ..        \
&& cp -r Build/irc $1
