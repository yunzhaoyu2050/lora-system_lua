
ARCH:=$(shell uname -m)

.PHONY:all clean

all:git luvi luvit openssl luv
	@echo "build..."
git:
	@git submodule update --init --recursive
luvi:
	@cd deps/luvi && make tiny && make && cd -
luvit:
	@cd deps/ && ln -ns luvi/build/luvi luvi-$(ARCH) && ./luvi-x86_64 luvit/ -o luvit-$(ARCH) && cd -
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
