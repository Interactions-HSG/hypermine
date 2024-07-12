FROM lscr.io/linuxserver/minetest:latest


RUN \
  apk add  \
  # required by pegasus
  gcc \
  musl-dev \
  zlib \
  zlib-dev \
  lua5.1-dev \
  luarocks \
  # for minetest mods
  git

RUN \
  luarocks-5.1 --lua-version=5.1 install lua-cjson && \
  luarocks-5.1 ZLIB_INCDIR=/usr/include --lua-version=5.1 install pegasus


# Path pegasus to work with coroutine
COPY patches/src/pegasus/init.lua /usr/local/share/lua/5.1/pegasus/init.lua

ARG MOD_PATH=/config/.minetest/mods

# Clone useful mods
RUN \
  # The repositories might exist when a volume is used
  rm -rf ${MOD_PATH}/* && \
  git clone https://github.com/appgurueu/dbg.git ${MOD_PATH}/dbg && \
  git clone https://github.com/Uberi/Minetest-WorldEdit.git ${MOD_PATH}/worldedit && \
  git clone https://github.com/ketwaroo/minetest-k-wordedit-gui.git ${MOD_PATH}/k_worldedit_gui && \
  git clone https://github.com/HybridDog/we_undo.git ${MOD_PATH}/we_undo && \
  git clone https://github.com/minetest-mods/unified_inventory.git ${MOD_PATH}/unified_inventory && \
  git clone https://codeberg.org/Wuzzy/minetest_spawnbuilder.git ${MOD_PATH}/spawnbuilder && \
  git clone https://gitlab.com/luk3yx/minetest-flow.git ${MOD_PATH}/flow \
