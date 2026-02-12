print("(Loaded) OPC Script for GrowSoft")

-- Storage (if you want to reset data, simply change the value of KEY_STRING)
local KEY_STRING = "ONLINE_POINT_CURRENCY_SERVER_" .. getServerID()

-- Empty tables for Player Names, OPC Amounts, and Player Timers
local PLAYER_NAME_MAP = PLAYER_NAME_MAP or {}
local ONLINE_POINT_CURRENCY = {}
local playerTimers = {}

-- Market Name and Currency Name (Editable)
local marketName = "Online Point Market"
local onlinePointName = "OPC"

-- Commands (Editable)
local showDialogOPC = "opc"
local showLeaderboardOPC = "opclb"
local giveCommandOPC = "giveopc"
local removeCommandOPC = "removeopc"

-- Configuration Values (Editable)
local OPC_INTERVAL = 300
local MAX_INVENTORY = 200
local MAX_PLAYER_CHECK = 250

-- Role Values for Permissions
local Roles = { ROLE_DEFAULT = 0, ROLE_DEVELOPER = 51 }

-- Items, Amount, and Price (Editable)
local OPC_ITEMS_STARTER = {
    {itemID = 20534, amount = 1, opcRequired = 1},
    {itemID = 202, amount = 25, opcRequired = 5},
    {itemID = 204, amount = 10, opcRequired = 5},
    {itemID = 206, amount = 4, opcRequired = 5},
    {itemID = 242, amount = 1, opcRequired = 5},
    {itemID = 6140, amount = 1, opcRequired = 10},
    {itemID = 20536, amount = 1, opcRequired = 25},
    {itemID = 20538, amount = 1, opcRequired = 100},
    {itemID = 20234, amount = 1, opcRequired = 100},
}

local OPC_ITEMS_POPULAR = {
    {itemID = 4994, amount = 1, opcRequired = 250},
    {itemID = 20258, amount = 1, opcRequired = 250},
    {itemID = 20614, amount = 1, opcRequired = 500},
    {itemID = 1796, amount = 1, opcRequired = 500},
    {itemID = 9114, amount = 1, opcRequired = 500},
    {itemID = 4654, amount = 1, opcRequired = 500},
    {itemID = 20616, amount = 1, opcRequired = 750},
    {itemID = 5264, amount = 1, opcRequired = 1000},
    {itemID = 12380, amount = 1, opcRequired = 1000},
}

local OPC_ITEMS_PREMIUM = {
    {itemID = 12390, amount = 1, opcRequired = 1250},
    {itemID = 9344, amount = 1, opcRequired = 1250},
    {itemID = 1970, amount = 1, opcRequired = 1250},
    {itemID = 12388, amount = 1, opcRequired = 1500},
    {itemID = 8286, amount = 1, opcRequired = 5000},
    {itemID = 14414, amount = 1, opcRequired = 5000},
    {itemID = 7188, amount = 1, opcRequired = 50000},
    {itemID = 20628, amount = 1, opcRequired = 500000},
    {itemID = 25002, amount = 1, opcRequired = 5000000},
}

local OPC_SORTED_INDEX_MAP = {}

local function loadDatasToServer()
    local data = loadDataFromServer(KEY_STRING)
    if data then

        ONLINE_POINT_CURRENCY = {}
        PLAYER_NAME_MAP = {}

        if data.OPC and type(data.OPC) == "table" then
            ONLINE_POINT_CURRENCY = data.OPC
            print("[OPC] Loaded OPC data.")
        else
            ONLINE_POINT_CURRENCY = {}
            print("[OPC] No existing OPC data.")
        end

        if data.Names and type(data.Names) == "table" then
            PLAYER_NAME_MAP = data.Names
            print("[OPC] Loaded player name map.")
        else
            PLAYER_NAME_MAP = {}
            print("[OPC] No existing name data.")
        end
    else
        ONLINE_POINT_CURRENCY = {}
        PLAYER_NAME_MAP = {}
        print("[OPC] No existing data.")
    end
end

local function saveDatasToServer()
    saveDataToServer(KEY_STRING, { OPC = ONLINE_POINT_CURRENCY, Names = PLAYER_NAME_MAP })
    print("[OPC] Saved OPC data.")
end

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60

    if minutes > 0 and remainingSeconds > 0 then
        return string.format("%d minute%s %d second%s", minutes, minutes ~= 1 and "s" or "", remainingSeconds, remainingSeconds ~= 1 and "s" or "")
    elseif minutes > 0 then
        return string.format("%d minute%s", minutes, minutes ~= 1 and "s" or "")
    else
        return string.format("%d second%s", remainingSeconds, remainingSeconds ~= 1 and "s" or "")
    end
