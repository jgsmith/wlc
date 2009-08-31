#!/usr/local/bin/ruby
require "mkmf"

dir_config("lua")

if have_header("lua.h") &&
   have_header("lualib.h") &&
   have_header("lauxlib.h") &&
   have_library("lua", "lua_open") &&
   have_library("lualib", "lua_dostring")
  create_makefile("lua")
end
