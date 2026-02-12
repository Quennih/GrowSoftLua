print("(Loaded) Fish Exchange Script for GrowSoft")

local Roles = {
    ROLE_DEFAULT = 0
}

local CURRENCY_ITEM_ID = 242
local PRIZE_AMOUNT_PER_FISH = 5
local FISH_WORLD = "FISHING"

-- Tier 1 = 1 to 50 lbs
-- Tier 2 = 51 to 100 lbs
-- Tier 3 = 101 to 250 lbs
-- They act as Multiplier (PRIZE_AMOUNT_PER_FISH * Tier)

local TIER_1 = 1
local TIER_2 = 2
local TIER_3 = 3

local sellFishCommand = {
    command = "fish",
    roleRequired = Roles.ROLE_DEFAULT,
    description = "Sell your silly fishes from your inventory."
}

local function formatNum(num)
    local formattedNum = tostring(num)
    formattedNum = formattedNum:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formattedNum = formattedNum:gsub("^,", "")
    return formattedNum
end

local function isFish(itemID)
    local def = getItem(itemID)
    return def and def:getActionType() == 64
end

local function getPlayerFish(player)
    local fishList = {}
    for _, item in ipairs(player:getInventoryItems()) do
        local itemID = item:getItemID()
        local amount = item:getItemCount()
        if isFish(itemID) and amount > 0 then
            table.insert(fishList, { id = itemID, amount = amount })
        end
    end
    return fishList
end

local function warpFishWorld(player)
    player:enterWorld(FISH_WORLD, "`2Happy Fishing")
end

local function showSellFishDialog(player)
    local layout = ""
    layout = layout .. "add_label_with_icon|big|`wTreasure Trawler|left|3810|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. "add_textbox|`wThe Treasure Trawlers sail from distant shores, bartering riches for every worthy catch. Trade your fish for rewards.|left|\n"
    layout = layout .. "add_spacer|small|\n"

    local fishList = getPlayerFish(player)
    if #fishList == 0 then
        layout = layout .. "add_smalltext|`wYou have no fish to sell.|left|\n"
        layout = layout .. "add_spacer|small|\n"
        layout = layout .. "add_button|refresh_dialog|`wRefresh|noflags|\n"
        layout = layout .. "add_button|warp_fishing|`wCatch Fish|noflags|\n"
    else
        layout = layout .. "add_smalltext|`wSelect a fish to sell:|left|\n"
        layout = layout .. "add_spacer|small|\n"
        for i, fish in ipairs(fishList) do
            
            layout = layout .. "text_scaling_string|aaaaaaaaaa|\n"
            local def = getItem(fish.id)
            layout = layout .. string.format(
                "add_button_with_icon|fish_%d|`9%slbs|staticGreyFrame|%d||\n",
                fish.id,
                formatNum(fish.amount),
                fish.id
            )

            if i % 8 == 0 then
                layout = layout .. "add_custom_break|\n"
                layout = layout .. "add_spacer|small|\n"
            end

        end

        layout = layout .. "add_custom_break|\n"
        layout = layout .. "add_spacer|small|\n"
        layout = layout .. "add_smalltext|`wExchange Rate:|left|\n"
        layout = layout .. "add_custom_break|\n"
        layout = layout .. "add_label_with_icon|small|`wx" .. PRIZE_AMOUNT_PER_FISH .. "|left|" .. CURRENCY_ITEM_ID .. "|\n"
        layout = layout .. "add_custom_break|\n"
        layout = layout .. "add_spacer|small|\n"
        layout = layout .. "add_smalltext|`wBonus:|left|\n"
        layout = layout .. "add_smalltext|`w1 to 50 Pounds: " .. PRIZE_AMOUNT_PER_FISH * TIER_1 .. " " .. getItem(CURRENCY_ITEM_ID):getName() .. "`w!|left|\n"
        layout = layout .. "add_smalltext|`w51 to 100 Pounds: " .. PRIZE_AMOUNT_PER_FISH * TIER_2 .. " " .. getItem(CURRENCY_ITEM_ID):getName() .. "`w!|left|\n"
        layout = layout .. "add_smalltext|`w101 to 250 Pounds: " .. PRIZE_AMOUNT_PER_FISH * TIER_3 .. " " .. getItem(CURRENCY_ITEM_ID):getName() .. "`w!|left|\n"
        layout = layout .. "add_custom_break|\n"
        layout = layout .. "add_spacer|small|\n"
        layout = layout .. "add_smalltext|`4(Warning: Instant exchange)|\n"
        layout = layout .. "add_custom_break|\n"
        layout = layout .. "add_spacer|small|\n"
        layout = layout .. "add_button|sell_all|`wQuick Sell|noflags|\n"
    end
    layout = layout .. "add_quick_exit|\n"
    layout = layout .. "end_dialog|sell_fish_dialog|||\n"
    layout = layout .. "add_custom_break|\n"
    layout = layout .. "add_label_with_icon|small||left||\n"
    player:onDialogRequest(layout)
