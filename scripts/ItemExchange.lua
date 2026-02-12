print("(Loaded) Exchange Script for GrowSoft")

local MAX_ITEM_STACK = 200

local ITEM_STORAGE = {
    {itemID = 2244, amountRequired = 5, itemToGiveID = 1796, amount = 1},
    {itemID = 2246, amountRequired = 1, itemToGiveID = 1796, amount = 1},
    {itemID = 2242, amountRequired = 1, itemToGiveID = 1796, amount = 1},
    {itemID = 2248, amountRequired = 1, itemToGiveID = 1796, amount = 5},
    {itemID = 2250, amountRequired = 1, itemToGiveID = 1796, amount = 5},
    {itemID = 3468, amountRequired = 200, itemToGiveID = 20534, amount = 1},
    {itemID = 4298, amountRequired = 100, itemToGiveID = 1486, amount = 1},
    {itemID = 4300, amountRequired = 100, itemToGiveID = 6802, amount = 1},
    {itemID = 4300, amountRequired = 200, itemToGiveID = 1784, amount = 1},
    {itemID = 4300, amountRequired = 200, itemToGiveID = 1782, amount = 1},
    {itemID = 4300, amountRequired = 200, itemToGiveID = 14700, amount = 1},
    {itemID = 4300, amountRequired = 200, itemToGiveID = 14694, amount = 1},
    {itemID = 7188, amountRequired = 100, itemToGiveID = 9006, amount = 1},
}

local Roles = {
    ROLE_DEFAULT = 0
}

local exchangeCommand = {
    command = "exchange",
    roleRequired = Roles.ROLE_DEFAULT,
    description = "Opens the Exchange Menu"
}

registerLuaCommand(exchangeCommand)

local function showExchangeDialog(player)
    local dialog = "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big|`w" .. getServerName() .. " Exchange Center|left|12592||\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`oWelcome to Item Exchange Center! Trade your unwanted or surplus items for something more useful. Choose from a variety of fair and balanced trades to upgrade your inventory.|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`2(Click the yellow-framed button to exchange your items)|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "text_scaling_string|aaaaaaaaaaaaaa|\n"

    for i, items in ipairs(ITEM_STORAGE) do
        local reqName = getItem(items.itemID):getName()
        local giveName = getItem(items.itemToGiveID):getName()
        dialog = dialog .. string.format("add_button_with_icon|req_%d|%s|noflags|%d|%d|left|\n",
            i, reqName, items.itemID, items.amountRequired)
        dialog = dialog .. string.format("add_button_with_icon|click_none||noflags|11162||\n")
        dialog = dialog .. string.format("add_button_with_icon|give_%d|%s|staticYellowFrame|%d|%d|left|\n",
            i, giveName, items.itemToGiveID, items.amount)
        dialog = dialog .. "add_custom_break|\nadd_spacer|small|\n"
    end

    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|exchange_dialog|Close||\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_label_with_icon|big||left|0||\n"
    player:onDialogRequest(dialog)
end

local function showQuantityDialog(player, index)
    local data = ITEM_STORAGE[index]
    if not data then return end
    local itemAmt = player:getItemAmount(data.itemID)
    local itemName = getItem(data.itemID):getName()
    local itemReward = getItem(data.itemToGiveID):getName()

    local dialog = "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big|`wConfirm Exchange|left|6292|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`2You'll give|left|\n"
    dialog = dialog .. "add_label_with_icon|small|(" .. data.amountRequired .. ") " .. itemName .. "|left|" .. data.itemID .. "|\n"
    dialog = dialog .. "add_smalltext|`4You'll get|left|\n"
    dialog = dialog .. "add_label_with_icon|small|(" .. data.amount .. ") " .. itemReward .. "|left|" .. data.itemToGiveID .. "|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`2(You have " .. itemAmt .. " " .. itemName .. ")|left|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`wHow many times do you want to perform this exchange?|\n"
    dialog = dialog .. "add_text_input|qty_input|`w:|1|3|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "end_dialog|confirm_qty_" .. index .. "|Cancel|Confirm|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_label_with_icon|small||left||\n"
    player:onDialogRequest(dialog)
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, args = fullCommand:match("^(%S+)%s*(.*)")
    if command == exchangeCommand.command then
        showExchangeDialog(player)
        player:playAudio("spell1.wav")
        return true
    end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"] or ""
    local buttonClicked = data["buttonClicked"] or ""

    if dialogName == "exchange_dialog" and buttonClicked:match("^give_%d+") then
        local index = tonumber(buttonClicked:match("^give_(%d+)"))
        showQuantityDialog(player, index)
        return true
    end

    local index = tonumber(dialogName:match("^confirm_qty_(%d+)$"))
    if index then
        local exchange = ITEM_STORAGE[index]
        if not exchange then return true end

        local qtyInput = data["qty_input"] or "1"

        if not qtyInput:match("^%d+$") then
            player:onConsoleMessage("Please enter a valid number.")
            player:onTalkBubble(player:getNetID(), "`4Invalid Input", 0)
            player:playAudio("bleep_fail.wav")
            return true
        end

        local qty = tonumber(qtyInput) or 1
        if qty < 1 then qty = 1 end
        if qty > MAX_ITEM_STACK then
            player:onConsoleMessage("Invalid Input")
            player:onTalkBubble(player:getNetID(), "`4Invalid Input", 0)
            player:playAudio("bleep_fail.wav")
            return true 
        end

        local totalCost = exchange.amountRequired * qty
        local totalReward = exchange.amount * qty

        local playerHas = player:getItemAmount(exchange.itemID)
        local playerRewardCount = player:getItemAmount(exchange.itemToGiveID)

        if playerHas < totalCost then
            player:onConsoleMessage("Not enough items for exchange")
            player:onTalkBubble(player:getNetID(), "`4Not enough items for exchange", 0)
            player:playAudio("bleep_fail.wav")
            return true
        end

        if playerRewardCount + totalReward > MAX_ITEM_STACK then
            player:onConsoleMessage("Not enough space in your inventory for this item")
            player:onTalkBubble(player:getNetID(), "`4Not enough space in your inventory for this item", 0)
            player:playAudio("bleep_fail.wav")
            return true
        end

        player:changeItem(exchange.itemID, -totalCost, 0)
        player:changeItem(exchange.itemToGiveID, totalReward, 0)

        player:onConsoleMessage("Exchanged " .. totalCost .. " " .. getItem(exchange.itemID):getName() .. " for " .. totalReward .. " " .. getItem(exchange.itemToGiveID):getName())
        player:onTalkBubble(player:getNetID(), "`2Exchange Complete", 0)
        world:useItemEffect(player:getNetID(), exchange.itemID, 0, 100)
        player:playAudio("keypad_hit.wav")

        showExchangeDialog(player)
        return true
    end
end)