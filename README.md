# hypermine

This project might grow into a feature rich environment that allows to control agents with hypermedia controls.

## How to run

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
