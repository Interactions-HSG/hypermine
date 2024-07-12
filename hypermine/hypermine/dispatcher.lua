hypermine.Dispatcher = {
    _threads = {},
    _names = {},
    _nthreads = 0
}

local _log_point = hypermine._log_prefix .. ".dispatcher: "

local function _unregister_coroutine(index)
    table.remove(hypermine.Dispatcher._threads, index)
    table.remove(hypermine.Dispatcher._names, index)
    hypermine.Dispatcher._nthreads = hypermine.Dispatcher._nthreads - 1
end

function hypermine.Dispatcher.register_coroutine(thread, name)
    minetest.log("verbose", _log_point .. "registering coroutine " .. name)
    table.insert(hypermine.Dispatcher._threads, thread)
    table.insert(hypermine.Dispatcher._names, name)
    hypermine.Dispatcher._nthreads = hypermine.Dispatcher._nthreads + 1
end

function hypermine.Dispatcher.dispatch()
    -- local hypermine.Dispatcher._nthreads = table.getn(hypermine.coroutines)
    if 1 <= hypermine.Dispatcher._nthreads then
      -- Log level trace is on purpose
      minetest.log("trace", _log_point .. "currently handling " .. hypermine.Dispatcher._nthreads .. " coroutines")
      for i=1, hypermine.Dispatcher._nthreads do
        local thread = hypermine.Dispatcher._threads[i]
        local name = hypermine.Dispatcher._names[i]
        local status_co = coroutine.status(thread)
        if "suspended" == status_co then
        -- the order might be different in Lua 5.1 than in later versions
          local is_resumed, res = coroutine.resume(thread)
          if is_resumed then
            -- Log level trace is on purpose
            minetest.log("trace", _log_point .. "successfully resumed coroutine " .. name)
          else
            minetest.log("error", _log_point .. "error when trying to resume coroutine  " .. name)
            minetest.log("error", _log_point .. "removing coroutine " .. dump(res))
            _unregister_coroutine(i)
          end
        elseif "dead" then
          minetest.log("verbose", _log_point .. "coroutine "  .. name .. " finished cleanly")
          _unregister_coroutine(i)
        end
        -- keep "running" co running
      end
    end 
end