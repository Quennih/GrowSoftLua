
-- Global table for storing per-player dialog context
local playerDialogContext = {}

-- Define gem ranges for each item ID
local gemRanges = {
    [20534] = {min = 1000, max = 1500},
    [20536] = {min = 10000, max = 10500},
    [20538] = {min = 100000, max = 100500}
}

-- Helper function: get item name by ID
local function getItemNameByID(itemID)
    local item = getItem(itemID)
    if item then
        return item:getName() or "Unknown Item"
    end
    return "Unknown Item"
end

-- Helper: get random gems based on item ID
local function getRandomGems(itemID)
    local range = gemRanges[itemID]
    if range then
        return math.random(range.min, range.max)
    end
    return 0
end

-- Callback: player uses (consumes) an item
onPlayerConsumableCallback(function(world, player, tile, clickedPlayer, itemID)
    if gemRanges[itemID] then
        
        playerDialogContext[player:getUserID()] = { consumedItemID = itemID }

        local itemName = getItemNameByID(itemID)

        -- Build dialog (FIXED BUTTONS)
        local dialog = "set_default_color|`o\n"
        dialog = dialog .. "add_label_with_icon|big|`wExchange to Gems|left|" .. itemID .. "|\n"
        dialog = dialog .. "add_label|small|`oHow many to consume?|left|\n"
        dialog = dialog .. "add_label|small|`o(you have " .. player:getItemAmount(itemID) .. ")|left|\n"
        dialog = dialog .. "add_text_input|consume_amount||1|10|numeric|\n"
        dialog = dialog .. "add_spacer|small|\n"
        dialog = dialog .. "add_quick_exit|\n"
        dialog = dialog .. "end_dialog|gems_confirm_" .. itemID .. "|Cancel|Consume|\n"

        player:onDialogRequest(dialog)
        return true
    end
    return false
end)

-- Callback: dialog interaction
onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"] or ""

    -- Ambil itemID dari dialog
    local itemID = tonumber(dialogName:match("^gems_confirm_(%d+)$"))
    if not itemID then return false end

    local amount = tonumber(data["consume_amount"]) or 1
    if amount < 1 then amount = 1 end

    local itemName = getItemNameByID(itemID)

    if player:getItemAmount(itemID) < amount then
        player:onConsoleMessage("`4Error:`o Not enough " .. itemName .. ".")
        return true
    end

    player:changeItem(itemID, -amount, 0)

    local totalGems = 0
    for i = 1, amount do
        totalGems = totalGems + getRandomGems(itemID)
    end

    player:addGems(totalGems, 1, 0)
    player:onConsoleMessage(
        "`2You Consumed `^" .. amount .. "x `o" .. itemName ..
        " `2And received `^" .. totalGems .. " Gems."
    )
    player:onTalkBubble(player:getNetID(), "`^+" .. totalGems .. " Gems``", 0)
    player:playAudio("gulp.wav")

    return true
end)

onPlayerDisconnectCallback(function(player)
    playerDialogContext[player:getUserID()] = nil
end)