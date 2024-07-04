local Router = require 'pegasus.plugins.router'
local json = require 'cjson.safe'

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/player_control.lua")

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
      },

      ["/player/name"] = {

        GET = function(req, resp)
          resp:statusCode(200)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(hypermine.player_name))
        end,

        POST = function(req, resp)
          local res_code = 200
          -- JSON data send with curl contains escape characters
          local body = string.gsub(req:receiveBody(),"\\","*")
          local is_decoded, res_decode = pcall(json.decode, body)
          if is_decoded then
            hypermine.player_name = res_decode.name
            minetest.log("warning", "You now control " .. hypermine.player_name)
          else
            minetest.log("error", "Failed to set player name to " .. res_decode)
            -- TODO make this something sensible
            res_code = 422
          end
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(hypermine.player_name))
        end,
      },
    }

    hypermine.server = hypermine.server or {}
    hypermine.server.plugins = {
      Router:new {
          prefix = "/api/v1/",
          routes = hypermine.routes,
    },
}