local json = require 'cjson.safe'

hypermine.player_name = {}
hypermine.player_name.routes = {}

local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. ".routes_player_name: "
local _decoded = {}

hypermine.player_name.routes = {
  ["/player/name"] = {

    preFunction = function(req, resp)
      minetest.log("info", _log_point .. "received on " .. req.routerPath)
      _decoded = hypermine._decode_body(req:receiveBody())
    end,

    postFunction = function(req, resp)
      _decoded = {}
    end,
  
    GET = function(req, resp)
      resp:statusCode(200)
      resp:addHeader("Content-Type", "application/json")
      resp:write(json.encode(hypermine.player.name))
    end,

    POST = function(req, resp)
      local res_code = 200
      if _decoded.name then
        local status, result = pcall(hypermine.set_player, _decoded.name)
        if status then
          minetest.log("info", _log_point .. "took control over player" .. hypermine.player.name)
        else
          minetest.log("error", _log_point .. "unable to take control over player ")
          minetest.log("error", result)
          res_code = 400
        end
      else
        minetest.log("error", _log_point .. "unable to extract name from request body")
        -- TODO make this something sensible
        res_code = 400
      end
      
      resp:statusCode(res_code)
      resp:addHeader("Content-Type", "application/json")
      resp:write(json.encode(hypermine.player.name))
    end,

    DELETE = function(req, resp)
      hypermine.player.name = ""
      hypermine.player.object = {}
      
      resp:statusCode(200)
      resp:addHeader("Content-Type", "application/json")
      resp:write(json.encode(hypermine.player.name))
    end
  },
  
}