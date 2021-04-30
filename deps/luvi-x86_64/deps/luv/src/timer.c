/*
 *  Copyright 2014 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
#include "private.h"

static uv_timer_t* luv_check_timer(lua_State* L, int index) {
  uv_timer_t* handle = (uv_timer_t*) luv_checkudata(L, index, "uv_timer");
  luaL_argcheck(L, handle->type == UV_TIMER && handle->data, index, "Expected uv_timer_t");
  return handle;
}

static int luv_new_timer(lua_State* L) {
  luv_ctx_t* ctx = luv_context(L);
  uv_timer_t* handle = (uv_timer_t*) luv_newuserdata(L, sizeof(*handle));
  int ret = uv_timer_init(ctx->loop, handle);
  if (ret < 0) {
    lua_pop(L, 1);
    return luv_error(L, ret);
  }
  handle->data = luv_setup_handle(L, ctx);
  return 1;
}

static void luv_timer_cb(uv_timer_t* handle) {
  luv_handle_t* data = (luv_handle_t*)handle->data;
  lua_State* L = data->ctx->L;
  luv_call_callback(L, data, LUV_TIMEOUT, 0);
}

static int luv_timer_start(lua_State* L) {
  uv_timer_t* handle = luv_check_timer(L, 1);
  uint64_t timeout;
  uint64_t repeat;
  int ret;
  timeout = luaL_checkinteger(L, 2);
  repeat = luaL_checkinteger(L, 3);
  luv_check_callback(L, (luv_handle_t*)handle->data, LUV_TIMEOUT, 4);
  ret = uv_timer_start(handle, luv_timer_cb, timeout, repeat);
  return luv_result(L, ret);
}

static int luv_timer_stop(lua_State* L) {
  uv_timer_t* handle = luv_check_timer(L, 1);
  int ret = uv_timer_stop(handle);
  return luv_result(L, ret);
}

static int luv_timer_again(lua_State* L) {
  uv_timer_t* handle = luv_check_timer(L, 1);
  int ret = uv_timer_again(handle);
  return luv_result(L, ret);
}

static int luv_timer_set_repeat(lua_State* L) {
  uv_timer_t* handle = luv_check_timer(L, 1);
  uint64_t repeat = luaL_checkinteger(L, 2);
  uv_timer_set_repeat(handle, repeat);
  return 0;
}

static int luv_timer_get_repeat(lua_State* L) {
  uv_timer_t* handle = luv_check_timer(L, 1);
  uint64_t repeat = uv_timer_get_repeat(handle);
  lua_pushinteger(L, repeat);
  return 1;
}

static uv_timer_t* timer_handle = NULL;
static int volatile lua_entry = 0;
static unsigned char last_event = 0;

static void luv_event_cb(void* obj, unsigned char event) {
  //  printf("handler start [%p]\n",obj);
  if(timer_handle != NULL && lua_entry == 0){

      last_event = event;
      lua_State* L = luv_state(timer_handle->loop);
      luv_handle_t* data = (luv_handle_t*)timer_handle->data;
      // printf("obj=%p,event=%d,last=%d\n",obj,event);
      lua_entry=1;
      lua_pushinteger(L, (unsigned long int)obj);
      lua_pushinteger(L, event);
      luv_call_callback(L, data, LUV_TIMEOUT, 2);
      lua_entry = 0;
    }
    else if(lua_entry){
      printf("lua_entry error obj=%p,event=%d,last=%d\n",obj,event,last_event);
    }
  // printf("handler done\n");
}

static int luv_lv_event_start(lua_State* L) {
  uv_timer_t* handle = luv_check_timer(L, 1);
  uint64_t timeout;
  uint64_t repeat;
  void (*event_handle)(struct uv_timer_s *) = NULL;
  const char *cb_str;
  size_t size;
  int ret;
  timer_handle = NULL;
  repeat = luaL_checkinteger(L, 2);
  cb_str = luaL_checklstring(L,3, &size);
  if(size <= 0 || sscanf(cb_str,"cdata<unsigned int ()>: %p",&event_handle) != 1){
     printf("lv_event_start bad c callback\n");
     lua_pushinteger(L, -1);
     return 1;
  }
  ret = uv_timer_start(handle, event_handle, repeat, repeat);
  if (ret < 0) return luv_error(L, ret);
  if(luv_is_callable(L,4)){
      luv_check_callback(L, (luv_handle_t*)handle->data, LUV_TIMEOUT, 4);
      timer_handle = handle;
      lua_entry = 0;
  }
  // printf("luv_event_cb=%p\n",luv_event_cb);
  lua_pushinteger(L, (long int)luv_event_cb);
  return 1;
}