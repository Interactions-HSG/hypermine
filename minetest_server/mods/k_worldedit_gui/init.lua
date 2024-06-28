local S = minetest.get_translator("k_worldedit_gui")
local gui = flow.widgets

local boxSpacing = 0.1
local boxPadding = 0
k_worldedit_gui = {
    cmdList = {},
    nodeList = {},
    playerCmdList = {},
    contexts = {},
    forms = {},
}

local cmdGui = {
    event = {}
}

--@return vector
k_worldedit_gui.avgPos = function(x, y, z)
    if "table" == type(x) then
        x, y, z = x.x, x.y, x.z
    end
    x, y, z = math.floor(x + 0.5), math.floor(y + 0.5), math.floor(z + 0.5)
    return vector.new(x, y, z)
end

--[[
Handle on_use events.

@param player
@pt pointed thing
]]
k_worldedit_gui.doWandStuff = function(player, pt)
    if
        nil == pt
        or nil == pt.type
    then
        return
    end

    local playerName = player:get_player_name()
    local newPos = nil
    if "node" == pt.type then
        if player:get_player_control().aux1 then
            newPos = k_worldedit_gui.avgPos(pt.above)
        else
            newPos = k_worldedit_gui.avgPos(pt.under)
        end
    elseif
        "object" == pt.type
        and nil ~= pt.ref:get_luaentity()
        and string.match(pt.ref:get_luaentity().name, 'worldedit:pos%d')
    then
        newPos = k_worldedit_gui.avgPos(pt.ref:get_pos())
    else
        return
    end

    -- check if there's a nil position
    local distances = {}
    for i = 1, 2, 1 do
        local posstr = "pos" .. i
        if nil == worldedit[posstr][playerName] then
            worldedit[posstr][playerName] = newPos
            worldedit.marker_update(playerName)
            return
        end
        -- calc distance from new pos
        distances[i] = vector.distance(newPos, worldedit[posstr][playerName])
    end

    -- find marker closest to newPos
    if 0 == distances[1] or 0 == distances[2] then
        worldedit.pos1[playerName] = newPos
        worldedit.pos2[playerName] = newPos
    elseif distances[1] == distances[2] then
        -- inteterminate?
        -- @todo maybe use player pos as tie breaker
        local randpos = "pos" .. math.random(2)
        worldedit[randpos][playerName] = newPos
    elseif distances[1] > distances[2] then
        worldedit.pos2[playerName] = newPos
    else
        worldedit.pos1[playerName] = newPos
    end

    worldedit.marker_update(playerName)
end

k_worldedit_gui.clearRegionSelection = function(player, ctx)
    local playerName = player:get_player_name()
    worldedit.pos1[playerName] = nil
    worldedit.pos2[playerName] = nil
    worldedit.marker_update(playerName)
    ctx.message = S("Region selection cleared.")
    return true
end

cmdGui.parseParam = function(player, ctx)
    local params = ctx.form.params
    local replacements = {}

    replacements["<node1>"] = k_worldedit_gui.nodeList[ctx.form.node1]
    replacements["<node2>"] = k_worldedit_gui.nodeList[ctx.form.node2]
    replacements["<node3>"] = k_worldedit_gui.nodeList[ctx.form.node3]
    replacements["<node4>"] = k_worldedit_gui.nodeList[ctx.form.node4]

    for srch, rep in pairs(replacements) do
        params = string.gsub(params, srch, rep)
    end
    return params
end

