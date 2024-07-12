hypermine.exploration = {
  types_unprotected = {
    [1] = "air",
    [2] = "airlike"
  },
  types_need_protection = {
    "basenodes:sand",
    "group:lava"
  },
  type_protected = "testnodes:glasslike"
}

local _log_point = "hym.exploration: "

local _protect_node = {
  pos = vector.zero,
  type = hypermine.exploration.type_protected,
  node = {}
}

local function _set_protect_node(pos)
  _protect_node.pos = pos + vector.new(0,1,0)
  _protect_node.node =  minetest.get_node(_protect_node.pos)
end

local function _protect(pos, trap_node)
  minetest.log("verbose", _log_point .. "add protection to " .. (dump(trap_node)))
  -- unclear if air nodes always have a name
  if _protect_node.node.name ~= _protect_node.type then
    -- nodes might be already covered by something, e.g. lava underground
    for _, type in pairs(hypermine.exploration.types_unprotected) do
      minetest.log("verbose", _log_point .. "covering trap node with " .. dump(_protect_node.type))
      minetest.swap_node(_protect_node.pos, { name = _protect_node.type})
    end
  end
end

local function _unprotect(pos, trap_node)
  minetest.log("verbose", _log_point .. "remove protection on trap node" .. (dump(pos)))
  minetest.swap_node(_protect_node.pos, {name = hypermine.exploration.types_unprotected[1]})
end

-- ABM to swap nodes above sand when the player is near
minetest.register_abm({
  label = "Cover Trap Nodes",
  nodenames = hypermine.exploration.types_need_protection,
  interval = 1.0,
  chance = 1,
  action = function(pos, node, active_object_count, active_object_count_wider)
    local players = minetest.get_connected_players()
    _set_protect_node(pos)
    for _, player in ipairs(players) do
      -- max walkspeed is 4
      if 6 > vector.distance(pos, player:get_pos()) then
        -- Danger! Player is near a trap node.
        _protect(pos, node)
      else
        _unprotect(pos, node)
      end
    end
  end,
})
