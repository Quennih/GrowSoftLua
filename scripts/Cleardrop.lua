print("(Loaded) Clear World Drops")

local Roles = {
    ROLE_DEFAULT = 0,
    ROLE_DEVELOPER = 51
}

local cd_config = {
    COMMANDS = {"clear"}, 
    COOLDOWN_SECONDS = 300,
    SAVE_KEY_COOLDOWNS = "PM_CD_COOLDOWNS_V1",
    ROLE_COOLDOWN_BYPASS = Roles.ROLE_DEVELOPER
}

local cd_lastClearTime = {}
local cd_sessionState = {}

local function cd_loadData()
    local loadedData = loadDataFromServer(cd_config.SAVE_KEY_COOLDOWNS)
    if loadedData and type(loadedData) == "table" then
        cd_lastClearTime = loadedData
    else
        cd_lastClearTime = {}
    end
end

local function cd_saveData()
    saveDataToServer(cd_config.SAVE_KEY_COOLDOWNS, cd_lastClearTime)
end

local function cd_performClear(world)
    local totalCleared = 0
    while true do
        local droppedItems = world:getDroppedItems()
        if not droppedItems or #droppedItems == 0 then
            break
        end

        for _, item in ipairs(droppedItems) do
            world:removeDroppedItem(item:getUID())
        end
        
        totalCleared = totalCleared + #droppedItems
    end
    return totalCleared
end

local function cd_buildConfirmDialog(player, itemCount)
    local dialog = "set_bg_color|0,0,139,127|\nset_border_color|255,0,0,255|\n"
    dialog = dialog .. "add_label_with_icon|big|`wConfirm Clear|left|1430|\n"
    dialog = dialog .. "add_smalltext|`oThis world contains `w" .. itemCount .. "`o dropped items.`o|\n"
    dialog = dialog .. "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n"
    dialog = dialog .. "add_textbox|`4Are you sure you want to permanently remove them all? This action cannot be undone.`4|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|cd_confirm_yes|`4Yes, Clear All Items|noflags|\n"
    dialog = dialog .. "add_button|cd_confirm_no|`wNo, Cancel|noflags|\n"
    dialog = dialog .. "end_dialog|cd_confirm_dialog|Close||\n"
    player:onDialogRequest(dialog)
end

local function cd_handleClearCommand(world, player)
    if not world:hasAccess(player) then
        player:onConsoleMessage("`4You do not have access to clear items in this world.")
        player:playAudio("bleep_fail.wav")
        return
    end
    
    if not player:hasRole(cd_config.ROLE_COOLDOWN_BYPASS) then
        local userID = player:getUserID()
        local currentTime = os.time()
        local lastTime = cd_lastClearTime[userID]

        if lastTime and (currentTime - lastTime) < cd_config.COOLDOWN_SECONDS then
            local timeLeft = cd_config.COOLDOWN_SECONDS - (currentTime - lastTime)
            player:onConsoleMessage("`4Command is on cooldown. Please wait " .. timeLeft .. " more seconds.`o")
            return
        end
    end

    local itemsToClear = #(world:getDroppedItems())

    if itemsToClear == 0 then
        player:onConsoleMessage("`oThere are no items to clear in this world.")
        return
    end
    
    cd_sessionState[player:getNetID()] = { worldName = world:getName() }
    cd_buildConfirmDialog(player, itemsToClear)
end

for _, commandName in ipairs(cd_config.COMMANDS) do
    registerLuaCommand({
        command = commandName,
        roleRequired = Roles.ROLE_DEFAULT,
        description = "Clears all dropped items in your world."
    })
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)")
    
    for _, registeredCommand in ipairs(cd_config.COMMANDS) do
        if command == registeredCommand then
            cd_handleClearCommand(world, player)
            return true
        end
    end

    return false
end)

onPlayerDialogCallback(function(world, player, data)
    if data.dialog_name ~= "cd_confirm_dialog" then return false end
    
    local state = cd_sessionState[player:getNetID()]
    if not state or state.worldName ~= world:getName() then
        return true 
    end

    if data.buttonClicked == "cd_confirm_yes" then
          if not player:hasRole(cd_config.ROLE_COOLDOWN_BYPASS) then
             local userID = player:getUserID()
             local currentTime = os.time()
             local lastTime = cd_lastClearTime[userID]

             if lastTime and (currentTime - lastTime) < cd_config.COOLDOWN_SECONDS then
                 player:onConsoleMessage("`4Command is on cooldown. Please wait " .. cd_config.COOLDOWN_SECONDS - (currentTime - lastTime) .. " more seconds.`o")
                 player:playAudio("bleep_fail.wav")
                 return true
             end
             cd_lastClearTime[userID] = os.time()
        end
        
        local itemsCleared = cd_performClear(world)
        player:onConsoleMessage("`2Successfully cleared " .. itemsCleared .. " items from the world.")
        player:playAudio("trash.wav")

    elseif data.buttonClicked == "cd_confirm_no" then
        player:onConsoleMessage("`oItem clear cancelled.")
    end
    
    cd_sessionState[player:getNetID()] = nil 
    return true
end)

onPlayerDisconnectCallback(function(player)
    if cd_sessionState[player:getNetID()] then
        cd_sessionState[player:getNetID()] = nil
    end
end)

onAutoSaveRequest(function()
    cd_saveData()
end)

cd_loadData()