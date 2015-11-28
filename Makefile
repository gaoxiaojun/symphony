SKYNET_SRC_PATH = 3rd/skynet

# detect platform
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
ifeq ($(uname_S),Darwin)
    PLAT ?= macosx
endif
ifeq ($(uname_S),Linux)
    PLAT ?= linux
endif
ifeq ($(uname_S),FreeBSD)
    PLAT ?= freebsd
endif

include $(SKYNET_SRC_PATH)/platform.mk
LUA_CLIB_PATH ?= luaclib
CSERVICE_PATH ?= cservice

SKYNET_BUILD_PATH ?= .

CFLAGS = -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)
# CFLAGS += -DUSE_PTHREAD_LOCK

# lua

LUA_STATICLIB := $(SKYNET_SRC_PATH)/3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= $(SKYNET_SRC_PATH)/3rd/lua

$(LUA_STATICLIB) :
	cd $(SKYNET_SRC_PATH)/3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)

# jemalloc 

JEMALLOC_STATICLIB := $(SKYNET_SRC_PATH)/3rd/jemalloc/lib/libjemalloc_pic.a
JEMALLOC_INC := $(SKYNET_SRC_PATH)/3rd/jemalloc/include/jemalloc

all : jemalloc
	
.PHONY : jemalloc update$(SKYNET_SRC_PATH)/3rd

MALLOC_STATICLIB := $(JEMALLOC_STATICLIB)

$(JEMALLOC_STATICLIB) : $(SKYNET_SRC_PATH)/3rd/jemalloc/Makefile
	cd $(SKYNET_SRC_PATH)/3rd/jemalloc && $(MAKE) CC=$(CC) 

$(SKYNET_SRC_PATH)/3rd/jemalloc/autogen.sh :
	git submodule update --init

$(SKYNET_SRC_PATH)/3rd/jemalloc/Makefile : | $(SKYNET_SRC_PATH)/3rd/jemalloc/autogen.sh
	cd $(SKYNET_SRC_PATH)/3rd/jemalloc && ./autogen.sh --with-jemalloc-prefix=je_ --disable-valgrind

jemalloc : $(MALLOC_STATICLIB)

update$(SKYNET_SRC_PATH)/3rd :
	rm -rf $(SKYNET_SRC_PATH)/3rd/jemalloc && git submodule update --init

# skynet

CSERVICE = snlua logger gate harbor
LUA_CLIB = skynet socketdriver bson mongo md5 netpack \
  clientsocket memory profile multicast \
  cluster crypt sharedata stm sproto lpeg \
  mysqlaux debugchannel

SKYNET_SRC = skynet_main.c skynet_handle.c skynet_module.c skynet_mq.c \
  skynet_server.c skynet_start.c skynet_timer.c skynet_error.c \
  skynet_harbor.c skynet_env.c skynet_monitor.c skynet_socket.c socket_server.c \
  malloc_hook.c skynet_daemon.c skynet_log.c

all : \
  $(SKYNET_BUILD_PATH)/skynet \
  $(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(SKYNET_BUILD_PATH)/skynet : $(foreach v, $(SKYNET_SRC), $(SKYNET_SRC_PATH)/skynet-src/$(v)) $(LUA_LIB) $(MALLOC_STATICLIB)
	$(CC) $(CFLAGS) -o $@ $^ -I$(SKYNET_SRC_PATH)/skynet-src -I$(JEMALLOC_INC) $(LDFLAGS) $(EXPORT) $(SKYNET_LIBS) $(SKYNET_DEFINES)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

define CSERVICE_TEMP
  $$(CSERVICE_PATH)/$(1).so : $(SKYNET_SRC_PATH)/service-src/service_$(1).c | $$(CSERVICE_PATH)
	$$(CC) $$(CFLAGS) $$(SHARED) $$< -o $$@ -I$(SKYNET_SRC_PATH)/skynet-src
endef

$(foreach v, $(CSERVICE), $(eval $(call CSERVICE_TEMP,$(v))))

$(LUA_CLIB_PATH)/skynet.so : $(SKYNET_SRC_PATH)/lualib-src/lua-skynet.c $(SKYNET_SRC_PATH)/lualib-src/lua-seri.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_SRC_PATH)/skynet-src -I$(SKYNET_SRC_PATH)/service-src -I$(SKYNET_SRC_PATH)/lualib-src