cmdGui.event.ok = function(player, ctx)
    -- print("ok" .. dump(ctx))
    local cmdName    = ctx.cmd
    local playerName = player:get_player_name()

    local param      = cmdGui.parseParam(player, ctx)
    -- reset some
    ctx.message      = nil
    ctx.needConfirm  = false

    -- shameless borrowing from worldedit. See chatcommand_handler()
    local def        = assert(worldedit.registered_commands[cmdName])

    if def.require_pos == 2 then
        local pos1, pos2 = worldedit.pos1[playerName], worldedit.pos2[playerName]
        if pos1 == nil or pos2 == nil then
            -- worldedit.player_notify(playerName, S("no region selected"))
            ctx.message = S("no region selected")
            return true
        end
    elseif def.require_pos == 1 then
        local pos1 = worldedit.pos1[playerName]
        if pos1 == nil then
            -- worldedit.player_notify(playerName, S("no position 1 selected"))
            ctx.message = S("no position 1 selected")
            return true
        end
    end

    local parsed = { def.parse(param) }
    local success = table.remove(parsed, 1)
    if not success then
        -- worldedit.player_notify(playerName, parsed[1] or S("invalid usage"))
        ctx.message = parsed[1] or S("invalid usage")
        return true
    end

    if def.nodes_needed then
        local count = def.nodes_needed(playerName, unpack(parsed))
        -- safe check a bit lower than world edit but whatever.
        if count > 16384 and true ~= ctx.form.confirmed then
            ctx.needConfirm = true
            ctx.message = S("WARNING: this operation could affect up to @1 nodes; check 'Confirm' to continue.", count)
            return true
        end
    end
    -- no "safe region" check
    local _, msg = def.func(playerName, unpack(parsed))
    cmdGui.populateMarkerPos(player, ctx) -- in case set by pos1, pos2 commands
    if msg then
        minetest.chat_send_player(playerName, msg)
        ctx.message = msg
    end
    return true
end

cmdGui.event.back = function(player, ctx)
    ctx.message = nil
    cmdGui.showCmdListForm(player)
end

cmdGui.event.setPos = function(pos, player, ctx)
    -- print("setpos " .. pos .. dump(ctx))
    local playerName = player:get_player_name()

    local ps = string.split(pos, "_pos_")

    local thing = ps[1]
    local p = "pos" .. ps[2]
    local playerpos = k_worldedit_gui.avgPos(player:get_pos())
    if "player" == thing then
        worldedit[p][playerName] = vector.new(playerpos.x, playerpos.y, playerpos.z)
    elseif "set" == thing then
        worldedit[p][playerName] = vector.new(
        --@todo defaults to playpos or zero?
            tonumber(ctx.form[p .. "_x"]) or playerpos.x,
            tonumber(ctx.form[p .. "_y"]) or playerpos.y,
            tonumber(ctx.form[p .. "_z"]) or playerpos.z
        )
    elseif "clear" == thing then
        worldedit[p][playerName] = nil
    end

    worldedit.marker_update(playerName)
    cmdGui.populateMarkerPos(player, ctx)
    return true
end

cmdGui.populateMarkerPos = function(player, ctx)
    local playerName = player:get_player_name()

    if nil == ctx.form then
        ctx.form = {}
    end

    for _, posNum in pairs({ '1', '2' }) do
        for _, coord in pairs({ 'x', 'y', 'z' }) do
            ctx.form["pos" .. posNum .. "_" .. coord] = ""
            if
                nil ~= worldedit["pos" .. posNum][playerName]
                and nil ~= worldedit["pos" .. posNum][playerName][coord]
            then
                ctx.form["pos" .. posNum .. "_" .. coord] = "" .. worldedit["pos" .. posNum][playerName][coord]
            end
        end
    end
    -- worldedit.marker_update(playerName)
end

cmdGui.buildPosDefForm = function(pos, player, ctx)
    cmdGui.populateMarkerPos(player, ctx)
    return gui.HBox({
        spacing = boxSpacing,
        padding = boxPadding,
        gui.Label { label = S("Pos " .. pos .. " (x,y,z):"), w = 1.25, h = 0.5, },
        gui.Field { name = "pos" .. pos .. "_x", w = 1.25, h = 0.5, },
        gui.Field { name = "pos" .. pos .. "_y", w = 1.25, h = 0.5, },
        gui.Field { name = "pos" .. pos .. "_z", w = 1.25, h = 0.5, },
        gui.Button { name = "set_pos_" .. pos, on_event = function(player, ctx) return cmdGui.event.setPos("set_pos_" .. pos, player, ctx) end, label = S("S"), w = 0.5, h = 0.5, },
        gui.Tooltip { tooltip_text = S("Set pos " .. pos), gui_element_name = "set_pos_" .. pos, },
        gui.Button { name = "clear_pos_" .. pos, on_event = function(player, ctx) return cmdGui.event.setPos("clear_pos_" .. pos, player, ctx) end, label = S("C"), w = 0.5, h = 0.5, },
        gui.Tooltip { tooltip_text = S("Clear pos " .. pos), gui_element_name = "clear_pos_" .. pos, },
        gui.Button { name = "player_pos_" .. pos, on_event = function(player, ctx) return cmdGui.event.setPos("player_pos_" .. pos, player, ctx) end, label = S("P"), w = 0.5, h = 0.5, },
        gui.Tooltip { tooltip_text = S("Set pos " .. pos .. " to player position"), gui_element_name = "player_pos_" .. pos, },

    })
