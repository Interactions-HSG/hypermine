# Hypermine Exploration

Adds protective barriers around fields that might trap explorers

## Activation

### Mod Interface

Just enable the mod in the mod interface of Minetest

### HTTP Request

Might follow in the future

## Configuration

The defaults of this mods requires the devtest mods. However, it is configurable with this public interface

```lua
hypermine.exploration = {
  -- node types that qualify a node as unprotected
  types_unprotected = {
    [1] = "air",
    [2] = "airlike"
  },
  -- node types the explorer should be protected from
  types_need_protection = {
    "basenodes:sand",
    "group:lava"
  },
  -- node types that are used to protect the explorer
  type_protected = "testnodes:glasslike"
}
```