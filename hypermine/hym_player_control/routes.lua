local Router = require 'pegasus.plugins.router'
local json = require 'cjson.safe'

local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. "routes: "

function hypermine._decode_body(body)
  -- JSON data send with curl contains escape characters
  -- It does not seem to work in a single statement. Not sure why.
  local clean_string = string.gsub(body, "\\","*")
  local decoded = json.decode(clean_string)
  minetest.log("info", "hypermine: decoded body" .. dump(decoded))
  return decoded
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/player_control.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/routes_player_moveto.lua")
-- example data for the "router" plugin
hypermine.routes = {
      -- router-level preFunction runs before the method prefunction and callback
      preFunction = function(req, resp)
        local stop = false
        local headers = req:headers()
        local accept = (headers.accept or "*/*"):lower()
        if not accept:find("application/json", 1, true) and
           not accept:find("application/*", 1, true) and
           not accept:find("*/*", 1, true) then

          resp:writeDefaultErrorMessage(406, "This API only produces 'application/json'")
          stop = true
        end
        return stop
      end,
      
      ["/player/position"] = {

        GET = function(req, resp)
          resp:statusCode(200)
          resp:addHeader("Content-Type", "application/json")
          local pos = hypermine.get_pos()
          resp:write(json.encode(pos))
        end,

        POST = function(req, resp)
          local res_code = 200
          local pos = {}
          -- JSON data send with curl contains escape characters
          local body = string.gsub(req:receiveBody(),"\\","*")
          local is_decoded, res_decode = pcall(json.decode, body)
          if is_decoded then
            pos = vector.new(res_decode.position)
            local is_to_api, res_to_api = pcall(hypermine.add_pos, pos)
            if is_to_api then
              res_code = 200
            else
              res_code = 500
              minetest.log("error", "Could not forward request to API")
              minetest.log("error", dump(res_to_api))
            end
          else
            -- TODO make this something sensible
            res_code = 422
          end
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(hypermine.get_pos()))
        end,

        PUT = function(req, resp)
          local res_code = 200
          local pos = {}
          -- JSON data send with curl contains escape characters
          local body = string.gsub(req:receiveBody(),"\\","*")
          local is_decoded, res_decode = pcall(json.decode, body)
          if is_decoded then
            pos = vector.new(res_decode.position)
            local is_to_api, res_to_api = pcall(hypermine.player.object.set_pos,hypermine.player.object, pos)
            if is_to_api then
              res_code = 200
            else
              res_code = 500
              minetest.log("error", "Could not forward request to API")
              minetest.log("error", dump(res_to_api))
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

      ["/player/name"] = {

        GET = function(req, resp)
          resp:statusCode(200)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(hypermine.player.name))
        end,

        POST = function(req, resp)
          local res_code = 200
          local decoded = hypermine._decode_body(req:receiveBody())
          if decoded.name then
            local status, result = pcall(hypermine.set_player, decoded.name)
            if status then
              minetest.log("info", "Hypermine: took control over " .. hypermine.player.name)
            else
              minetest.log("error", "Hypermine: unable to take control over player ")
              minetest.log("error", result)
              res_code = 400
            end
          else
            minetest.log("error", "Hypermine: unable to extract name from request body")
            -- TODO make this something sensible
            res_code = 400
          end
          
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(hypermine.player.name))
        end,
      },
}

for k,v in pairs(hypermine.player_moveto.routes) do hypermine.routes[k] = v end

hypermine.server = hypermine.server or {}
hypermine.server.plugins = {
  Router:new {
      prefix = "/api/v1/",
      routes = hypermine.routes,
  },
}