hypermine = {}

local function load_module(path)
    local file = io.open(path, "r")
    if not file then return end
    file:close()
    return dofile(path)
end

local path = minetest.get_modpath(minetest.get_current_modname())
load_module(path .. "/dispatcher.lua")
load_module(path .. "/server.lua")

local _dispatcher = hypermine.Dispatcher

minetest.log("warning", dump(minetest.object_refs))

minetest.register_globalstep(function(dtime)
  -- give control to the coroutines
  hypermine.Dispatcher.dispatch()
end)