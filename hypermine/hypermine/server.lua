local Pegasus = require("pegasus")

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

hypermine.server_co = coroutine.create(function ()
    hypermine.server:start(function () return false end)
end)