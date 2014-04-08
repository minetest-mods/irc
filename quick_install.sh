#! /bin/sh

scons &&\
ln -s $(pwd)/build/irc $1

