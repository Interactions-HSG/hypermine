# Hypermine

This project might grow into a feature rich environment that allows to control agents with hypermedia controls.

## How to run the container

To run this example, you will the server in the accompanied docker compose. It creates and image that contains the correct Lua version, the required dependencies, a patches for the dependencies, the correct environment variables ... just the usual container stuff.

### Bring up the server

```text
docker compose build
docker compose up
```

### Run a client

1. Start the client via the task menu or via cli `minetest`.
2. Click on `Join Game`
3. Type in IP address. To do so `docker network inspect hypermine_default` might be helpful
4. Register a new player
5. Connect

### Control the player

Implementation to the minetest mod can be found in `minetest_server/mods/interfaces/init.lua`.

```bash
# Get the player name that is currently controlled by the mod
curl localhost:9090/api/v1/player/name

# Set the player you are currently controlling
curl -X POST -H "Content-Type: application/json" localhost:9090/api/v1/player/name -d '{"name": "agent0"}'


# Get the position of the controlled player
curl localhost:9090/api/v1/player/position

# Change the position of the player by increment position
curl -X POST -H "Content-Type: application/json" localhost:9090/api/v1/player/position -d '{"position": {"x": -5.5,"y": 0,"z": 2.5 }}'
```

### Running in circles

Run `move.py` from outside the container.

## How to run on host

Make sure that you have installed the necessary dependency in a version that matches the Lua version of minetest. Since minetest usually uses LuaJIT, that is Lua5.1. See the `Dockerfile` for the currently required dependencies. Before starting `minetest` you will need to extend the environment with

```bash
eval `luarocks --lua-version=5.1 path`
```


## Development

### Insights

- Movement of player with `/player/position` endpoint does not perform collision detection
- Movement of player with `/player/move_to` endpoint is very clunky
  - Observation:
    1. This behavior showed up both when implementing directly in `register_globalstep` and using a Lua coroutine
    2. The method to [accelerate a localplayer](https://github.com/minetest/minetest/blob/3de42f56c5156c4a6e6438843f9d4a6d9ee236d9/src/client/localplayer.cpp#L806) receives a `target_speed`.
    3. The method [limits the rate](https://github.com/minetest/minetest/blob/3de42f56c5156c4a6e6438843f9d4a6d9ee236d9/src/client/localplayer.cpp#L829).
  - Assumption:
    1. The server side loop is not in sync with the client side loop and runs slower
      - [register_globalstep]() is called every ~0.1 s and hence misses out a few client-side loops. 
    2. If no movement button is pressed, a `target_speed` of `0` is passed to `accelerate`
    3. Since the HTTP API is not keypress based, and due to 1. and 2., the speed is reduced client-side between server-side
  - Conclusion:
    - If the assumptions are true, then this limits the mods features to applications that need a frequencies of single digit hertz

### Log levels

|level|usage|
|-------|-----|
|info   | logs for sequence monitoring of the hypermine modpack |
|verbose| logs that show intermediate results of functions in the hypermine modpack |