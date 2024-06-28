local register_node = minetest.register_node
local register_alias = minetest.register_alias


register_node('void_essential:stone', {
    description = 'Essential node for mapgen alias “mapgen_stone”',
    tiles = { 'void_essential_stone.png' },
    groups = { oddly_breakable_by_hand = 3 },
    is_ground_content = true
})

register_node('void_essential:water_source', {
    description = 'Essential node for mapgen alias “mapgen_water_source”',
    tiles = { 'void_essential_water_source.png' },
    groups = { oddly_breakable_by_hand = 3 },
    is_ground_content = true
})

register_node('void_essential:river_water_source', {
    description = 'Essential node for mapgen alias “mapgen_river_water_source”',
    tiles = { 'void_essential_river_water_source.png' },
    groups = { oddly_breakable_by_hand = 3 },
    is_ground_content = true
})


register_alias('mapgen_stone', 'void_essential:stone')
register_alias('mapgen_water_source', 'void_essential:water_source')
register_alias('mapgen_river_water_source', 'void_essential:river_water_source')
