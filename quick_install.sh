#! /bin/sh

mkdir -p Build &&\
cd Build       &&\
cmake ..       &&\
make           &&\
ln -s $(pwd)/irc $1

