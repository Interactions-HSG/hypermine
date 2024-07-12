local Pegasus = require("pegasus")

local _log_point = hypermine._log_prefix .. ".server: "

hypermine.server = Pegasus:new(
    {
        port = '9090',
        timeout = 0.1, -- prevent server from blocking
        -- plugins = {
        --     Router:new {
        --         prefix = "/api/v1/",
        --         routes = hypermine.routes,
        --       },
        -- }
    }
)

local _co_name = "Pegasus"
local _co = coroutine.create(function ()
    hypermine.server:start(function () return false end)
end)

hypermine.Dispatcher.register_coroutine(_co, _co_name)
