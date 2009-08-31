/* $Id: lua.c,v 1.15 2001/09/29 23:35:53 mingo Exp $ */
#include <ruby.h> 
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/*#define DEBUG_STACK 1*/

#ifdef DEBUG_STACK
    #define debug_stack(s) fprintf(stderr,"Stack top %s = %d\n", s, lua_gettop(L));
#else
    #define debug_stack(s)

#endif


int FLAGS[] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  1, 0,10, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 1, 1, 0,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 6, 0, 6, 0,
  0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
  0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

int HEXR[] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  1, 2, 3, 4, 5, 6, 7, 8, 9,10, 0, 0, 0, 0, 0, 0,
  0,11,12,13,14,15,16, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0,11,12,13,14,15,16, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

unsigned char HEX[] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

static ID keys_id;

static int call_ruby_function(lua_State *L);

static int escape_url(lua_State *L);
static int escape_html(lua_State *L);


static void rbLua_free(void *p){
  lua_close(p);
}

static VALUE rbLua_new(int argc, VALUE *argv , VALUE class){
  VALUE largv[1], tdata,args, arg;
  lua_State *L;
  int i, len, stack = 1024;
  if(rb_scan_args(argc,argv,"*",&args) >= 1){
    len = RARRAY(args)->len;
    i = 0;
    arg = RARRAY(args)->ptr[i];
    /* first argument if it's a number is the stack value */

    if(TYPE(arg) == T_FIXNUM){
      stack = FIX2INT(arg);
      i++;
    }
    L = lua_open();
    /* we expect strings describing libraries to enable*/
    for(;i < len; i++){
      arg = RARRAY(args)->ptr[i];
      Check_Type(arg, T_STRING);
      if(strcmp(STR2CSTR(arg), "baselib") == 0) lua_baselibopen(L);
      if(strcmp(STR2CSTR(arg), "strlib") == 0) lua_strlibopen(L);
      if(strcmp(STR2CSTR(arg), "mathlib") == 0) lua_mathlibopen(L);
      if(strcmp(STR2CSTR(arg), "iolib") == 0) lua_iolibopen(L);
      if(strcmp(STR2CSTR(arg), "dblib") == 0) lua_dblibopen(L);
    }
  } else {
    L = lua_open();
    lua_baselibopen(L);
    lua_tablibopen(L);
    lua_strlibopen(L);
    lua_mathlibopen(L);
  }

  /* register function */
  lua_register(L, "escape_url", escape_url);
  lua_register(L, "escape_html", escape_html);
  
  tdata = Data_Wrap_Struct(class,0,rbLua_free,L);
  largv[0] = stack;
  rb_obj_call_init(tdata,1,largv);
  return(tdata);
}


static  VALUE   rbLua_init(VALUE self, VALUE stack){
  lua_State *L;
  Data_Get_Struct(self, lua_State, L);
  /*
    lua_register(L,"_ERRORMESSAGE",ml_err);
    lua_register(L,"print",ml_print);
    lua_register(L,"import",ml_import);
   */
  return(self);
}

static VALUE rbLua_eval(VALUE self, VALUE arg){
  lua_State *L;
  Data_Get_Struct(self, lua_State, L);
  Check_Type(arg, T_STRING);
  if (lua_dobuffer(L, RSTRING(arg)->ptr, RSTRING(arg)->len, NULL)){
    lua_dobuffer(L, RSTRING(arg)->ptr, RSTRING(arg)->len, RSTRING(arg)->ptr);
    rb_warn("%s", RSTRING(arg)->ptr);
  }
  return arg;
}