end

local function showConfirmSellFish(player, itemID)
    local def = getItem(itemID)
    if not def then return end

    local currentAmount = player:getItemAmount(itemID)
    local total_prize = 0
    if currentAmount >= 1 and currentAmount <= 50 then
        total_prize = PRIZE_AMOUNT_PER_FISH * TIER_1
    elseif currentAmount >= 51 and currentAmount <= 100 then
        total_prize = PRIZE_AMOUNT_PER_FISH * TIER_2
    elseif currentAmount >= 101 and currentAmount <= 250 then
        total_prize = PRIZE_AMOUNT_PER_FISH * TIER_3
    end

    local currencyName = getItem(CURRENCY_ITEM_ID):getName()
    local layout = ""
    layout = layout .. ""
    layout = layout .. "add_label_with_icon|big|`wConfirm Exchange      |left|" .. CURRENCY_ITEM_ID .. "|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. string.format(
        "add_smalltext|`wSell `7%s`w for `7%d %s%s`w?|left|\n",
        def:getName(),
        total_prize,
        currencyName,
        (total_prize > 1) and "s" or ""
    )
    layout = layout .. "text_scaling_string|aaaaaaaaaaa|\n"
    layout = layout .. "add_custom_break|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. "add_button_with_icon|empty_one|`w" .. getItem(itemID):getName() .. "|staticNoneFrame|" .. itemID .. "||\n"
    layout = layout .. "add_button_with_icon|empty_one||staticNoneFrame|482||\n"
    layout = layout .. "add_button_with_icon|empty_one|`w" .. getItem(CURRENCY_ITEM_ID):getName() .. "|staticNoneFrame|" .. CURRENCY_ITEM_ID .. "|" .. total_prize .. "|\n"
    layout = layout .. "add_custom_break|\n"
    layout = layout .. "add_spacer|small|\n"
    layout = layout .. string.format("add_button|confirm_sell_%d|`wYes, Sell it|noflags|\n", itemID)
    layout = layout .. "add_quick_exit|\n"
    layout = layout .. "end_dialog|sellfish_confirm|||\n"

    player:onDialogRequest(layout)
end

local function safelyGiveItem(player, itemID, totalAmount)
    local maxPerGive = 200
    local fullChunks = math.floor(totalAmount / maxPerGive)
    local remainder = totalAmount % maxPerGive

    for i = 1, fullChunks do
        player:changeItem(itemID, maxPerGive,1)
    end

    if remainder > 0 then
        player:changeItem(itemID, remainder,1)
    end
end

