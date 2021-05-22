
ARCH:=$(shell uname -m)

.PHONY:all clean install git luvi luvit openssl luv

all:git luvi luvit openssl luv
	@echo "build end..."
git:
	@echo "git sub update..."
	@git submodule update --init --recursive
luvi:
	@echo "build luvi..."
	@cd deps/luvi && make tiny && make && cd -
luvit:
	@echo "build luvit..."
	@cd deps/ && if [ ! -f "luvi-$(ARCH)" ];then \
			ln -ns luvi/build/luvi luvi-$(ARCH); \
		fi \
		&& ./luvi-x86_64 luvit/ -o luvit-$(ARCH) && cd -
openssl:
	@cd deps/lua-openssl/ && sed -i '87a CFLAGS += -I../luvi/deps/luv/deps/luajit/src/' Makefile && git submodule update --init --recursive && make && cd -
luv:
	@cd deps/luv && make && cd -

clean:
	@echo "clean..."
	@cd deps/luvi && make clean && cd -
	@cd deps/luv && make clean && cd -
	@cd deps/lua-openssl/ && make clean && cd -
	@cd deps/ && rm -f luvi-$(ARCH) && rm -f luvit-$(ARCH)

install:
	@cd deps/luvi && make regular-shared && mkdir -p build/install && LUVI_BINDIR=build/install make install && cd -