end


cmdGui.buildCmdLaunchForm = function(player, ctx)
    local cmd = ctx.cmd

    cmdGui.populateMarkerPos(player, ctx)

    --print("build" .. dump(ctx))
    local cmdDef = worldedit.registered_commands[cmd]
    local playerName = player:get_player_name()

    local hasParams = ("string" == type(cmdDef.params) and 0 ~= string.len(cmdDef.params))

    -- minetest 5.7+
    -- local windowInfo = minetest.get_player_window_information(playerName)
    local maxWidth = hasParams and 16 or 8 --windowInfo.max_formspec_size.x - 2
    local maxTextWidth = maxWidth * 16     -- just a guess

    local guiNil = gui.Nil {}
    local labelCol = 1.4
    local guiDef = {
        spacing = boxSpacing,
        padding = 0.2,
        w = maxWidth,
        gui.StyleType {
            selectors = { "*" },
            props = {
                font_size = "12",
            }
        },
        gui.HBox({
            spacing = boxSpacing,
            padding = boxPadding,
            gui.Hypertext({
                w = 6,
                h = 1,
                text = "<bigger><b>" .. cmd .. "</b></bigger>",
                name = "header",
            })
        }),

        gui.HBox({
            spacing = boxSpacing,
            padding = boxPadding,

            hasParams and gui.Label({ label = S("Command\nParameters:"), align_v = "top", w = labelCol, }) or guiNil,

            gui.Style {
                selectors = { "params" },
                props = {
                    font_size = "+2",
                    font      = "mono",
                }
            },
            hasParams and gui.Textarea({ name = "params", w = 6, h = 5, align_v = "top" }) or guiNil,

            gui.VBox({
                spacing = boxSpacing,
                padding = boxPadding,

                cmdGui.buildPosDefForm(1, player, ctx),
                cmdGui.buildPosDefForm(2, player, ctx),

                hasParams and gui.Label { label = S("Placeholders:"), w = 1.5, h = 0.5, } or guiNil,
                hasParams and gui.HBox({
                    gui.Label { label = S("<node1>:"), w = 1, h = 0.5, },
                    gui.Dropdown { name = "node1", items = k_worldedit_gui.nodeList, index_event = true, w = 7, h = 0.5 },
                }) or guiNil,
                hasParams and gui.HBox({
                    gui.Label { label = S("<node2>:"), w = 1, h = 0.5, },
                    gui.Dropdown { name = "node2", items = k_worldedit_gui.nodeList, index_event = true, w = 7, h = 0.5 },
                }) or guiNil,
                hasParams and gui.HBox({
                    gui.Label { label = S("<node3>:"), w = 1, h = 0.5, },
                    gui.Dropdown { name = "node3", items = k_worldedit_gui.nodeList, index_event = true, w = 7, h = 0.5 },
                }) or guiNil,
                hasParams and gui.HBox({
                    gui.Label { label = S("<node4>:"), w = 1., h = 0.5, },
                    gui.Dropdown { name = "node4", items = k_worldedit_gui.nodeList, index_event = true, w = 7, h = 0.5 },
                }) or guiNil,

            }),
        }),

        ("string" == type(cmdDef.params) and 0 ~= string.len(cmdDef.params))
        and gui.HBox({
            spacing = boxSpacing,
            padding = boxPadding,
            gui.Label({ label = S("Params hint: "), align_v = "top", w = labelCol, }),
            gui.Label({ label = cmdDef.params, align_v = "top", }),
        })
        or gui.Nil({}),

        gui.HBox({
            spacing = boxSpacing,
            padding = boxPadding,
            gui.Label({ label = S("Description: "), align_v = "top", w = labelCol, }),
            gui.Hypertext({
                name = "cmd_description",
                text = "<style size=12>" .. cmdDef.description .. "</style>",
                h = 0.75 * math.ceil(string.len(cmdDef.description) / maxTextWidth),
                w = maxWidth - labelCol,
                align_v = "top",
            }),
        }),

    }

    table.insert(guiDef, gui.HBox({
        spacing = boxSpacing,
        padding = boxPadding,

        gui.Spacer {},

        ctx.needConfirm and gui.Checkbox({ label = S("Confirm Unsafe"), name = "confirmed" }) or gui.Nil({}),
        gui.Button({
            label = S("RUN"),
            name = "ok",
            on_event = function(player, ctx)
                ctx.cmd = cmd
                return cmdGui.event.ok(player, ctx)
            end,
        }),
        gui.ButtonExit({ label = S("Back"), on_event = cmdGui.event.back, name = "back", }),
        gui.ButtonExit({ label = S("Close"), name = "cancel", }),

    }))

    if nil ~= ctx.message then
        table.insert(guiDef, gui.HBox({
            spacing = boxSpacing,
            padding = boxPadding,
            gui.Label({ label = S("Messages: "), w = labelCol, align_v = "top" }),
            gui.Hypertext({ name = "message_text", text = ctx.message, h = math.ceil(string.len(ctx.message) / maxTextWidth), w = maxWidth - labelCol }),

        }))
        ctx.message = nil
    end

    -- save current context

    k_worldedit_gui.contexts[playerName][cmd] = ctx

    return gui.VBox(guiDef)
