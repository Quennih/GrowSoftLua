print("(Loaded) Optimized Auto-Convert GUI + Converter by Sixz v2.0")

local AC_CONFIG = {
    SAVE_KEY = "AUTOCONVERT_SETTINGS_V2",
    CHECK_INTERVAL = 2000,
    CONVERSION_RULES = {
        { from = 242, to = 1796, rate = 100, direction = "up" },
        { from = 1796, to = 7188, rate = 100, direction = "up" },
        { from = 7188, to = 20628, rate = 100, direction = "up" },
        { from = 20628, to = 25048, rate = 100, direction = "up" },
    }
}

local autoConvertEnabled = {}
local lastCheckTime = {}
local processingQueue = {}
local processingState = {}

local function ac_loadData()
    local data = loadDataFromServer(AC_CONFIG.SAVE_KEY)
    autoConvertEnabled = (data and type(data) == "table") and data or {}
end

local function ac_saveData()
    saveDataToServer(AC_CONFIG.SAVE_KEY, autoConvertEnabled)
end

local function formatLargeNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num/1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num/1000)
    end
    return tostring(num)
end

local function ac_handleConversion(player, rule, quantity)
    local from_id = rule.from
    local to_id = rule.to
    local rate = rule.rate
    local items_needed = rate * quantity
    
    if items_needed <= 0 then return false end
    
    local currentAmount = player:getItemAmount(from_id)
    if currentAmount < items_needed then return false end
    
    local success1 = player:changeItem(from_id, -items_needed, 0)
    local success2 = player:changeItem(to_id, quantity, 0)
    
    if success1 and success2 then
        if quantity >= 1 then
            player:onConsoleMessage(string.format(
                "`2[AutoConvert] `oConverted `w%s %s`o → `w%s %s`o.",
                formatLargeNumber(items_needed),
                getItem(from_id):getName(),
                formatLargeNumber(quantity),
                getItem(to_id):getName()
            ))
        end
        return true
    end
    
    if success1 and not success2 then
        player:changeItem(from_id, items_needed, 0)
    end
    
    return false
end

local function ac_checkPlayerOptimized(player)
    local userID = player:getUserID()
    local currentTime = os.time()
    
    if not autoConvertEnabled[userID] then return end
    
    if lastCheckTime[userID] and (currentTime - lastCheckTime[userID]) < 2 then
        return
    end
    
    lastCheckTime[userID] = currentTime
    
    local state = processingState[userID] or { lastRuleIndex = 0 }
    processingState[userID] = state
    
    state.lastRuleIndex = (state.lastRuleIndex % #AC_CONFIG.CONVERSION_RULES) + 1
    local rule = AC_CONFIG.CONVERSION_RULES[state.lastRuleIndex]
    
    local currentAmount = player:getItemAmount(rule.from)
    local possible = math.floor(currentAmount / rule.rate)
    
    if possible > 0 then
        local maxConvert = math.min(possible, 1000)
        ac_handleConversion(player, rule, maxConvert)
    end
end

local function processAutoConvertQueue()
    local players = getServerPlayers()
    local batchSize = math.min(10, #players)
    
    for i = 1, batchSize do
        local player = players[i]
        if player and player:isOnline() then
            local userID = player:getUserID()
            
            if processingQueue[userID] then
                goto continue
            end
            
            processingQueue[userID] = {
                player = player,
                timestamp = os.time()
            }
            
            ::continue::
        end
    end
    
    local processed = 0
    for userID, queueData in pairs(processingQueue) do
        if processed >= 5 then break end
        
        local player = queueData.player
        if player and player:isOnline() then
            ac_checkPlayerOptimized(player)
            processed = processed + 1
        end
        
        processingQueue[userID] = nil
    end
end

local lastProcessTime = 0
local PROCESS_INTERVAL = 5000

onTick(function()
    local currentTime = os.time() * 1000
    
    if (currentTime - lastProcessTime) < PROCESS_INTERVAL then
        return
    end
    
    lastProcessTime = currentTime
    processAutoConvertQueue()
end)

onPlayerDisconnectCallback(function(player)
    local userID = player:getUserID()
    processingQueue[userID] = nil
    processingState[userID] = nil
    lastCheckTime[userID] = nil
end)

local function showAutoConvertMenu(player)
    local userID = player:getUserID()
    autoConvertEnabled[userID] = autoConvertEnabled[userID] or false
    local statusText = autoConvertEnabled[userID] and "`2Enabled ✓" or "`4Disabled ✗"
    local toggleButton = autoConvertEnabled[userID] and "disable_autoconvert" or "enable_autoconvert"
    
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wAuto-Convert Locks|left|242|\n")
    table.insert(dialog, "add_smalltext|`oAutomatically converts WL → DL → BGL → BBGL when possible.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_label|medium|`wStatus: " .. statusText .. "|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|" .. toggleButton .. "|`wToggle Auto-Convert|noflags|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_smalltext|`oOptimized System: Checks every 2-5 seconds to reduce lag.`o|\n")
    table.insert(dialog, "add_quick_exit|\n")
    table.insert(dialog, "end_dialog|autoconvert_main|||\n")
    
    player:onDialogRequest(table.concat(dialog))
end

onPlayerDialogCallback(function(world, player, data)
    if not data or data.dialog_name ~= "autoconvert_main" then return false end
    
    local userID = player:getUserID()
    
    if data.buttonClicked == "enable_autoconvert" then
        autoConvertEnabled[userID] = true
        ac_saveData()
        player:onConsoleMessage("`2[AutoConvert] Enabled ✓ (Optimized Mode)")
        showAutoConvertMenu(player)
        return true
    elseif data.buttonClicked == "disable_autoconvert" then
        autoConvertEnabled[userID] = false
        ac_saveData()
        player:onConsoleMessage("`4[AutoConvert] Disabled ✗")
        showAutoConvertMenu(player)
        return true
    end
    
    return false
end)

registerLuaCommand({
    command = "autoconvert",
    roleRequired = 0,
    description = "Toggle automatic lock conversion or open the GUI."
})

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd, args = fullCommand:match("^(%S+)%s*(.*)$")
    if cmd ~= "autoconvert" then return false end
    
    if args and args:lower() == "toggle" then
        local userID = player:getUserID()
        autoConvertEnabled[userID] = not autoConvertEnabled[userID]
        ac_saveData()
        local status = autoConvertEnabled[userID] and "Enabled ✓ (Optimized)" or "Disabled ✗"
        player:onConsoleMessage("`wAutoConvert: " .. status)
        return true
    end
    
    showAutoConvertMenu(player)
    return true
end)

onAutoSaveRequest(function()
    ac_saveData()
end)

ac_loadData()
print("[AutoConvert] Optimized system loaded.")