static VALUE get_lua_var(lua_State *L){
  int tix;
  VALUE key,val,rt = Qnil;
  debug_stack("before get_lua_var");
  switch(lua_type(L,-1)){
  case LUA_TNONE:
    break;
  case LUA_TBOOLEAN:
    rt = lua_toboolean(L,-1) ? Qtrue : Qfalse;
    break;
  case LUA_TUSERDATA:
    rt = (VALUE) lua_touserdata(L,-1);
    break;
  case LUA_TNIL:
    break;
  case LUA_TNUMBER:
    rt = rb_float_new(lua_tonumber(L,-1));
    break;
  case LUA_TSTRING:
    rt = rb_str_new2(lua_tostring(L,-1));
    break;
  case LUA_TTABLE:
    rt = rb_hash_new();
    tix = lua_gettop(L);
    lua_pushnil(L);
    while(lua_next(L,tix) != 0){
      val = get_lua_var(L);
      lua_pop(L,1);
      key = get_lua_var(L);
      rb_hash_aset(rt,key,val);
      /* lua_pop(L,1); */
    }
    lua_settop(L,tix);
    break;
  case LUA_TFUNCTION:
    break;
  }
  debug_stack("after get_lua_var");
  return(rt);
}


static VALUE rbLua_get(VALUE self, VALUE arg){
  VALUE v;
  lua_State *L;
  Data_Get_Struct(self, lua_State, L);
  Check_Type(arg, T_STRING);
  debug_stack("before rbLua_get");
  lua_getglobal(L, STR2CSTR(arg));
  v = get_lua_var(L);
  lua_pop(L,1); /* remove global from stack */
  debug_stack("after rbLua_get");
  return(v);
}

static void set_lua_table_value(lua_State *L, VALUE vname, VALUE vvalue);

static void push_lua_table_value(lua_State *L, VALUE vvalue){
  int tbl,len,i;
  VALUE keys;
  debug_stack("before set_lua_table_value");
  switch (TYPE(vvalue)) {
  case T_NIL:
    lua_pushnil(L);
    break;
  case T_TRUE:
    lua_pushboolean(L,1);
    break;
  case T_FALSE:
    lua_pushboolean(L,0);
    break;
  case T_STRING:
    lua_pushlstring(L, RSTRING(vvalue)->ptr, RSTRING(vvalue)->len);
    break;;
  case T_FIXNUM:
    lua_pushnumber(L,FIX2INT(vvalue));
    break;;
  case T_BIGNUM:
    lua_pushnumber(L,NUM2DBL(vvalue));
    break;;
  case T_FLOAT:
    lua_pushnumber(L,(lua_Number)RFLOAT(vvalue)->value);
    break;;
  case T_ARRAY:
    lua_newtable(L);
    tbl = lua_gettop(L);
    len = RARRAY(vvalue)->len;
    lua_pushstring(L, "n");
    lua_pushnumber(L,len);
    lua_settable(L, -3);
    for (i = 0; i < len; i++) {
      push_lua_table_value(L,RARRAY(vvalue)->ptr[i]);
      lua_rawseti(L,tbl,i + 1);
    }
    break;;
  case T_HASH:
    lua_newtable(L);
    keys = rb_funcall(vvalue, keys_id, 0);
    for (i=0; i<=(RARRAY(keys)->len)-1; i++){
      VALUE key;
      key = *(RARRAY(keys)->ptr+i);
      set_lua_table_value(L,key, rb_hash_aref(vvalue,key));
    }
    break;

  default:
    lua_pushlightuserdata(L,(void*)vvalue); /* saves ruby object */
    break;
  }
  debug_stack("after set_lua_table_value");
}

static void set_lua_table_value(lua_State *L, VALUE vname, VALUE vvalue){
  debug_stack("before set_lua_table");
  lua_pushlstring(L, RSTRING(vname)->ptr, RSTRING(vname)->len);
  push_lua_table_value(L,vvalue);
  lua_settable(L, -3);
  debug_stack("after set_lua_table");
}


static VALUE set_lua_var(lua_State *L, VALUE vname, VALUE vvalue){
  debug_stack("before set_lua_var");
  lua_pushlstring(L, RSTRING(vname)->ptr, RSTRING(vname)->len);
  push_lua_table_value(L,vvalue);
  lua_settable(L, LUA_GLOBALSINDEX);
  debug_stack("after set_lua_var");
  return Qnil;
}

