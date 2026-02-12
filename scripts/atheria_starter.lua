
local DISCORD_WEBHOOK = "discordwebhooklink"

local starterItems = {
        {itemID = 1796, itemCount = 1},
    {itemID = 30036, itemCount = 1},
    {itemID = 13324, itemCount = 1},
    {itemID = 6946, itemCount = 1},
     {itemID = 3010, itemCount = 1},
      {itemID = 25900, itemCount = 250},
       {itemID = 6948, itemCount = 1},
       {itemID = 20700, itemCount = 1},
       {itemID = 20556, itemCount = 1},
       {itemID = 25890, itemCount = 10},
       {itemID = 25888, itemCount = 10},
       {itemID = 12600, itemCount = 10}
}

local starterGems = 200000
local starterRole = 0

local function sendWelcomeWebhook(playerName)
    local message = "**A new Atherian has registered and entered the Atheria...**\n\n" ..
                   "**Welcome " .. playerName .. "!**"

    local payload = {
        content = message,
        username = "Atheria Ps Welcome Bot",
        avatar_url = "https://cdn.discordapp.com/emojis/1426975024065019984.webp?size=160"
    }

    local jsonData = json.encode(payload)

    coroutine.wrap(function()
        local success, result = http.post(
            DISCORD_WEBHOOK,
            { ["Content-Type"] = "application/json" },
            jsonData
        )
        if success then
            print("[StarterPack] Welcome webhook sent successfully for " .. playerName)
        else
            print("[StarterPack] Webhook failed: " .. tostring(result))
        end
    end)()
end

local function formatNum(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local starterCommand = {
    command = "starteritems",
    roleRequired = 0,
    description = "View available starter items"
}
registerLuaCommand(starterCommand)

local function showStarterItemsDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "set_bg_color|0,0,50,230|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big|`#Starter Pack / New Get Items|left|30034|\n"
    dialog = dialog .. "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n"
    dialog = dialog .. "add_textbox|`oWelcome to `#Atheria Ps! `oHere are your available starter items.|left|\n"
     dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|small|" .. player:getName() .. "|left|12436|\n"
    
    dialog = dialog .. "add_smalltext|`oYou will receive these items when you register!|\n"
      dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|small|`wStarter Items|left|9436|\n"

    dialog = dialog .. "add_spacer|small|\n"
    
    for i, item in ipairs(starterItems) do
        local itemDef = getItem(item.itemID)
        local itemName = itemDef:getName()
        local itemCount = item.itemCount
        
        dialog = dialog .. string.format(
            "add_button_with_icon|item_%d|`w%s x%d|staticBlueFrame|%d|%d|left|\n",
            i, itemName, itemCount, item.itemID, itemCount
        )
    end
    
    dialog = dialog .. "add_spacer|small|\n"
     dialog = dialog .. "add_custom_break|\n"
       dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|small|`oAdditional Rewards|left|1432|\n"
    dialog = dialog .. "add_spacer|small|\n"
     dialog = dialog .. "add_label_with_icon|small|`c200,000 `2Gems|left|20536|\n"

    
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. "add_label_with_icon|big||left|0|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|starter_items_dialog|||\n"
    
    player:onDialogRequest(dialog)
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local args = {}
    for word in fullCommand:gmatch("%S+") do
        table.insert(args, word)
    end
    local cmd = args[1]
    
    if cmd == starterCommand.command then
        showStarterItemsDialog(player)
        player:playAudio("spell1.wav")
        return true
    end
    
    if cmd == "mystarter" then
        if player:hasRole(starterRole) then
            player:onConsoleMessage("2You received the starter pack (default role detected)")
        else
            player:onConsoleMessage("`4You haven't received the starter pack")
        end
        return true
    end
    
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"] or ""
    local buttonClicked = data["buttonClicked"] or ""
    
    if dialogName == "starter_items_dialog" then
        local itemIndex = tonumber(buttonClicked:match("^item_(%d+)$"))
        if itemIndex and starterItems[itemIndex] then
            local item = starterItems[itemIndex]
            local itemDef = getItem(item.itemID)
            local name = itemDef:getName()
            local rarity = itemDef:getRarity()
            local description = itemDef:getDescription()
            
            local dialog = "set_default_color|`o\n"
            dialog = dialog .. "add_spacer|small|\n"
            dialog = dialog .. "add_label_with_icon|big|`wItem Details|left|6292|\n"
            dialog = dialog .. "add_spacer|small|\n"
            dialog = dialog .. "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n"
            dialog = dialog .. "add_smalltext|`wName: `o" .. name .. "|\n"
            dialog = dialog .. "add_smalltext|`wAmount: `o" .. item.itemCount .. "|\n"
            dialog = dialog .. (rarity == 999 and "add_smalltext|`wRarity: `oNo rarity|\n" or "add_smalltext|`wRarity: `o" .. rarity .. "|\n")
            dialog = dialog .. "add_spacer|small|\n"
            dialog = dialog .. "add_label_with_icon|big||left|" .. item.itemID .. "|\n"
            dialog = dialog .. "add_spacer|small|\n"
            dialog = dialog .. "add_smalltext|`wItem Description:|\n"
            dialog = dialog .. "add_smalltext|`o" .. description .. "|\n"
            dialog = dialog .. "add_spacer|small|\n"
            dialog = dialog .. "add_button|back_to_main|`4Back|\n"
            dialog = dialog .. "add_custom_break|\n"
            dialog = dialog .. "add_label_with_icon|big||left|0|\n"
            dialog = dialog .. "add_quick_exit|\n"
            dialog = dialog .. "end_dialog|item_details_dialog|||\n"
            
            player:onDialogRequest(dialog)
            return true
        end
    end
    
    if dialogName == "item_details_dialog" and buttonClicked == "back_to_main" then
        showStarterItemsDialog(player)
        return true
    end
    return false
end)

onPlayerRegisterCallback(function(world, player)
    for i, item in ipairs(starterItems) do
        world:useItemEffect(player:getNetID(), item.itemID, 0, 250 * (i + 1))

        if not player:changeItem(item.itemID, item.itemCount, 0) then
            player:changeItem(item.itemID, item.itemCount, 1)
        end
    end

    player:addGems(starterGems, 1, 0)

    player:setRole(starterRole)

    sendWelcomeWebhook(player:getCleanName())

    player:onConsoleMessage("2Welcome to Atheria Ps! You've received your starter pack!``")
    player:onTalkBubble(player:getNetID(), 
        string.format("Starter Pack received! You got %d Gems, %d items and Moderator role!", 
        starterGems, #starterItems), 1)
        
    player:onConsoleMessage("`9A welcome message has been sent to our Discord! The community will greet you soon!`")
end)

print("[StarterPack] Starter Pack System loaded successfully")