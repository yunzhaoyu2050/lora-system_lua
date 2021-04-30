
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
#include <linux/serial.h>
#define TIOCGRS485      0x542E
#define TIOCSRS485      0x542F


#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"



#if (LUA_VERSION_NUM >= 502)

#define luaL_register(L,n,f)	luaL_newlib(L,f)

#endif



static int setTimeOuts (lua_State *L)
{
    return 0;
}

static int purgeComm (lua_State *L)
{
    //int h_Comm = luaL_checkint(L,1);
    //int mask = luaL_checkint(L,2);
    //PurgeComm(h_Comm,mask);
    return 0;
}



static int open_port (lua_State *L)
{
    const int   speed_arr[] = {B4000000,B3500000,B3000000,B2500000,B2000000,B1500000,B1152000,B1000000,B921600,B576000,B500000,B460800,B230400,B115200, B57600, B38400, B19200, B9600, B4800, B2400, B1800, B1200, B300};
    const int   name_arr[] = {4000000,3500000,3000000,2500000,2000000,1500000,1152000,1000000,921600,576000,500000,460800,230400,115200, 57600, 38400, 19200,  9600,  4800,  2400,  1800, 1200,  300};
    struct termios options;
    int err;
    int i;
    const char *port = luaL_checkstring(L, 1);
    int baudrate = luaL_optinteger(L,2,9600);
    const char * str_parity = luaL_optstring(L,3,"N");
    int data_bits = luaL_optinteger(L,4,8);
    int stop_bits = luaL_optinteger(L,5,1);
    int flow_ctrl = luaL_optinteger(L,6,0);
    int fd = open(port, O_RDWR|O_NOCTTY|O_NDELAY);
    if(fd < 0)
    {
        printf("open %s failure, err = %s\n", port, strerror(errno));
        goto err1;
    }
    fcntl(fd, F_SETFL, 0);
    tcflush(fd, TCIOFLUSH);
    if ((err = tcgetattr(fd, &options)) != 0)
    {
        printf("tcgetattr %s, err = %s\n", port, strerror(errno));
        close(fd);
        goto err1;

    }
    options.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
    options.c_oflag &= ~OPOST;
    options.c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
    options.c_cflag &= ~(CSIZE|PARENB);
    options.c_cflag |= CS8;
    options.c_cflag &= ~CRTSCTS;//no flow control
    switch(flow_ctrl)
    {
    case 0 ://不使用流控制
        options.c_cflag &= ~CRTSCTS;
        break;
    case 1 ://使用硬件流控制
        options.c_cflag |= CRTSCTS;
        break;
    case 2 ://使用软件流控制
        options.c_cflag |= IXON | IXOFF | IXANY;
        break;
    }

    options.c_cflag &= ~CSIZE;
    switch(data_bits)
    {
    case 5:
        options.c_cflag |= CS5;
        break;
    case 6:
        options.c_cflag |= CS6;
        break;
    case 7:
        options.c_cflag |= CS7;
        break;
    case 8:
        options.c_cflag |= CS8;
        break;
    default:
        fprintf(stderr,"Unsupported data size\n");
        close(fd);
        fd = -3;
        goto err1;
    }
    switch(*str_parity)
    {
    case 'n':
    case 'N':
        options.c_cflag &= ~PARENB;
        options.c_iflag &= ~INPCK;
        break;
    case 'o':
    case 'O':
        options.c_cflag |= (PARODD | PARENB);
        options.c_iflag |= INPCK;
        break;
    case 'e':
    case 'E':
        options.c_cflag |= PARENB;
        options.c_cflag &= ~PARODD;
        options.c_iflag |= INPCK;
        break;
    case 's':
    case 'S':
        options.c_cflag &= ~PARENB;
        options.c_cflag &= ~CSTOPB;
        break;
    default:
        fprintf(stderr,"Unsupported parity\n");
        close(fd);
        fd = -4;
        goto err1;
    }
    switch (stop_bits)
    {
        case 1:
            options.c_cflag &= ~CSTOPB;
            break;
        case 2:
            options.c_cflag |= CSTOPB;
            break;
        default:
            fprintf(stderr,"Unsupported stop bitsn");
            close(fd);
            fd = -4;
            goto err1;
    }
    //设置等待时间和最小接收字符
    options.c_cc[VTIME] = 1; /* 读取一个字符等待1*(1/10)s */
    options.c_cc[VMIN] = 1; /* 读取字符的最少个数为1 */

    for ( i= 0;  i < sizeof(speed_arr) / sizeof(int);  i++)
    {
        if  (baudrate == name_arr[i])
        {
            cfsetispeed(&options, speed_arr[i]);
            cfsetospeed(&options, speed_arr[i]);
        }
    }
    tcsetattr (fd, TCSANOW, &options);
err1:
    lua_pushinteger(L,fd);
    return 1;
}

