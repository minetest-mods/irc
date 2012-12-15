#! /bin/bash

# ONLY FOR MAINTAINER USE!!

t="`pwd`";
cd "`dirname "$0"`/..";
basedir="`pwd`";
cd "$t";

ver=0.1.0;

do_make() # [PLATFORM]
{

    TC_FILE='';
    BLD_SFX='';

    if [ "$1" ]; then
        TC_FILE="-DCMAKE_TOOLCHAIN_FILE=cmake/x-$1.cmake";
        BLD_SFX="-$1";
    fi

    cd "$basedir";
    mkdir -p Build$BLD_SFX;
    cd Build$BLD_SFX;
    cmake $TC_FILE .. || exit;
    make || exit;
    make pack_mod || exit;
    cd ..;

}

mkdir -p "$basedir/dists"

# Native Version
(do_make \
    && cd Build \
    && tar cfz "$basedir/dists/Kaeza-irc-$ver-`uname -s`-`uname -p`.tar.gz" irc \
) || exit;

# Linux -> MinGW32 Crosscompiler
(do_make i586-mingw32msvc \
    && cd Build-i586-mingw32msvc \
    && zip -r "$basedir/dists/Kaeza-irc-$ver-Win32.zip" irc \
) || exit;