static VALUE rbLua_set(VALUE self, VALUE vname, VALUE vvalue){
  lua_State *L;
  VALUE v;
  Data_Get_Struct(self, lua_State, L);
  debug_stack("before rbLua_set");
  v = set_lua_var(L,vname,vvalue);
  debug_stack("after rbLua_set");
  return(v);
}


static VALUE rbLua_setUserData(VALUE self, VALUE vname, VALUE vvalue){
  lua_State *L;
  Data_Get_Struct(self, lua_State, L);
  debug_stack("before rbLua_set");
  lua_pushlightuserdata(L,(void*)vvalue); /* saves ruby object */
  lua_setglobal(L,STR2CSTR(vname));
  debug_stack("after rbLua_set");
  return(vvalue);
}

static int call_ruby_function(lua_State *L){
  VALUE obj_id, args;
  ID method;
  int i,n = lua_gettop(L);    /* number of arguments */
  debug_stack("before call_ruby_function");
  method = (ID) lua_touserdata(L,lua_upvalueindex(2)); /* recover the ruby method ID */

  obj_id = (VALUE) lua_touserdata(L,lua_upvalueindex(1)); /* recover the ruby obj_id */
  args = rb_ary_new();
  for (i = n; i > 0; i--) { /* get arguments in first in first out order */

    lua_pushvalue(L,-i);
    rb_ary_push(args, get_lua_var(L));
    lua_pop(L,1); /* remove argument from stack */
  }
  lua_pop(L,n);
  n = lua_gettop(L);
  /* the result */
  push_lua_table_value(L, rb_funcall2(obj_id,method,RARRAY(args)->len,RARRAY(args)->ptr));
  /*push_lua_table_value(L, args);*/ /* the result */
  debug_stack("after call_ruby_function");
  return(lua_gettop(L) - n); /* number of results */

}

static VALUE rbLua_setFunc(VALUE self, VALUE args){
  int len,i;
  VALUE func_name,obj_id,method;
  lua_State *L;
  Data_Get_Struct(self, lua_State, L);
  debug_stack("before rbLua_setFunc");
  len = RARRAY(args)->len;
  i = 0;
  func_name = RARRAY(args)->ptr[i++];
  Check_Type(func_name, T_STRING);  /* function name to set */
  obj_id = RARRAY(args)->ptr[i++];
  method = rb_intern(STR2CSTR(RARRAY(args)->ptr[i++]));
  lua_pushlightuserdata(L,(void*)obj_id); /* saves ruby object */
  lua_pushlightuserdata(L,(void*)method); /* saves ruby object */

  lua_pushcclosure (L, call_ruby_function, 2);
  lua_setglobal(L,STR2CSTR(func_name));
  debug_stack("after rbLua_setFunc");
  return(Qnil);
}

static VALUE rbLua_call(int argc, VALUE *argv , VALUE self){
  lua_State *L;
  VALUE func, args, ret = Qnil;
  int i, len;
  Data_Get_Struct(self, lua_State, L);
  debug_stack("before rbLua_call");
  if(rb_scan_args(argc,argv,"1*",&func,&args) >= 1){
    lua_getglobal(L,STR2CSTR(func));
    len = RARRAY(args)->len;
    for (i = 0; i < len; i++) {
      push_lua_table_value(L,RARRAY(args)->ptr[i]);
    }
    ret = lua_pcall(L,len,1,0);
    if(ret == LUA_ERRRUN) {
      ret = get_lua_var(L);
      lua_pop(L,1); /*remove value from stack*/
      rb_raise(rb_eStandardError, "error calling '%s' in lua: '%s'", STR2CSTR(func), STR2CSTR(ret));
    }
    else if(ret == LUA_ERRMEM) {
      ret = get_lua_var(L);
      lua_pop(L,1); /*remove value from stack*/
      rb_raise(rb_eNoMemError, "out of memory calling '%s' in lua: '%s'", STR2CSTR(func), STR2CSTR(ret));
    }
    else {
      ret = get_lua_var(L);
      lua_pop(L,1); /*remove value from stack*/
    }
  }
  debug_stack("after rbLua_call");
  return(ret);
}

