-- hypermine = hypermine or {}
-- Change this to your player's name if necessary
hypermine.player_name = "singlenode"

function hypermine.add_velocity(delta)
  -- Changing velocity is eqaul to key press for one loop
  -- See https://api.minetest.net/class-reference/#methods_8
  minetest.log("info", "Received request to change velocity of " .. hypermine.player_name .. " by " .. tostring(delta))
  local player = minetest.get_player_by_name(hypermine.player_name)
  if not player then
    minetest.log("error", "No player with name "  .. hypermine.player_name .. " found!")
  else
    -- same set_pos on player objects
    local is_to_minetest_success, result = pcall(player.add_velocity, player, delta)
    if not is_to_minetest_success then
      minetest.log("error", tostring(result))
    end
  end
end

function hypermine.add_pos(pos_delta)
  minetest.log("info", "Received request to move " .. hypermine.player_name .. " by " .. tostring(pos_delta))
  local player = minetest.get_player_by_name(hypermine.player_name)
  if not player then
    minetest.log("error", "No player with name "  .. hypermine.player_name .. " found!")
  else
    local pos_old = player:get_pos()
    local is_success, res = pcall(vector.add, pos_old, pos_delta)
    if is_success then
      -- same set_pos on player objects
      player:move_to(res, true)
    else
      minetest.log("error", tostring(res))
    end
  end
end

function hypermine.get_velocity()
  local player_name = hypermine.player_name  -- Change this to your player's name if necessary
  local player = minetest.get_player_by_name(player_name)
  local velocity = 0
  if player then
    velocity = player:get_pos()
  end
  return velocity
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