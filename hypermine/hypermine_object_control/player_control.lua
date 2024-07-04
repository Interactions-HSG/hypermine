-- hypermine = hypermine or {}
-- Change this to your player's name if necessary
hypermine.player_name = "singlenode"

function hypermine.add_pos(pos_delta)
  minetest.log("info", "Received request to move " .. hypermine.player_name .. " by " .. tostring(pos_delta))
  local player = minetest.get_player_by_name(hypermine.player_name)
  local pos_old = player:get_pos()
  if not player then
    minetest.log("error", "No player with name "  .. hypermine.player_name .. " found!")
  else
    local is_success, res = pcall(vector.add, pos_old, pos_delta)
    if is_success then
      player:move_to(res, true)
      player:add_velocity(pos_delta)
    else
      minetest.log("error", tostring(res))
    end
  end
end

function hypermine.get_pos()
  local player_name = hypermine.player_name  -- Change this to your player's name if necessary
  local player = minetest.get_player_by_name(player_name)
  local pos = 0
  if player then
    pos = player:get_pos()
  end
  return pos
end