local json = require 'cjson.safe'

local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. "routes_player_moveto: "

hypermine.player_moveto = {}
hypermine.player_moveto.routes = {}

hypermine.player_moveto.routes = {
  ["/player/move_to"] = {

    POST = function(req, resp)
      minetest.log("verbose", _log_point .. "received POST to move player")
      local res_code = 200
      -- JSON data send with curl contains escape characters
      local decode = hypermine._decode_body(req:receiveBody())

      if decode.location then
        hypermine.move_to(decode.location)
      else
        minetest.log("error", _log_point .. "unable to extract location from request body")
        -- TODO make this something sensible
        res_code = 400
      end
      resp:statusCode(res_code)
      resp:addHeader("Content-Type", "application/json")
      resp:write(json.encode(hypermine.get_pos()))
    end,
  }
}