hypermine.Dispatcher = {
    _threads = {},
    _names = {},
    _nthreads = 0
}

local _log_point = hypermine._log_prefix .. ".dispatcher: "

local function _unregister_coroutine(index)
  minetest.log("info", _log_point .. "unregistering coroutine with index " .. index)
  table.remove(hypermine.Dispatcher._threads, index)
  table.remove(hypermine.Dispatcher._names, index)
  hypermine.Dispatcher._nthreads = hypermine.Dispatcher._nthreads - 1
  minetest.log("info", _log_point .. "now handling " .. hypermine.Dispatcher._nthreads .. " coroutines")
end

function hypermine.Dispatcher.register_coroutine(thread, name)
  minetest.log("info", _log_point .. "registering coroutine " .. name)
  table.insert(hypermine.Dispatcher._threads, thread)
  table.insert(hypermine.Dispatcher._names, name)
  hypermine.Dispatcher._nthreads = hypermine.Dispatcher._nthreads + 1
  minetest.log("info", _log_point .. "now handling " .. hypermine.Dispatcher._nthreads .. " coroutines")
end

function hypermine.Dispatcher.dispatch()
  -- local hypermine.Dispatcher._nthreads = table.getn(hypermine.coroutines)
  if 1 <= hypermine.Dispatcher._nthreads then
    for i=1, hypermine.Dispatcher._nthreads do
      local thread = hypermine.Dispatcher._threads[i]
      local name = hypermine.Dispatcher._names[i]
      local status_co = coroutine.status(thread)
      if "suspended" == status_co then
      -- the order might be different in Lua 5.1 than in later versions
        local is_resumed, res = coroutine.resume(thread)
        if not is_resumed then
          minetest.log("error", _log_point .. "error when trying to resume coroutine  " .. name)
          minetest.log("error", _log_point .. "removing coroutine " .. dump(res))
          _unregister_coroutine(i)
        end
      elseif "dead" then
        minetest.log("info", _log_point .. "coroutine "  .. name .. " finished cleanly")
        _unregister_coroutine(i)
      end
      -- keep "running" co running
    end
  end 
end