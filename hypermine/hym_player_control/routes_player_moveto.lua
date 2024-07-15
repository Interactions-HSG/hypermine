local json = require 'cjson.safe'

hypermine.player_moveto = {}
hypermine.player_moveto.routes = {}

local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. ".routes_player_moveto: "
local _decoded = {}

hypermine.player_moveto.routes = {
  ["/player/move_to"] = {

    preFunction = function(req, resp)
      local stop = false
      minetest.log("info", _log_point .. "received on " .. req.routerPath)
      _decoded = hypermine._decode_body(req:receiveBody())
      --TODO: ideally routes should not call the minetest API
      if not minetest.get_player_by_name(hypermine.player.name) then
        stop = true
        local err =  _log_point .. "player with name \"" .. hypermine.player.name .. "\" is invalid"
        minetest.log("error", err)
        resp:writeDefaultErrorMessage(400, err)
      else
        minetest.log("verbose", _log_point .. "accepted player name " .. dump(hypermine.player.name))
      end
      return stop
    end,

    postFunction = function(req, resp)
      _decoded = {}
    end,

    POST = function(req, resp)
      minetest.log("info", _log_point .. "received POST to move player")
      local stop = false
      local err = ""
      local res_code = 500
      local _ntask = 0

      if _decoded.location then
        --TODO This function needs to know what happened in order to propagate to user
        local status, result = pcall(hypermine.move_to, _decoded.location)
        if status then
          res_code = 202
          _ntask = hypermine.register_task()
        else
          stop = true
          err = "failed to set desination from request body"
          res_code = 400
        end
      else
        stop = true
        res_code = 400
        err = "unable to extract location from request body"
        minetest.log("error", _log_point .. err)
        -- TODO make this something sensible
      end

      if stop then
        resp:writeDefaultErrorMessage(res_code, err)
      else
        resp:statusCode(res_code)
        resp:addHeader("Content-Type", "application/json")
        resp:location("/player/move_to/" .. _ntask)
        resp:write(json.encode(hypermine.get_pos()))
      end
    return stop
    end,
  }
}