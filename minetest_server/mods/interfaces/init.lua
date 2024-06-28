local Pegasus = require("pegasus")
local Router = require 'pegasus.plugins.router'
local json = require 'cjson.safe'

local Interfaces = {}

-- Change this to your player's name if necessary
Interfaces.player_name = "singlenode"

local function add_pos(pos_delta)
  minetest.log("info", "Received request to move " .. Interfaces.player_name .. " by " .. tostring(pos_delta))
  local player = minetest.get_player_by_name(Interfaces.player_name)
  local pos_old = player:get_pos()
  if not player then
    minetest.log("error", "No player with name "  .. Interfaces.player_name .. " found!")
  else
    local is_success, res = pcall(vector.add, pos_old, pos_delta)
    if is_success then
      player:move_to(res, true)
    else
      minetest.log("error", tostring(res))
    end
  end
end

local function get_pos()
  local player_name = Interfaces.player_name  -- Change this to your player's name if necessary
  local player = minetest.get_player_by_name(player_name)
  local pos = 0
  if player then
    pos = player:get_pos()
  end
  return pos
end

-- example data for the "router" plugin
local routes do
    routes = {
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
          local pos = get_pos()
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
            local is_to_api, res_to_api = pcall(add_pos, pos)
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
          resp:write(json.encode(get_pos()))
        end,
      },

      ["/player/name"] = {

        GET = function(req, resp)
          resp:statusCode(200)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(Interfaces.player_name))
        end,

        POST = function(req, resp)
          local res_code = 200
          -- JSON data send with curl contains escape characters
          local body = string.gsub(req:receiveBody(),"\\","*")
          local is_decoded, res_decode = pcall(json.decode, body)
          if is_decoded then
            Interfaces.player_name = res_decode.name
            minetest.log("warning", "You now control " .. Interfaces.player_name)
          else
            minetest.log("error", "Failed to set player name to " .. res_decode)
            -- TODO make this something sensible
            res_code = 422
          end
          resp:statusCode(res_code)
          resp:addHeader("Content-Type", "application/json")
          resp:write(json.encode(Interfaces.player_name))
        end,
      },
    }
end

local server = Pegasus:new({
    port = '9090',
    timeout = 0.1, -- prevent server from blocking
    plugins = {
        Router:new {
            prefix = "/api/v1/",
            routes = routes,
          },
    }
})

local server_co = coroutine.create(function ()
    server:start(function () return false end)
end)

minetest.register_globalstep(function(dtime)
    -- give control to the server
    coroutine.resume(server_co)
end)