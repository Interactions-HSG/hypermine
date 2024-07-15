local json = require 'cjson.safe'

hypermine.player_moveto_status = {}
hypermine.player_moveto_status.routes = {}

local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. ".routes_player_moveto_status: "
local _decoded = {}

hypermine.player_moveto_status.routes = {
    ["/player/move_to/{task}"] = {
      preFunction = function (req, resp)
        local stop = false
        local _task = req.pathParameters.task

        if not hypermine.get_task(_task) then
          local err = ("'%s' is an unknown task"):format(_task)
          minetest.log("error", _log_point .. err)
          resp:writeDefaultErrorMessage(404, err)
          stop = true
        end

        return stop
      end,

      GET = function(req, resp)
        resp:statusCode(200)
        resp:addHeader("Content-Type", "application/json")
        resp:write(json.encode(hypermine.get_task_update(tostring(req.pathParameters.task))))
      end
  }
}