end

cmdGui.showCmdLaunchForm = function(player, cmd)
    --print(dump("show" .. cmd))
    local playerName = player:get_player_name()

    -- reload saved
    local ctx = k_worldedit_gui.contexts[playerName][cmd] or {}
    ctx.cmd = cmd
    local leGuy = flow.make_gui(cmdGui.buildCmdLaunchForm)

    k_worldedit_gui.forms[playerName].cmd = leGuy

    leGuy:show(player, ctx)
end

cmdGui.event.selectCmdFromList = function(player, ctx)
    cmdGui.showCmdLaunchForm(player, ctx.cmd)
end

cmdGui.buildCmdListForm = function(player, ctx)
    local playerName = player:get_player_name()
    -- minetest 5.7+
    local windowInfo = minetest.get_player_window_information(playerName)
    local cols = math.floor((windowInfo.max_formspec_size.x - 2) / 1.66)
    local maxTextWidth = cols * 12 -- just a guess
    local guiDef = {
        spacing = boxSpacing,
        padding = 0.2,
        gui.StyleType {
            selectors = { "*" },
            props = {
                font_size = "12",
            }
        },
        gui.Hbox {
            gui.Hypertext { w = cols, h = 1, text = "<bigger><b>K WorldEdit Command Launcher</b></bigger>" },
        }
    }
    local btnRow = {
        spacing = boxSpacing,
        padding = boxPadding,
    }
    local colCnt = 0

    for i = 1, #k_worldedit_gui.playerCmdList[playerName], 1 do
        local cmd = k_worldedit_gui.playerCmdList[playerName][i]
        local cmdDef = worldedit.registered_commands[cmd]
        table.insert(btnRow, gui.Button({
            w = 1.75,
            label = cmd,
            name = cmd,
            on_event = function(player)
                cmdGui.event.selectCmdFromList(player, { cmd = cmd })
            end,
        }))
        table.insert(btnRow, gui.Tooltip({
            tooltip_text = minetest.wrap_text(cmdDef.description, 128),
            gui_element_name = cmd,
        }))
        colCnt = colCnt + 1
        if colCnt == cols or i == #k_worldedit_gui.playerCmdList[playerName] then
            table.insert(guiDef, gui.HBox(btnRow))
            colCnt = 0
            btnRow = {
                spacing = boxSpacing,
                padding = boxPadding,
            }
        end
    end


    table.insert(guiDef, gui.HBox({
        spacing = boxSpacing,
        padding = boxPadding,

        cmdGui.buildPosDefForm(1, player, ctx),
        cmdGui.buildPosDefForm(2, player, ctx),
        gui.Spacer {},
        gui.Button({ label = S("Clear Region"), on_event = k_worldedit_gui.clearRegionSelection, name = "clear", align_h = "right", }),
        gui.ButtonExit({ label = "Close", align_h = "right", align_v = "bottom", })
    }))

    if nil ~= ctx.message then
        table.insert(guiDef, gui.HBox({
            spacing = boxSpacing,
            padding = boxPadding,
            gui.Label({ label = S("Messages: ") .. minetest.wrap_text(ctx.message, maxTextWidth) }),

        }))
        ctx.message = nil
    end

    guiDef.name = "cmdlist"
    -- @todo height stuff
    --return gui.ScrollableVBox(guiDef)
    return gui.VBox(guiDef)
