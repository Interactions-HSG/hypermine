hypermine = {
  _log_prefix = minetest.get_current_modname()
}

local _log_point = hypermine._log_prefix .. ": " 


local function load_module(path)
    local file = io.open(path, "r")
    if not file then return end
    file:close()
    return dofile(path)
end

local path = minetest.get_modpath(minetest.get_current_modname())
load_module(path .. "/dispatcher.lua")
load_module(path .. "/server.lua")

minetest.register_globalstep(function(dtime)
  -- give control to the coroutines
  hypermine.Dispatcher.dispatch()
end)