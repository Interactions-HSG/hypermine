local _log_point = hypermine._log_prefix .. "." .. minetest.get_current_modname() .. ".player_control: "

hypermine.player = {
  name = "",
  object = {},
  max_velocity = 4,
  move_to = {}
}

local _registered_tasks = {
  --[[
  [1] = {
    player = "agent0"
    status = "SUBMITTED", -- or ,INPROGESS,COMPLETED
    distance = vector.zero
  }
  --]]
}
local _task_counter = 0

function hypermine.get_task(task)
  return _registered_tasks[task]
end

function hypermine.get_task_update(ntask)
  _registered_tasks.player = hypermine.player.name
  if player.move_to then
    _registered_tasks[ntask].status = "INPROGRESS"
    _registered_tasks[ntask].distance = vector.distance(
      hypermine.get_pos(),
      hypermine.player_moveto
    )
  else
    _registered_tasks[ntask].status = "COMPLETED"
    _registered_tasks[ntask].distance = {}
  end
end

function hypermine.register_task()
  _task_counter = 1 + _task_counter
  _registered_tasks[_task_counter] = {
    player = hypermine.player.name,
    status = "SUBMITTED",
    distance = {}
  }

  return _task_counter
end

function hypermine.set_player(player_name)
  local player = minetest.get_player_by_name(player_name)
  if player then
    hypermine.player.name = player_name
    hypermine.player.object = player
  else
    error(_log_point .. "no player with name " .. player_name .. " found", hypermine._caller_level)
  end
end

function hypermine.add_velocity(delta)
  -- Changing velocity is eqaul to key press for one loop
  -- See https://api.minetest.net/class-reference/#methods_8
  local player = minetest.get_player_by_name(hypermine.player.name)
  if not player then
    minetest.log("error", _log_point .. "no player with name "  .. hypermine.player.name .. " found!")
  else
    minetest.log("info", _log_point .. "changing velocity of " .. hypermine.player.name .. " by " .. tostring(delta))
    -- same set_pos on player objects
    local is_to_minetest_success, result = pcall(player.add_velocity, player, delta)
    if not is_to_minetest_success then
      minetest.log("error", _log_point .. tostring(result))
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
      player:move_to(res, true)
      -- print(dump(player))
      -- player:add_pos(pos_delta)
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
  local pos = vector.zero()
  if hypermine.player then
    local status, result = pcall(hypermine.player.object.get_pos, hypermine.player.object)
    if status then
      pos = result
    else
      minetest.log("error", _log_point .. "could not get position from player" .. hypermine.player.name)
    end
  else
    minetest.log("error", _log_point .. "could not get player"  .. hypermine.player.name)
  end
  return pos
end

function hypermine.look_at_pos(destination)
  minetest.log("verbose", _log_point .. dump(destination))

  -- hypermine.get_pos() has some error handling
  local pos = hypermine.get_pos()
  local dir = vector.direction(pos, destination)

  hypermine.player.object:set_look_horizontal(
    vector.angle(vector.new(0,0,1), dir)
  )
end

local function _move_to()
  minetest.log("verbose", _log_point .. "moving player.")
  local tolerance = 0.1
  local vec_dir = vector.zero()
  local vec_vel = vector.zero()
  local vec_acc = vector.zero()
  local dist = vector.zero()
  
  while true do
    dist = vector.distance(hypermine.player.move_to, hypermine.get_pos())
    if math.abs(dist) < tolerance then
      break
    end
    vec_dir = vector.direction(hypermine.player.object:get_pos(), hypermine.player.move_to)
    vec_vel = hypermine.player.object:get_velocity()
    vec_acc = vector.zero()

    -- acceleration logic
    if vector.length(vec_vel) < hypermine.player.max_velocity then
      vec_acc = hypermine.player.max_velocity * vec_dir
    else
      vec_acc = vector.zero()
    end
    -- According to https://api.minetest.net/class-reference/#methods_8, velocity will be normalized
    hypermine.player.object:add_velocity(vec_acc)
    coroutine.yield()
  end
end

function hypermine.move_to(pos)
  minetest.log("info", _log_point .. "creating coroutine "  .. _co_name)
  local _co_name = "move_to"
  hypermine.look_at_pos(pos)
  hypermine.player.move_to = vector.new(pos)
  
  local _co = coroutine.create(_move_to)
  hypermine.Dispatcher.register_coroutine(_co, _co_name)
end
  
