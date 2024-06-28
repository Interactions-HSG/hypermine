local socket = require 'socket'
local Handler = require 'pegasus.handler'

local Pegasus = {}
Pegasus.__index = Pegasus

function Pegasus:new(params)
  params = params or {}
  local server = {}

  server.host = params.host or '*'
  server.port = params.port or '9090'
  server.location = params.location or ''
  server.plugins = params.plugins or {}
  server.timeout = params.timeout or 1

  return setmetatable(server, self)
end

function Pegasus:start(callback)
  local handler = Handler:new(callback, self.location, self.plugins)
  local server = assert(socket.bind(self.host, self.port))
  local ip, port = server:getsockname()
  print('Pegasus is up on ' .. ip .. ":".. port)
  -- AEG: Allow timeout to allow for non-blocking socket
  server:settimeout(self.timeout)

  -- AEG: back in case errmsg is unknown
  local function handle_unknown(errmsg)
    io.stderr:write('Failed to accept connection:' .. errmsg .. '\n')
  end

  -- AEG: switch alternative in lua to handle different errors
  local error_table = {
    ["timeout"] = function () end -- is to be expected when non-blocking
  }
 
  local function check_for_main ()
    -- API New	co.running()	is_main
    --   0	          nil        1
    --   0	          string     0
    --   1	          0          0
    --   1	          1          1
    local is_main = true -- in doubt assume main
    local _, i = string.find(_VERSION, "Lua ")
    local is_api_newer_5_1 = string.sub(_VERSION, i+1, #_VERSION) > "5.1"
    -- coroutine.running() behaves differently in 5.2 and newer
    local is_co_running, _ = coroutine.running()
    is_co_running = is_co_running and true or false
    if is_co_running ~= is_api_newer_5_1 then
      is_main = false
    end
    return is_main
  end

  local is_main = check_for_main()

  while 1 do
    -- AEG: if this function never yields, pegasus cannot be used with coroutines
    if not is_main then
      coroutine.yield()
    end
    local client, errmsg = server:accept()

    if client then
      client:settimeout(self.timeout, 'b')
      handler:processRequest(self.port, client, server)
    else
      if error_table[errmsg] then
        error_table[errmsg]()
      else
        handle_unknown(errmsg)
      end
    end
  end
end

return Pegasus