local function sellFish(player, itemID)
    local currentAmount = player:getItemAmount(itemID)
    local curName = getItem(CURRENCY_ITEM_ID):getName()
    if currentAmount <= 0 then
        player:onTalkBubble(player:getNetID(), "You don't have that fish anymore.", 1)
        showSellFishDialog(player)
        return
    end

    local total_prize = 0
    player:changeItem(itemID, -currentAmount, 0)
    if currentAmount >= 1 and currentAmount <= 50 then
        total_prize = PRIZE_AMOUNT_PER_FISH * TIER_1
    elseif currentAmount >= 51 and currentAmount <= 100 then
        total_prize = PRIZE_AMOUNT_PER_FISH * TIER_2
    elseif currentAmount >= 101 and currentAmount <= 250 then
        total_prize = PRIZE_AMOUNT_PER_FISH * TIER_3
    end

    if not player:changeItem(CURRENCY_ITEM_ID, total_prize, 0) then
        if total_prize > 200 then
            safelyGiveItem(player, CURRENCY_ITEM_ID, total_prize)
        else
            player:changeItem(CURRENCY_ITEM_ID, total_prize, 1)
        end
    end

    player:onTalkBubble(player:getNetID(), "`wExchanged " .. getItem(itemID):getName() .. " for `2" .. total_prize .. " " .. curName .. "`w", 0)
    player:onConsoleMessage("Exchanged " .. getItem(itemID):getName() .. " for " .. total_prize .. " " .. getItem(CURRENCY_ITEM_ID):getName())
    showSellFishDialog(player)
end

local function sellAllFish(player)
    local fishList = getPlayerFish(player)
    local total = 0
    local totalPrize = 0

    for _, fish in ipairs(fishList) do
        local countTracker = 0

        if fish.amount >= 1 and fish.amount <= 50 then
            CountTracker = PRIZE_AMOUNT_PER_FISH * TIER_1
        elseif fish.amount >= 51 and fish.amount <= 100 then
            CountTracker = PRIZE_AMOUNT_PER_FISH * TIER_2
        elseif fish.amount >= 101 and fish.amount <= 250 then
            CountTracker = PRIZE_AMOUNT_PER_FISH * TIER_3
        end

        totalPrize = totalPrize + CountTracker
        player:changeItem(fish.id, -fish.amount, 0)
        total = total + 1

    end

    if total > 0 then
    
        if not player:changeItem(CURRENCY_ITEM_ID, totalPrize, 0) then
            if totalPrize > 200 then
                safelyGiveItem(player, CURRENCY_ITEM_ID, totalPrize)
            else
                player:changeItem(CURRENCY_ITEM_ID, totalPrize, 1)
            end
        end

        local currencyName = getItem(CURRENCY_ITEM_ID):getName()
        player:onTalkBubble(player:getNetID(), "`wExchanged `9" .. formatNum(total) .. " `wFishes for `2" .. formatNum(totalPrize) .. " " .. currencyName .. "/s`w", 0)
        player:onConsoleMessage("Exchanged " .. formatNum(total) .. " Fishes for " .. totalPrize .. " " .. getItem(CURRENCY_ITEM_ID):getName() .. "/s`w")
    else
        player:onTalkBubble(player:getNetID(), "You have no fish to sell.", 1)
    end

    showSellFishDialog(player)
end

onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"]
    local button = data["buttonClicked"]
    if not dialogName or not button then return false end

    if dialogName == "sell_fish_dialog" then
        if button == "sell_all" then
            sellAllFish(player)
            player:playAudio("pop.wav")
            return true

        elseif button == "warp_fishing" then
            warpFishWorld(player)
            player:playAudio("realitytear.wav")
            return true

        elseif button:sub(1, 5) == "fish_" then
            local itemID = tonumber(button:sub(6))
            if itemID then
                showConfirmSellFish(player, itemID)
                return true
            end
        elseif button == "refresh_dialog" then
            showSellFishDialog(player)
            player:playAudio("dry_tick.wav")
            return true

        end

    elseif dialogName == "sellfish_confirm" then
        if button:sub(1, 13) == "confirm_sell_" then
            local itemID = tonumber(button:sub(14))
            if itemID then
                sellFish(player, itemID)
                player:playAudio("pop.wav")
                return true
            end
        end
    end

    return false
end)

registerLuaCommand(sellFishCommand)

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if cmd == sellFishCommand.command then
        showSellFishDialog(player)
        player:playAudio("spell1.wav")
        return true
    end
    return false
end)