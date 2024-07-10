-- hypermine = hypermine or {}
-- Change this to your player's name if necessary
-- hypermine.player.name = "singlenode"
hypermine.player = {
  name = "singlenode",
  object = {},
  max_velocity = 4,
  move_to = {}
}



function hypermine.set_player(player_name)
  local player = minetest.get_player_by_name(player_name)
  if player then
    hypermine.player.name = player_name
    hypermine.player.object = player
    local meta = player:get_meta()
    minetest.log("warning", "hypermine: metadataref "  .. dump(meta:to_table()))
  else
    error("No player with name " .. player_name .. " found", hypermine._caller_level)
  end
end

function hypermine.add_velocity(delta)
  -- Changing velocity is eqaul to key press for one loop
  -- See https://api.minetest.net/class-reference/#methods_8
  minetest.log("warning", "Received request to change velocity of " .. hypermine.player.name .. " by " .. tostring(delta))
  local player = minetest.get_player_by_name(hypermine.player.name)
  if not player then
    minetest.log("error", "No player with name "  .. hypermine.player.name .. " found!")
  else
    -- same set_pos on player objects
    local is_to_minetest_success, result = pcall(player.add_velocity, player, delta)
    if not is_to_minetest_success then
      minetest.log("error", tostring(result))
    end
  end
end

function hypermine.add_pos(pos_delta)
  minetest.log("info", "Received request to move " .. hypermine.player.name .. " by " .. tostring(pos_delta))
  local player = minetest.get_player_by_name(hypermine.player.name)
  if not player then
    minetest.log("error", "No player with name "  .. hypermine.player.name .. " found!")
  else
    local pos_old = player:get_pos()
    local is_success, res = pcall(vector.add, pos_old, pos_delta)
    if is_success then
      -- same set_pos on player objects
      -- player:move_to(res, true)
      print(dump(player))
      player:add_pos(pos_delta)
    else
      minetest.log("error", tostring(res))
    end
  end
end

function hypermine.get_velocity()
  local player_name = hypermine.player.name  -- Change this to your player's name if necessary
  local player = minetest.get_player_by_name(player_name)
  local velocity = vector.zero()
  if player then
    velocity = player:get_velocity()
  end
  return velocity
end

function hypermine.get_pos()
  local pos = 0
  if hypermine.player then
    pos = hypermine.player.object:get_pos()
  else
    minetest.log("error", "Could not get player"  .. hypermine.player.name)
  end
  return pos
end

function hypermine.look_at_pos(pos)
  minetest.log("info", "hypermine.look_at_pos.pos: " .. dump(pos))

  local status_old_pos, result_old_pos = pcall(hypermine.get_pos)
  local status, result = pcall(
    vector.direction,
    result_old_pos,
    pos
  )
  if status then
    minetest.log("info", "good " .. dump(result))
  else
    minetest.log("info", "bad " .. dump(result))
  end

  hypermine.player.object:set_look_horizontal(
    vector.angle(vector.new(0,0,1), result)
  )
end

function hypermine.move_to(pos)
  minetest.log("warning", "starting co")
  local tolerance = 0.1
  local vec_dir = vector.zero()
  local vec_vel = vector.zero()
  local vec_acc = vector.zero()
  hypermine.look_at_pos(pos)

  hypermine.player.move_to = vector.new(pos)
  
  local function _move_to()
    minetest.log("warning", "running co"  .. "move_to")
    while true do
      local dist = vector.distance(pos, hypermine.player.object:get_pos())
      minetest.log("warning", "hypermine: 1 - distance to destination is "  .. dump(tolerance))
      local status, result = pcall(math.abs, dist)
      if math.abs(dist) < tolerance then
        break
      end
      local vec_dir = vector.direction(hypermine.player.object:get_pos(), pos)
      local vec_vel = hypermine.player.object:get_velocity()
      local vec_acc = vector.zero()

      -- acceleration logic
      --TODO: review which logic makes the most sense and remove the others
      if false then
        local vec_acc = (hypermine.player.max_velocity * vec_dir) - vec_vel
        -- According to https://api.minetest.net/class-reference/#methods_8, velocity will be normalized
        hypermine.player.object:add_velocity(vec_acc)
      elseif true then
        if vector.length(vec_vel) < hypermine.player.max_velocity then
          vec_acc = hypermine.player.max_velocity * vec_dir
        else
          vec_acc = vector.zero()
        end
        -- According to https://api.minetest.net/class-reference/#methods_8, velocity will be normalized
        hypermine.player.object:add_velocity(vec_acc)
      elseif false then
        -- According to https://api.minetest.net/class-reference/#methods_8, velocity will be normalized
        hypermine.player.object:set_velocity(hypermine.player.max_velocity * vec_dir)
        -- velocity does not change
      end

      --TODO: review which logging makes sense and set level to "trace" 
      if false then
        -- Just logging
        minetest.log("warning", "hypermine: vec_acc: "  .. dump(vec_acc))
        minetest.log("warning", "hypermine: magnitude of vec_acc : "  .. dump(vector.length(vec_acc)))
        -- should be 1
        minetest.log("warning", "hypermine: magnitude of dir is "  .. dump(
          vector.length(vec_dir)
        ))
        minetest.log("warning", "hypermine: current velocity of selected player "  .. dump(
          vector.length(hypermine.player.object:get_velocity())
        ))
        minetest.log("warning", "hypermine: magnitude of current velocity of selected player "  .. dump(
          vector.length(vec_vel)
        ))
      end
      coroutine.yield()
    end
  end
  
  local res_co = coroutine.create(_move_to)
  hypermine.Dispatcher.register_coroutine(res_co, "move_to")
end
  
