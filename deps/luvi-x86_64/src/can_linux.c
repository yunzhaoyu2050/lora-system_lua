
#include <assert.h>
#include "luvi.h"
#include <ctype.h>
#include <limits.h>
#include <stddef.h>
#include <string.h>
#include <stdint.h>
#include <termios.h>
#include <fcntl.h>
#include <assert.h>
#include <errno.h>
 

#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"

#include <net/if.h>
// #include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>


#if (LUA_VERSION_NUM >= 502)

#define luaL_register(L,n,f)	luaL_newlib(L,f)

#endif





static int open_can (lua_State *L)
{
	struct sockaddr_can addr;
	struct ifreq ifr;
    int ret;
    int s;
    int ro = 0;
    const char *port = luaL_checkstring(L, 1);
    if(lua_isnumber(L,2)){
        ro = lua_tonumber(L,2);
    }
	s = socket(PF_CAN, SOCK_RAW, CAN_RAW);//创建套接字
	strcpy(ifr.ifr_name, port);
	ret = ioctl(s, 0x8933, (long)&ifr); //指定can 设备
    if (ret < 0){
        close(s);
        goto err;
    }
	addr.can_family = AF_CAN;
	addr.can_ifindex = ifr.ifr_ifindex;
	ret = bind(s, (struct sockaddr *)&addr, sizeof(addr));//将套接字与can 绑定
    if(ret < 0){
        close(s);
        goto err;
    }
    ret = setsockopt(s, SOL_CAN_RAW, CAN_RAW_RECV_OWN_MSGS, &ro, sizeof(ro));
    if(ret < 0){
        close(s);
        goto err;
    }
    int x;      //set NONBLOCK
    x=fcntl(s,F_GETFL,0);  
    ret = fcntl(s,F_SETFL,x | O_NONBLOCK);  
    if(ret < 0){
        close(s);
        goto err;
    }
    ret = s;
err:
    lua_pushinteger(L,ret);
    return 1;
}

static int close_can (lua_State *L)
{
    int s = luaL_checkint(L,1);
    int ret = close(s);
    lua_pushinteger(L,ret);
    return 1;
}

static int read_can(lua_State *L)
{
    int s = luaL_checkint(L,1);
    int ret;
    struct can_frame frame[1];
    ret = read(s,frame,sizeof(frame));
    if(ret > 0)
    {
        int i;
        lua_pushinteger(L,ret);
        struct can_frame *pframe = &frame;
        // printf("can revice id=%x,dlc=%d,data=%02x %02x %02x %02x %02x %02x %02x %02x\n",pframe->can_id,pframe->can_dlc, \
        // pframe->data[0],pframe->data[1],pframe->data[2],pframe->data[3],pframe->data[4],pframe->data[5],pframe->data[6],pframe->data[7]);
        lua_newtable(L);
        lua_pushinteger(L, pframe->can_id);
        lua_setfield(L,-2,"id");
        lua_pushinteger(L, pframe->can_dlc);
        lua_setfield(L,-2,"dlc");
        luaL_Buffer b;
        luaL_buffinitsize(L, &b, 8);
        luaL_addlstring(&b, pframe->data, 8);
        luaL_pushresult(&b);
        lua_setfield(L,-2,"data");
        return 2;
    }
    else
    {
        return 1;
    }
}

static int write_can (lua_State *L)
{
    int ret;
    struct can_frame frame;
    int s = luaL_checkint(L,1);
    if(lua_istable(L,2)){
        lua_getfield(L,2,"id");
        frame.can_id = luaL_checkint(L,-1);
        lua_pop(L, 1);
        lua_getfield(L,2,"dlc");
        frame.can_dlc = luaL_checkint(L,-1);
        lua_pop(L, 1);
        lua_getfield(L,2,"data");
        const char *data = luaL_checkstring(L,-1);
        memcpy(frame.data,data,8);
        lua_pop(L, 1);
        // printf("can write id=%x,dlc=%d,data=%02x %02x %02x %02x %02x %02x %02x %02x\n",frame.can_id,frame.can_dlc, \
        //     frame.data[0],frame.data[1],frame.data[2],frame.data[3],frame.data[4],frame.data[5],frame.data[6],frame.data[7]);
        ret = write(s,&frame,sizeof(frame));
        lua_pushinteger(L,ret);
    }
    else{
        lua_pushinteger(L,-2);
    }
    return 1;

}

static int set_can_opt (lua_State *L)
{
    struct can_filter rfilter;
    int s = luaL_checkint(L,1);
    rfilter.can_id  = luaL_checkint(L,2);
    rfilter.can_mask  = luaL_checkint(L,3);
    int ret = setsockopt(s, SOL_CAN_RAW, CAN_RAW_FILTER, &rfilter, sizeof(rfilter));
    lua_pushinteger(L,ret);
    return 1;
}

static int can_error(lua_State *L)
{
    int err_no = luaL_checkint(L,1);
    char *err = strerror(-err_no);
    if(err != NULL)
    {
        lua_pushlstring(L,err,strlen(err));
    }
    else

    {
        lua_pushnil(L);
    }
    return 1;
}

/* }====================================================== */



static const struct luaL_Reg canlib[] =
{
    {"open", open_can},
    {"close", close_can},
    {"read", read_can},
    {"write", write_can},
    {"setopt", set_can_opt},
    {"strerror",can_error},
    {NULL, NULL}
};


LUALIB_API  int luaopen_can(lua_State *L)
{

    luaL_register(L, "can", canlib);

    return 1;

}