$(LUA_CLIB_PATH)/socketdriver.so : $(SKYNET_SRC_PATH)/lualib-src/lua-socket.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_SRC_PATH)/skynet-src -I$(SKYNET_SRC_PATH)/service-src

$(LUA_CLIB_PATH)/bson.so : $(SKYNET_SRC_PATH)/lualib-src/lua-bson.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@ -I$(SKYNET_SRC_PATH)/skynet-src

$(LUA_CLIB_PATH)/mongo.so : $(SKYNET_SRC_PATH)/lualib-src/lua-mongo.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_SRC_PATH)/skynet-src

$(LUA_CLIB_PATH)/md5.so : $(SKYNET_SRC_PATH)/3rd/lua-md5/md5.c $(SKYNET_SRC_PATH)/3rd/lua-md5/md5lib.c $(SKYNET_SRC_PATH)/3rd/lua-md5/compat-5.2.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/3rd/lua-md5 $^ -o $@ 

$(LUA_CLIB_PATH)/netpack.so : $(SKYNET_SRC_PATH)/lualib-src/lua-netpack.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -I$(SKYNET_SRC_PATH)/skynet-src -o $@ 

$(LUA_CLIB_PATH)/clientsocket.so : $(SKYNET_SRC_PATH)/lualib-src/lua-clientsocket.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/memory.so : $(SKYNET_SRC_PATH)/lualib-src/lua-memory.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@ 

$(LUA_CLIB_PATH)/profile.so : $(SKYNET_SRC_PATH)/lualib-src/lua-profile.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/multicast.so : $(SKYNET_SRC_PATH)/lualib-src/lua-multicast.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@ 

$(LUA_CLIB_PATH)/cluster.so : $(SKYNET_SRC_PATH)/lualib-src/lua-cluster.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@ 

$(LUA_CLIB_PATH)/crypt.so : $(SKYNET_SRC_PATH)/lualib-src/lua-crypt.c $(SKYNET_SRC_PATH)/lualib-src/lsha1.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/sharedata.so : $(SKYNET_SRC_PATH)/lualib-src/lua-sharedata.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@ 

$(LUA_CLIB_PATH)/stm.so : $(SKYNET_SRC_PATH)/lualib-src/lua-stm.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@ 

$(LUA_CLIB_PATH)/sproto.so : $(SKYNET_SRC_PATH)/lualib-src/sproto/sproto.c $(SKYNET_SRC_PATH)/lualib-src/sproto/lsproto.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/lualib-src/sproto $^ -o $@ 

$(LUA_CLIB_PATH)/lpeg.so : $(SKYNET_SRC_PATH)/3rd/lpeg/lpcap.c $(SKYNET_SRC_PATH)/3rd/lpeg/lpcode.c $(SKYNET_SRC_PATH)/3rd/lpeg/lpprint.c $(SKYNET_SRC_PATH)/3rd/lpeg/lptree.c $(SKYNET_SRC_PATH)/3rd/lpeg/lpvm.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/3rd/lpeg $^ -o $@ 

$(LUA_CLIB_PATH)/mysqlaux.so : $(SKYNET_SRC_PATH)/lualib-src/lua-mysqlaux.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@	

$(LUA_CLIB_PATH)/debugchannel.so : $(SKYNET_SRC_PATH)/lualib-src/lua-debugchannel.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_SRC_PATH)/skynet-src $^ -o $@	

clean :
	rm -f $(SKYNET_BUILD_PATH)/skynet $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so 
	@rm -fr $(SKYNET_BUILD_PATH)/skynet.dSYM $(CSERVICE_PATH)/*.dSYM $(LUA_CLIB_PATH)/*.dSYM
	@rm -r $(CSERVICE_PATH) $(LUA_CLIB_PATH)
cleanall: clean
ifneq (,$(wildcard $(SKYNET_SRC_PATH)/3rd/jemalloc/Makefile))
	cd $(SKYNET_SRC_PATH)/3rd/jemalloc && $(MAKE) clean
endif
	cd $(SKYNET_SRC_PATH)/3rd/lua && $(MAKE) clean
	rm -f $(LUA_STATICLIB)