end

cmdGui.showCmdListForm = function(player, pt)
    local playerName = player and player:get_player_name() or nil

    if nil == playerName then
        return
    end
    local leGuy = flow.make_gui(cmdGui.buildCmdListForm)
    k_worldedit_gui.forms[playerName].cmdSelect = leGuy
    --print(dump(leGuy:render_to_formspec_string(player)))
    leGuy:show(player, {
        player = k_worldedit_gui.contexts[playerName],
    })
end

-- tool to do things.
minetest.register_tool("k_worldedit_gui:command_tablet", {
    description = S("Tablet of Worldly Commands"),
    inventory_image = "k_worldedit_gui_tablet.png",
    -- long range
    range = 200,
    light_level = 14,
    groups = { tool = 1, fire_immune = 1 },
    liquids_pointable = true,
    on_use = function(stack, player, pt)
        k_worldedit_gui.doWandStuff(player, pt)
    end,
    on_place = function(stack, player, pt)
        cmdGui.showCmdListForm(player, pt)
    end,
    on_secondary_use = function(stack, player, pt)
        cmdGui.showCmdListForm(player, pt)
    end,
})

minetest.register_on_mods_loaded(function()
    -- deduplicate by description.
    -- janky but whatever.
    local tmp = {}
    for cmd, def in pairs(worldedit.registered_commands) do
        if nil == tmp[def.description] then
            tmp[def.description] = cmd
        elseif string.len(tmp[def.description]) < string.len(cmd) then
            tmp[def.description] = cmd
        end
    end

    local cmdList = {}
    for _, cmd in pairs(tmp) do
        table.insert(cmdList, cmd)
    end
    table.sort(cmdList)
    k_worldedit_gui.cmdList = cmdList

    k_worldedit_gui.nodeList = {
        -- keep air as first option.
        "air"
    }
    tmp = {}
    for nodename, _ in pairs(minetest.registered_nodes) do
        if string.match(nodename, '.+:.+') then
            table.insert(tmp, nodename)
        end
    end
    table.sort(tmp)
    for i = 1, #tmp, 1 do
        table.insert(k_worldedit_gui.nodeList, tmp[i])
    end
end)

local refreshPlayerCmdList = function(playerName)
    k_worldedit_gui.playerCmdList[playerName] = {}
    for i = 1, #k_worldedit_gui.cmdList, 1 do
        local cmd = k_worldedit_gui.cmdList[i]
        local cmdDef = worldedit.registered_commands[cmd]

        if minetest.check_player_privs(playerName, cmdDef.privs) then
            table.insert(k_worldedit_gui.playerCmdList[playerName], cmd)
        end
    end
end

minetest.register_on_joinplayer(function(player)
    local playerName = player and player:get_player_name() or nil

    if nil == playerName then
        return
    end

    if nil == k_worldedit_gui.contexts[playerName] then
        k_worldedit_gui.contexts[playerName] = {}
    end

    if nil == k_worldedit_gui.forms[playerName] then
        k_worldedit_gui.forms[playerName] = {}
    end

    refreshPlayerCmdList(playerName)
end)

minetest.register_on_priv_grant(function(name, granter, priv)
    refreshPlayerCmdList(name)
end)

minetest.register_on_priv_revoke(function(name, granter, priv)
    refreshPlayerCmdList(name)
end)
