local json = require 'cjson.safe'

hypermine.player_moveto = {}
hypermine.player_moveto.routes = {}

hypermine.player_moveto.routes = {
  ["/player/move_to"] = {
    -- GET = function(req, resp)
    --     resp:statusCode(200)
    --     resp:addHeader("Content-Type", "application/json")
    --     local pos = hypermine.get_velocity()
    --     resp:write(json.encode(pos))
    --     end,

    POST = function(req, resp)
      local res_code = 200
      local dest = {}
      -- JSON data send with curl contains escape characters
      local decode = hypermine._decode_body(req:receiveBody())

      if decode.location then
        hypermine.move_to(decode.location)
      --   minetest.log("error", "player/move_to.vector: " .. dump(vector.new(decode.location)))
      --   local pos = hypermine.get_pos()
      --   minetest.log("error", "player/move_to.get_pos: " .. dump(pos))
      --   -- local status, result = pcall(
      --   --   -- vector.direction,
      --   --   hypermine.player.get_pos
      --   --   -- vector.new(decode.location)
      --   -- )
      else
        minetest.log("error", "Hypermine: unable to extract location from request body")
        -- TODO make this something sensible
        res_code = 400
      end


      -- if is_decoded then
      --   if res_decode.velocity then
      --   velocity = vector.new(res_decode.velocity)
      --   local is_to_api, res_to_api = pcall(hypermine.add_velocity, velocity)
      --   if is_to_api then
      --     res_code = 200
      --   else
      --     res_code = 500
      --     minetest.log("error", "Could not forward request to API")
      --     minetest.log("error", dump(res_to_api))
      --   end
      --   else
      --     res_code = 400
      --     minetest.log("error", "This endpoint the velocity requires a field velocity. Got:\n")
      --     minetest.log("error", decode)
      --   end
      -- else
      --   -- TODO make this something sensible
      --   res_code = 422
      -- end
      resp:statusCode(res_code)
      resp:addHeader("Content-Type", "application/json")
      resp:write(json.encode(hypermine.get_pos()))
    end,
  }
}