end

local function findPlayerByNameInsensitive(inputName)
    local target = string.lower(inputName)
    for _, p in ipairs(getServerPlayers()) do
        if string.lower(p:getCleanName()) == target then
            return p
        end
    end
    return nil
end

local function formatNum(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

registerLuaCommand({
    command = showDialogOPC,
    roleRequired = Roles.ROLE_DEFAULT,
    description = "Open OPC Dialog"
})

registerLuaCommand({
    command = giveCommandOPC,
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Give OPC to a player"
})

registerLuaCommand({
    command = removeCommandOPC,
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Remove OPC to a player"
})

registerLuaCommand({
    command = showLeaderboardOPC,
    roleRequired = Roles.ROLE_DEFAULT,
    description = "Open OPC Leaderboard Dialog"
})

local function showOPCDialog(player)
    local userId = player:getUserID()
    local opc = ONLINE_POINT_CURRENCY[userId] or 0
    local dialog = "set_bg_color|170,175,180,255|\n"
    dialog = dialog .. "set_border_color|0,192,203,255|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big|`w" .. marketName .. "|left|9474|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_custom_button|game_title|image:interface/server_1981/banner_opc.rttex;image_size:1200,260;width:1;state:disabled;|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`7Welcome to " .. marketName .. "! Spend your hard-earned " .. onlinePointName .. " in this shop. You can earn 1 " .. onlinePointName .. " every `w" .. formatTime(OPC_INTERVAL) .. "`7 by staying online in a world.|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|small|" .. player:getName() .. "|left|12436|\n"
    dialog = dialog .. "add_smalltext|`7Your current balance is `w" .. formatNum(opc) .. " " .. onlinePointName .. "|\n"
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. "text_scaling_string|aaaaaaaaaa|\n"

    OPC_SORTED_INDEX_MAP = {}
    local buttonIndex = 1

    local function addSection(title, items, categoryName)
        if #items == 0 then return end

        dialog = dialog .. string.format("add_label_with_icon|medium|`w%s|left|7074|\n", title)
        dialog = dialog .. "add_spacer|small|\n"

        for i, item in ipairs(items) do
            OPC_SORTED_INDEX_MAP[buttonIndex] = { category = categoryName, index = i }

            local frameStyle = "staticYellowFrame"
                
            if categoryName == "starter" then
                frameStyle = "staticBlueFrame"
            elseif categoryName == "popular" then
                frameStyle = "staticPurpleFrame"
            end

            dialog = dialog .. string.format(
                "add_button_with_icon|var_%d||%s|%d|%d|left|\n",
                buttonIndex, frameStyle, item.itemID, item.opcRequired
            )

            buttonIndex = buttonIndex + 1
        end
    
        dialog = dialog .. "add_custom_break|\n"
        dialog = dialog .. "add_spacer|small|\n"
    end

    addSection("`wStarter Section", OPC_ITEMS_STARTER, "starter")
    addSection("`wPopular Section", OPC_ITEMS_POPULAR, "popular")
    addSection("`wPremium Section", OPC_ITEMS_PREMIUM, "premium")

    dialog = dialog .. "add_label_with_icon|big||left|0|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|opc_dialog|||\n"

    player:onDialogRequest(dialog)
end

local function showConfirmDialog(player, buttonIndex)
    local mapping = OPC_SORTED_INDEX_MAP[buttonIndex]
    if not mapping then return end

    local category, index = mapping.category, mapping.index
    local item
    if category == "starter" then
        item = OPC_ITEMS_STARTER[index]
    elseif category == "popular" then
        item = OPC_ITEMS_POPULAR[index]
    elseif category == "premium" then
        item = OPC_ITEMS_PREMIUM[index]
    end

    if not item then return end

    local userId = player:getUserID()
    local opc = ONLINE_POINT_CURRENCY[userId] or 0

    local itemDef = getItem(item.itemID)
    local name = itemDef:getName()
    local rarity = itemDef:getRarity()
    local description = itemDef:getDescription()

    local dialog = "set_bg_color|170,175,180,255|\n"
    dialog = dialog .. "set_border_color|0,192,203,255|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big|`wConfirm Purchase|left|6292|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`wName: `7" .. name .. "|\n"
    dialog = dialog .. "add_smalltext|`wAmount: `7" .. item.amount .. "|\n"
    dialog = dialog .. "add_smalltext|`wPrice: `7" .. formatNum(item.opcRequired) .. " " .. onlinePointName .. "|\n"
    dialog = dialog .. (rarity == 999 and "add_smalltext|`wRarity: `7No rarity|\n" or "add_smalltext|`wRarity: `7" .. rarity .. "|\n")
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big||left|" .. item.itemID .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`wItem Description:|\n"
    dialog = dialog .. "add_smalltext|`7" .. description .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`w(Current balance: " .. formatNum(opc) .. " " .. onlinePointName .. ")|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. string.format("add_custom_button|confirm_opc_buy_%d|textLabel:`wPurchase for %s %s|\n", buttonIndex, formatNum(item.opcRequired), onlinePointName)
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|back_to_main|`wBack|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_label_with_icon|big||left|0|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|confirm_opc_dialog|||\n"
    player:onDialogRequest(dialog)
end

local function showOPCLeaderboard(player)
    local leaderboard = {}

    for userId = 1, MAX_PLAYER_CHECK do
        local opc = ONLINE_POINT_CURRENCY[userId]

        if opc == nil then
            goto continue
        end

        table.insert(leaderboard, { userId = userId, opc = opc })

        ::continue::
    end

    table.sort(leaderboard, function(a, b)
        return a.opc > b.opc
    end)

    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_label_with_icon|big|`w" .. onlinePointName .. " Leaderboard   |left|15076|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`oShowing top " .. math.min(25, #leaderboard) .. " players|\n"
    dialog = dialog .. "add_spacer|small|\n"

    for i = 1, math.min(25, #leaderboard) do
        local entry = leaderboard[i]
        local name = PLAYER_NAME_MAP[entry.userId] or ("UserID " .. entry.userId)

        dialog = dialog .. string.format("add_textbox|`w#%d `o%s `w- %d %s|left|\n", i, name, entry.opc, onlinePointName)
    end

    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "end_dialog|opc_lb_dialog||Close|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_label_with_icon|big||left|0|\n"

    player:onDialogRequest(dialog)
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local args = {}
    for word in fullCommand:gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = args[1]

    if cmd == showDialogOPC then
        showOPCDialog(player)
        player:playAudio("spell1.wav")
        return true
    end

    if cmd == showLeaderboardOPC then
        showOPCLeaderboard(player)
        player:playAudio("spell1.wav")
        return true
    end

    if (cmd == giveCommandOPC or cmd == removeCommandOPC) and player:hasRole(Roles.ROLE_DEVELOPER) then
        local targetName = args[2]
        local amount = tonumber(args[3] or "")

        if not targetName or not amount then
            player:onConsoleMessage("Usage: /" .. cmd .. " <playerName> <amount>")
            return true
        end

        local target = findPlayerByNameInsensitive(targetName)
        if not target then
            player:onConsoleMessage("`4Player '" .. targetName .. "' not found or not online.")
            return true
        end

        local targetId = target:getUserID()
        if not targetId then
            player:onConsoleMessage("`4Failed to get user ID for " .. target:getName() .. ".")
            return true
        end

        ONLINE_POINT_CURRENCY[targetId] = ONLINE_POINT_CURRENCY[targetId] or 0

        if cmd == giveCommandOPC then
            ONLINE_POINT_CURRENCY[targetId] = ONLINE_POINT_CURRENCY[targetId] + amount
            player:onConsoleMessage("`2Gave " .. amount .. " " .. onlinePointName .. " to " .. target:getName() .. "!")
            target:onConsoleMessage("`2You received " .. amount .. " " .. onlinePointName .. " from a Developer!")
            target:playAudio("gauntlet_spawn.wav");
            player:playAudio("gauntlet_spawn.wav");
        else
            ONLINE_POINT_CURRENCY[targetId] = math.max(0, ONLINE_POINT_CURRENCY[targetId] - amount)
            player:onConsoleMessage("`4Removed " .. amount .. " " .. onlinePointName .. " from " .. target:getName() .. "!")
            target:onConsoleMessage("`4A Developer removed " .. amount .. " " .. onlinePointName .. " from your balance!")
            target:playAudio("gauntlet_spawn.wav");
            player:playAudio("gauntlet_spawn.wav");
        end

        saveDatasToServer()
        return true
    end

    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"] or ""
    local buttonClicked = data["buttonClicked"] or ""

    if dialogName == "opc_dialog" then
        local index = tonumber(buttonClicked:match("^var_(%d+)$"))
        if index then
            showConfirmDialog(player, index)
            return true
        end
    end

    if dialogName == "confirm_opc_dialog" and buttonClicked == "back_to_main" then
        showOPCDialog(player)
        return true
    end

    if dialogName == "confirm_opc_dialog" and buttonClicked:find("confirm_opc_buy_") then
        local buttonIndex = tonumber(buttonClicked:match("confirm_opc_buy_(%d+)"))
        if not buttonIndex then return true end

        local mapping = OPC_SORTED_INDEX_MAP[buttonIndex]
        if not mapping then return true end

        local category, index = mapping.category, mapping.index
        local item
        if category == "starter" then
            item = OPC_ITEMS_STARTER[index]
        elseif category == "popular" then
            item = OPC_ITEMS_POPULAR[index]
        elseif category == "premium" then
            item = OPC_ITEMS_PREMIUM[index]
        end

        if not item then return true end

        local userId = player:getUserID()
        local opc = ONLINE_POINT_CURRENCY[userId] or 0

        if opc < item.opcRequired then
            player:onTalkBubble(player:getNetID(), "`4Not enough " .. onlinePointName .. "!", 0)
            player:onConsoleMessage("Not enough " .. onlinePointName .. "!")
            player:playAudio("bleep_fail.wav")
            return true
        end

        if player:getItemAmount(item.itemID) + item.amount > MAX_INVENTORY then
            player:onTalkBubble(player:getNetID(), "`4Not enough inventory space!", 0)
            player:onConsoleMessage("Not enough inventory space!")
            player:playAudio("bleep_fail.wav")
            return true
        end

        ONLINE_POINT_CURRENCY[userId] = opc - item.opcRequired
        player:changeItem(item.itemID, item.amount, 0)
        saveDatasToServer()

        player:onTalkBubble(player:getNetID(), "`2Transaction complete!", 0)
        player:onConsoleMessage("Bought " .. getItem(item.itemID):getName() .. " for " .. item.opcRequired .. " " .. onlinePointName .. "!")
        world:useItemEffect(player:getNetID(), item.itemID, 0, 100)
        player:playAudio("piano_nice.wav")
        showOPCDialog(player)
        return true
    end

    return false
end)

