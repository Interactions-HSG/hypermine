local Router = require 'pegasus.plugins.router'
local json = require 'cjson.safe'

--TODO: ideally routes should not call the minetest API
local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. ".routes: "

function hypermine._decode_body(body)
  -- JSON data send with curl contains escape characters
  local clean_string = string.gsub(body, "\\","*")
  local decoded = json.decode(clean_string)
  minetest.log("verbose", _log_point .. "decoded body" .. dump(decoded))
  return decoded
end

--TODO: ideally routes should not call the minetest API
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/player_control.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/routes_player_moveto.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/routes_player_name.lua")

local _decoded = {}

-- example data for the "router" plugin
hypermine.routes = {

      ["/player/position"] = {

        -- router-level preFunction runs before the method prefunction and callback
        preFunction = function(req, resp)
          local stop = false
          minetest.log("info", _log_point .. "received on " .. req.routerPath)
          _decoded = hypermine._decode_body(req:receiveBody())
          --TODO: ideally routes should not call the minetest API
          if not minetest.get_player_by_name(hypermine.player.name) then
            stop = true
            local err =  _log_point .. "player with name \"" .. hypermine.player.name .. "\" is invalid"
            minetest.log("error", err)
            resp:writeDefaultErrorMessage(404, err)
          end
          return stop
        end,

        postFunction = function(req, resp)
          _decoded = {}
        end,

        GET = function(req, resp)
          resp:statusCode(200)
          resp:addHeader("Content-Type", "application/json")
          local pos = hypermine.get_pos()
          resp:write(json.encode(pos))
        end,

        POST = function(req, resp)
          local res_code = 200
          local pos = {}

          if _decoded.position then
            pos = vector.new(_decoded.position)

            local is_to_api, res_to_api = pcall(hypermine.add_pos, pos)
            if is_to_api then
              res_code = 200
            else
              res_code = 500
              minetest.log("error", _log_point .. "could not forward request to API")
              minetest.log("error", dump(res_to_api))
            end
          else
            -- TODO make this something sensible
            res_code = 422
          end
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          
          if 200 == res.code then 
            resp:write(json.encode(hypermine.get_pos()))
          elseif 200 < res_code then
            resp:write(json.encode({}))
          end
        end,

        PUT = function(req, resp)
          local res_code = 500
          local pos = {}
          -- JSON data send with curl contains escape characters
          if _decoded.position then
            pos = vector.new(_decoded.position)
            if minetest.get_player_by_name(hypermine.player.name) then
              local status, result = pcall(hypermine.player.object.set_pos, hypermine.player.object, pos)
              if status then
                res_code = 200
              else
                res_code = 500
                minetest.log("error", _log_point .. "could not forward request to API")
                minetest.log("error", dump(result))
              end
            else
              minetest.log("error", _log_point .. "")
              res_code = 422
            end
          else
            -- TODO make this something sensible
            res_code = 422
          end
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          
          if 200 == res_code then 
            resp:write(json.encode(hypermine.get_pos()))
          else
            resp:write(json.encode({}))
          end
        end,
      },

      ["/player/velocity"] = {

        GET = function(req, resp)
          resp:statusCode(200)
          resp:addHeader("Content-Type", "application/json")
          local pos = hypermine.get_velocity()
          resp:write(json.encode(pos))
        end,

        POST = function(req, resp)
          local res_code = 200
          local velocity = {}
          -- JSON data send with curl contains escape characters
          local body = string.gsub(req:receiveBody(),"\\","*")
          local is_decoded, res_decode = pcall(json.decode, body)
          if is_decoded then
            if res_decode.velocity then
              velocity = vector.new(res_decode.velocity)
              local is_to_api, res_to_api = pcall(hypermine.add_velocity, velocity)
              if is_to_api then
                res_code = 200
              else
                res_code = 500
                minetest.log("error", "Could not forward request to API")
                minetest.log("error", dump(res_to_api))
              end
            else
              res_code = 400
              minetest.log("error", "This endpoint the velocity requires a field velocity. Got:\n")
              minetest.log("error", body)
            end
          else
            -- TODO make this something sensible
            res_code = 422
          end
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(hypermine.get_pos()))
        end,
      },


}

for k,v in pairs(hypermine.player_moveto.routes) do hypermine.routes[k] = v end
for k,v in pairs(hypermine.player_name.routes) do hypermine.routes[k] = v end

hypermine.server = hypermine.server or {}
hypermine.server.plugins = {
  Router:new {
      prefix = "/api/v1/",
      routes = hypermine.routes,
  },
}