static int close_port (lua_State *L)
{
    int fd = luaL_checkint(L,1);
    int ret = close(fd);
    lua_pushinteger(L,ret);
    return 1;
}

static int read_port(lua_State *L)
{
    int fd = luaL_checkint(L,1);
    int length = luaL_checkint(L,2);
    int ret;
    char *buf = malloc(length);
    ret = read(fd,buf,length);
    lua_pushinteger(L,ret);
    if(ret > 0)
    {
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        luaL_addlstring(&b, buf, ret);
        free(buf);
        luaL_pushresult(&b);
        return 2;
    }
    else
    {
        free(buf);
        return 1;
    }
}

static int write_port (lua_State *L)
{
    int ret;
    int fd = luaL_checkint(L,1);
    const char *data = luaL_checkstring(L, 2);
    int length = luaL_checkint(L,3);
    ret = write(fd,data,length);
    lua_pushinteger(L,ret);
    return 1;

}


static int set485conf(lua_State *L)
{
    int ret;
    struct serial_rs485 rs485conf;
    int fd = luaL_checkint(L,1);
    rs485conf.flags = luaL_checkint(L,2);
    rs485conf.delay_rts_before_send = luaL_checkint(L,3);
    rs485conf.delay_rts_after_send = luaL_checkint(L,4);
    ret = ioctl (fd, TIOCSRS485, &rs485conf);
    lua_pushinteger(L,ret);
    return 1;
}

static int str_error(lua_State *L)
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



static const struct luaL_Reg seriallib[] =
{
    {"open", open_port},
    {"close", close_port},
    {"read", read_port},
    {"write", write_port},
    {"setTimeOuts",setTimeOuts},
    {"purgeComm",purgeComm},
    {"strerror",str_error},
    {"set485conf",set485conf},
    {NULL, NULL}
};


LUALIB_API  int luaopen_serial(lua_State *L)
{

    luaL_register(L, "serial", seriallib);

    return 1;

}

#ifdef TEST

int main(int argc, char **argv)

{

    int fd;

    int ret;

    LPVOID lpMsgBuf;

    char rxbuf[256];

    fd = OpenPort("COM1",9600,'N',8,1);

    if(fd < 0)

    {

        printf(strerror(-fd));

        FormatMessageA (

            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,

            NULL,

            -fd,

            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),

            (LPTSTR) &lpMsgBuf,

            0, NULL );

        printf(lpMsgBuf);

        LocalFree(lpMsgBuf);

    }



    fd = WritePort(fd,"hello",5);

    printf(strerror(-fd));

    if(fd < 0)

    {

        FormatMessageA (

            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,

            NULL,

            -fd,

            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),

            (LPTSTR) &lpMsgBuf,

            0, NULL );

        printf(lpMsgBuf);

        LocalFree(lpMsgBuf);

    }

    ret = ReadPort(fd,rxbuf,256);

    ClosePort(fd);



}

#endif

