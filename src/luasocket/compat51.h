/*
** Compat-5.1
** Copyright Kepler Project 2004-2005 (http://www.keplerproject.org/compat/)
** $Id: compat-5.1.h,v 1.7 2005/07/08 18:25:52 carregal Exp $
*/

#ifndef COMPAT_H

LUALIB_API void luaL_module(lua_State *L, const char *libname,
                                       const luaL_reg *l, int nup);
#define luaL_openlib luaL_module

#endif
