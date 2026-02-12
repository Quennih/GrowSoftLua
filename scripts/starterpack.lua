print("(Loaded) Starter Pack script for GrowSoft")

local DEV_ROLE = 51
local SAVE_KEY = "STARTER_PACK_CONFIG"

local starterConfig = loadDataFromServer(SAVE_KEY) or {}
starterConfig.items = starterConfig.items or {
    { itemID = 2912,  itemCount = 1  },
    { itemID = 2914,  itemCount = 50 },
    { itemID = 5480,  itemCount = 1  },
    { itemID = 9640,  itemCount = 1  },
    { itemID = 20634, itemCount = 1  },
    { itemID = 954,   itemCount = 50 },
    { itemID = 98,    itemCount = 1  },
    { itemID = 818,   itemCount = 1  }
}
starterConfig.gems = starterConfig.gems or 1000
starterConfig.inventorySlots = starterConfig.inventorySlots or 5

local function saveConfig()
    saveDataToServer(SAVE_KEY, starterConfig)
end

onPlayerRegisterCallback(function(world, player)
    for i, item in ipairs(starterConfig.items or {}) do
        world:useItemEffect(player:getNetID(), item.itemID, 0, 250 * (i + 1))
        if not player:changeItem(item.itemID, item.itemCount, 0) then
            player:changeItem(item.itemID, item.itemCount, 1)
        end
    end

    if starterConfig.gems and starterConfig.gems > 0 then
        player:addGems(starterConfig.gems, 1, 0)
    end

    if starterConfig.inventorySlots and starterConfig.inventorySlots > 0 then
        player:upgradeInventorySpace(starterConfig.inventorySlots)
    end

    player:onTalkBubble(
        player:getNetID(),
        "Received the Starter Pack! You now have " .. player:getGems() .. " Gems and extra inventory space!",
        1
    )
end)

local function showStarterPanel(player)
    local d = {}
    table.insert(d, "set_default_color|`o\n")
    table.insert(d, "add_label_with_icon|big|`wStarter Pack Config|left|32|\n")
    table.insert(d, "add_smalltext|`2(Click the yellow-framed button to remove item from starterpack)|\n")
    table.insert(d, "add_spacer|small|\n")

    -- list items
    if starterConfig.items and #starterConfig.items > 0 then
        for i, entry in ipairs(starterConfig.items) do
            local item = getItem(entry.itemID)
            local name = item and item:getName() or ("Item " .. entry.itemID)
            table.insert(d, "add_button_with_icon|remove_"..i.."|"..name.." x"..entry.itemCount.."|staticYellowFrame|"..entry.itemID.."|\n")
        end
        table.insert(d, "add_custom_break|\n")
    else
        table.insert(d, "add_textbox|`oNo items in starter pack yet.|\n")
    end

    table.insert(d, "add_spacer|small|\n")
    table.insert(d, "add_text_input|item_id|Item ID:||5|\n")
    table.insert(d, "add_text_input|item_count|Amount:||5|\n")
    table.insert(d, "add_button|add_manual|Add Item (Manual)|noflags|\n")
    table.insert(d, "add_item_picker|chooseItem|Add From Backpack|Choose an item to add|\n")
    table.insert(d, "add_spacer|small|\n")

    -- gems & slots
    table.insert(d, "add_text_input|starter_gems|Starting Gems|"..(starterConfig.gems or 0).."|10|\n")
    table.insert(d, "add_text_input|starter_slots|Extra Inventory Slots|"..(starterConfig.inventorySlots or 0).."|5|\n")
    table.insert(d, "add_button|save_all|Save All Settings|noflags|\n")
    table.insert(d, "add_smalltext|`2Have New Idea for next feature? dm @.z0x__ (VxVnoCountt) on discord|\n")
    table.insert(d, "end_dialog|starterpack_panel|||\n")
    player:onDialogRequest(table.concat(d))
end

registerLuaCommand({
    command = "starterpack",
    roleRequired = DEV_ROLE,
    description = "Open starter pack admin panel"
})

onPlayerCommandCallback(function(world, player, fullCommand)
    if fullCommand:lower() == "starterpack" then
        if player:hasRole(DEV_ROLE) then
            showStarterPanel(player)
        end
        return true
    end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    if data.dialog_name == "starterpack_panel" then
        local btn = data.buttonClicked or ""

        local idx = btn:match("^remove_(%d+)$")
        if idx then
            idx = tonumber(idx)
            table.remove(starterConfig.items, idx)
            saveConfig()
            showStarterPanel(player)
            return true
        end

        if btn == "add_manual" then
            local id = tonumber(data.item_id) or 0
            local count = tonumber(data.item_count) or 1
            if id > 0 and count > 0 then
                starterConfig.items = starterConfig.items or {}
                table.insert(starterConfig.items, { itemID = id, itemCount = count })
                saveConfig()
            end
            showStarterPanel(player)
            return true
        end

        if data.chooseItem and tonumber(data.chooseItem) then
            local id = tonumber(data.chooseItem)
            local d = {}
            table.insert(d, "add_label_with_icon|big|Set Amount|left|"..id.."|\n")
            table.insert(d, "add_text_input|amount|Enter amount:|1|5|\n")
            table.insert(d, "add_button|confirm_add_"..id.."|Confirm|noflags|\n")
            table.insert(d, "end_dialog|starterpack_amount|||\n")
            player:onDialogRequest(table.concat(d))
            return true
        end

        if btn == "save_all" then
            starterConfig.gems = tonumber(data.starter_gems) or 0
            starterConfig.inventorySlots = tonumber(data.starter_slots) or 0
            saveConfig()
            player:onConsoleMessage("`2Starter Pack settings saved.")
            return true
        end

    elseif data.dialog_name == "starterpack_amount" then
        local btn = data.buttonClicked or ""
        local id = tonumber(btn:match("^confirm_add_(%d+)$"))
        if id then
            local amount = tonumber(data.amount) or 1
            if amount > 0 then
                starterConfig.items = starterConfig.items or {}
                table.insert(starterConfig.items, { itemID = id, itemCount = amount })
                saveConfig()
            end
            showStarterPanel(player)
            return true
        end
    end
    return false
end)
