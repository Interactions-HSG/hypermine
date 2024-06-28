FROM lscr.io/linuxserver/minetest:latest


RUN \
apk add  \
# required by pegasus
gcc \
musl-dev \
zlib \
zlib-dev \
lua5.1-dev \
luarocks

RUN \
  luarocks-5.1 --lua-version=5.1 install lua-cjson && \
  luarocks-5.1 ZLIB_INCDIR=/usr/include --lua-version=5.1 install pegasus


# Path pegasus to work with coroutine
COPY patches/src/pegasus/init.lua /usr/local/share/lua/5.1/pegasus/init.lua
