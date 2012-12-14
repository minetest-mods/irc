#! /bin/bash

# ONLY FOR MAINTAINER USE!!

ver=0.1.0;

do_make() # [PLATFORM]
{

    TC_FILE='';
    BLD_SFX='';

    if [ "$1" ]; then
        TC_FILE="-DCMAKE_TOOLCHAIN_FILE=cmake/x-$1.cmake";
        BLD_SFX="-$1";
    fi

    mkdir -p Build$BLD_SFX;
    cd Build$BLD_SFX;
    cmake $TC_FILE .. || exit;
    make || exit;
    make pack_mod || exit;
    cd ..;

}

cd "`dirname "$0"`/..";

rm -fr irc;

# Native Version
do_make;
tar cfz Kaeza-irc-$ver-`uname -s`-`uname -p`.tar.gz irc || exit;
rm -fr irc;

# Linux -> MinGW32 Crosscompiler
do_make i586-mingw32msvc;
zip -r Kaeza-irc-$ver-Win32.zip irc || exit;
rm -fr irc;
