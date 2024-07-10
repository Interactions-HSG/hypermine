hypermine.Dispatcher = {
    _threads = {},
    _names = {},
    _nthreads = 0
}

local function _unregister_coroutine(index)
    table.remove(hypermine.Dispatcher._threads, index)
    table.remove(hypermine.Dispatcher._names, index)
    hypermine.Dispatcher._nthreads = hypermine.Dispatcher._nthreads - 1
end

function hypermine.Dispatcher.register_coroutine(thread, name)
    table.insert(hypermine.Dispatcher._threads, thread)
    table.insert(hypermine.Dispatcher._names, name)
    hypermine.Dispatcher._nthreads = hypermine.Dispatcher._nthreads + 1
end

function hypermine.Dispatcher.dispatch()
    -- local hypermine.Dispatcher._nthreads = table.getn(hypermine.coroutines)
    if 1 <= hypermine.Dispatcher._nthreads then
      minetest.log("warning", "currently handling " .. hypermine.Dispatcher._nthreads .. " coroutines")
      for i=1, hypermine.Dispatcher._nthreads do
        local thread = hypermine.Dispatcher._threads[i]
        local name = hypermine.Dispatcher._names[i]
        local status_co = coroutine.status(thread)
        if "suspended" == status_co then
        -- the order might be different in Lua 5.1 than in later versions
          local is_resumed, res = coroutine.resume(thread)
          if is_resumed then
            minetest.log("trace", "hypermine: successfully resumed coroutine " .. name)
          else
            minetest.log("error", "hypermine: error when trying to resume coroutine  " .. name)
            minetest.log("error", "hypermine: removing coroutine " .. dump(res))
            _unregister_coroutine(i)
          end
        elseif "dead" then
          minetest.log("trace", "hypermine: coroutine "  .. name .. " finished orderly")
          _unregister_coroutine(i)
        end
        -- keep "running" co running
      end
    end 
end