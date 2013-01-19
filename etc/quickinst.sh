#! /bin/sh
cd Build \
    && cmake .. \
    && make \
    && make pack_mod \
    && rm -fr ~/.minetest/games/testing/mods/irc \
    && cp -fr irc ~/.minetest/games/testing/mods/