static int escape_url(lua_State *L) {
  int n = lua_gettop(L);    /* number of arguments */
  int i, arglen, retlen;
  const char *argstr;
  unsigned char *retstr, *p;
  unsigned char c;

  if (n != 1 || !lua_isstring(L, 1)) {
    lua_pushstring(L, "incorrect argument to function `escape_url'");
    lua_error(L);
  }

  /* Check_Type(str, T_STRING); */
  argstr = lua_tostring(L, 1);
  arglen = lua_strlen(L, 1);

  /* get length */
  retlen = 0;
  i=0;
  while(i<arglen) {
    c = argstr[i];
    if (FLAGS[c] & 1) {
      retlen += 1;
    } else {
      retlen += 3;
    }
    i++;
  }
  /* alloc */
  retstr = malloc(retlen);

  /* convert */
  p = retstr;
  i = 0;
  while(i<arglen) {
    c = argstr[i];
    if (FLAGS[c] & 1) {
      if (c==' ') *p++ = '+'; else *p++ = c;
    } else {
      *p++ = '%';
      *p++ = HEX[c >> 4];
      *p++ = HEX[c & 0xf];
    }
    i++;
  }
  
  lua_pushlstring(L, retstr, retlen); /* first result */
  free(retstr);
  
  return 1;                           /* number of results */
}

static int escape_html(lua_State *L) {
  int n = lua_gettop(L);    /* number of arguments */
  int i, arglen, retlen;
  const char *argstr;
  unsigned char *retstr, *p;
  unsigned char c;

  if (n != 1 || !lua_isstring(L, 1)) {
    lua_pushstring(L, "incorrect argument to function `escape_url'");
    lua_error(L);
  }

  /* Check_Type(str, T_STRING); */
  argstr = lua_tostring(L, 1);
  arglen = lua_strlen(L, 1);

  /* get length */
  retlen = arglen;
  for(i=0; i<arglen; i++) {
    retlen += (FLAGS[argstr[i]] >> 1);
  }
  /* alloc */
  retstr = malloc(retlen);

  /* convert */
  p = retstr;
  for(i=0; i<arglen;) {
    c = argstr[i];
    if (FLAGS[c] >> 1) {
      switch(c) {
      case '"':
        *p++ = '&';
        *p++ = 'q';
        *p++ = 'u';
        *p++ = 'o';
        *p++ = 't';
        *p++ = ';';
        break;
      case '&':
        *p++ = '&';
        *p++ = 'a';
        *p++ = 'm';
        *p++ = 'p';
        *p++ = ';';
        break;
      case 0x27:
        *p++ = '&';
        *p++ = '#';
        *p++ = '3';
        *p++ = '9';
        *p++ = ';';
        break;
      case '<':
        *p++ = '&';
        *p++ = 'l';
        *p++ = 't';
        *p++ = ';';
        break;
      case '>':
        *p++ = '&';
        *p++ = 'g';
        *p++ = 't';
        *p++ = ';';
        break;
      }
    } else {
      *p++ = c;
    }
    i++;
  }
  
  lua_pushlstring(L, retstr, retlen); /* first result */
  free(retstr);
  
  return 1;                           /* number of results */
}

void Init_lua(){
  VALUE L;
  L=rb_define_class("Lua",rb_cObject);
  rb_define_singleton_method(L,"new", rbLua_new,-1);
  rb_define_method(L,"initialize",rbLua_init,1);
  rb_define_method(L,"eval",rbLua_eval,1);
  rb_define_method(L,"get",rbLua_get,1);
  rb_define_method(L,"set",rbLua_set,2);
  rb_define_method(L,"setFunc",rbLua_setFunc,-2);
  rb_define_method(L,"setUserData",rbLua_setUserData,2);
  rb_define_method(L,"call",rbLua_call,-1);
  keys_id = rb_intern("keys");
}


