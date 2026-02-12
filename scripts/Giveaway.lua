print("(Loaded) Giveaway Script for GrowSoft")

local Roles = {
    ROLE_DEVELOPER = 51
}

local giveawayItems = {}

local MAX_INVENTORY_SLOT = 200

local function formatNum(num)
    local formattedNum = tostring(num)
    formattedNum = formattedNum:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formattedNum = formattedNum:gsub("^,", "")
    return formattedNum
end

local function showGiveawayDialog(player)
    local layout = "add_spacer|small|\n"
    layout = layout .. "add_label_with_icon|big|`wGiveaway Manager|left|6128|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. "add_textbox|`oAdd items to the giveaway list and distribute to all players.|left|\n"
    layout = layout .. "add_spacer|small|\n"

    if #giveawayItems == 0 then
        layout = layout .. "add_smalltext|`7(No items)|left|\n"
    else
        layout = layout .. "add_smalltext|`wItems to be given (click to remove):|left|\n"
        layout = layout .. "add_spacer|small|\n"

        for i, entry in ipairs(giveawayItems) do
            local item = getItem(entry.id)
            --local label = string.format("%s x%s", item:getName(), formatNum(entry.amount))
            layout = layout .. "text_scaling_string|aaaaaaaaaaaa|\n"
            layout = layout .. string.format("add_button_with_icon|remove_%d|%s|staticYellowFrame|%d|%s|\n", i, item:getName(), entry.id, formatNum(entry.amount))
        end
    end

    layout = layout .. "add_custom_break|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. "add_text_input|item_id|Item ID:|242|5|\n"
    layout = layout .. "add_text_input|item_amount|Amount:|1|5|\n"
    layout = layout .. "add_quick_exit|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. "add_custom_button|add_item|textLabel:Add Item;margin:10,0|\n"
    layout = layout .. "add_custom_break|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. "add_custom_button|give_all|textLabel:`2Giveaway;margin:10,0|\n"
    layout = layout .. "end_dialog|giveaway_dialog|||\n"
    layout = layout .. "add_custom_break|\n"
    layout = layout .. "add_label_with_icon|small||left|0|\n"
    player:onDialogRequest(layout)
end

onPlayerDialogCallback(function(world, player, data)
    if data["dialog_name"] ~= "giveaway_dialog" then return false end

    local clicked = data["buttonClicked"]

    local removeIndex = clicked:match("^remove_(%d+)$")
    if removeIndex then
        removeIndex = tonumber(removeIndex)
        if giveawayItems[removeIndex] then
            local removedItem = getItem(giveawayItems[removeIndex].id)
            table.remove(giveawayItems, removeIndex)
            player:onTalkBubble(player:getNetID(), "Removed " .. removedItem:getName() .. " from the list.", 0)
        end
        showGiveawayDialog(player)
        return true
    end

    if clicked == "add_item" then
        local id = tonumber(data["item_id"])
        local amount = tonumber(data["item_amount"])
        if not id or not amount or id <= 0 or amount <= 0 or amount > MAX_INVENTORY_SLOT then
            player:onTalkBubble(player:getNetID(), "Invalid item ID or amount.", 1)
            player:playAudio("bleep_fail.wav")
            return true
        end

        table.insert(giveawayItems, { id = id, amount = amount })
        showGiveawayDialog(player)
        return true
    end

    if clicked == "give_all" then
        if #giveawayItems == 0 then
            player:onTalkBubble(player:getNetID(), "Giveaway list is empty.", 1)
            player:playAudio("bleep_fail.wav")
            return true
        end

        local players = getServerPlayers()
        for _, target in ipairs(players) do
            local messageLines = {}
            for _, entry in ipairs(giveawayItems) do
                local item = getItem(entry.id)
                local itemName = item:getName()
                local amount = entry.amount

                if not target:changeItem(entry.id, amount, 0) then
                    target:changeItem(entry.id, amount, 1)
                end

                table.insert(messageLines, "- " .. itemName .. " x" .. formatNum(amount))
            end

            target:onConsoleMessage("`2You received:\n" .. table.concat(messageLines, "\n"))
            target:sendVariant({"OnAddNotification", "interface/large/atomic_button.rttex", "`2Received Something from Giveaway", "audio/beep.wav", 0})
        end

        giveawayItems = {}
        player:onTalkBubble(player:getNetID(), "`2Giveaway Complete!", 0)
        return true
    end

    return false
end)

local giveawayCommand = {
    command = "giveaway",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Opens the giveaway management UI"
}

registerLuaCommand(giveawayCommand)

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, args = fullCommand:match("^(%S+)%s*(.*)")
    if command == giveawayCommand.command then
        if not player:hasRole(Roles.ROLE_DEVELOPER) then
            player:onConsoleMessage("`4Unknown command. `oEnter /? for a list of valid commands.")
            player:playAudio("bleep_fail.wav")
            return true
        end
        showGiveawayDialog(player)
        return true
    end
    return false
end)