local function startPlayerTimer(player)
    local userId = player:getUserID()
    local now = os.time()

    if not playerTimers[userId] then
        playerTimers[userId] = { accumulatedSeconds = 0, lastTick = now, active = true }
    else
        playerTimers[userId].lastTick = now
        playerTimers[userId].active = true
    end

    if ONLINE_POINT_CURRENCY[userId] == nil then
        ONLINE_POINT_CURRENCY[userId] = 0
    end
end

local function pausePlayerTimer(player)
    local userId = player:getUserID()
    if playerTimers[userId] then
        playerTimers[userId].active = false
    end
end

local function resetPlayerTimer(player)
    local userId = player:getUserID()
    playerTimers[userId] = nil
end

onPlayerEnterWorldCallback(function(world, player)
    startPlayerTimer(player)
end)

onPlayerLeaveWorldCallback(function(world, player)
    pausePlayerTimer(player)
end)

onPlayerDisconnectCallback(function(player)
    resetPlayerTimer(player)
end)

onWorldTick(function(world)
    local now = os.time()
    for userId, timer in pairs(playerTimers) do
        if timer.active then
            local elapsed = now - timer.lastTick
            if elapsed > 0 then
                timer.accumulatedSeconds = (timer.accumulatedSeconds or 0) + elapsed
                timer.lastTick = now

                while timer.accumulatedSeconds >= OPC_INTERVAL do
                    timer.accumulatedSeconds = timer.accumulatedSeconds - OPC_INTERVAL
                    ONLINE_POINT_CURRENCY[userId] = (ONLINE_POINT_CURRENCY[userId] or 0) + 1
                    for _, p in ipairs(getServerPlayers()) do
                        if p:getUserID() == userId then
                            p:onConsoleMessage("`2+1 " .. onlinePointName .. " ")
                            p:playAudio("bell.wav")
                            break
                        end
                    end

                    saveDatasToServer()
                end
            end
        else
            timer.lastTick = now
        end
    end
end)

loadDatasToServer()

for _, player in ipairs(getServerPlayers()) do
    startPlayerTimer(player)
end

onPlayerLoginCallback(function(player)
    local userID = player:getUserID()
    local name = tostring(player:getName())
    PLAYER_NAME_MAP[userID] = name
    saveDatasToServer()
end)