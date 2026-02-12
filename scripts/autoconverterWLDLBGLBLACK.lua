print("(Loaded) Auto-Convert GUI + Converter by Sixz")

local AC_CONFIG = {
    SAVE_KEY = "AUTOCONVERT_SETTINGS_V1",
    CONVERSION_RULES = {
        { from = 242,   to = 1796,  rate = 100, direction = "up" },
        { from = 1796,  to = 7188,  rate = 100, direction = "up" },
        { from = 7188,  to = 20628, rate = 100, direction = "up" },
    }
}

local autoConvertEnabled = {}

local function ac_loadData()
    local data = loadDataFromServer(AC_CONFIG.SAVE_KEY)
    autoConvertEnabled = (data and type(data) == "table") and data or {}
end

local function ac_saveData()
    saveDataToServer(AC_CONFIG.SAVE_KEY, autoConvertEnabled)
end

local function ac_handleConversion(player, rule, quantity)
    local from_id = rule.from
    local to_id   = rule.to
    local rate    = rule.rate

    local items_needed = rate * quantity
    local items_gained = quantity

    if player:getItemAmount(from_id) < items_needed then return false end

    player:changeItem(from_id, -items_needed, 0)
    player:changeItem(to_id, items_gained, 0)

    player:onConsoleMessage(
        string.format("`2[AutoConvert] `oConverted `w%d %s(s)`o → `w%d %s(s)`o.",
        items_needed, getItem(from_id):getName(), items_gained, getItem(to_id):getName())
    )
    player:playAudio("keypad_hit.wav")
    return true
end

local function ac_checkPlayer(player)
    local userID = player:getUserID()
    if not autoConvertEnabled[userID] then return end

    for _, rule in ipairs(AC_CONFIG.CONVERSION_RULES) do
        local currentAmount = player:getItemAmount(rule.from)
        local possible = math.floor(currentAmount / rule.rate)
        if possible > 0 then
            ac_handleConversion(player, rule, possible)
        end
    end
end

local function showAutoConvertMenu(player)
    local userID = player:getUserID()
    autoConvertEnabled[userID] = autoConvertEnabled[userID] or false

    local statusText = autoConvertEnabled[userID] and "`2Enabled ✅" or "`4Disabled ❌"
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
    table.insert(dialog, "add_label|small|`oTip: You can also use `/autoconvert toggle` to quickly toggle without the GUI.`o|\n")
    table.insert(dialog, "add_quick_exit|\n")
    table.insert(dialog, "end_dialog|autoconvert_main|||\n")

    player:onDialogRequest(table.concat(dialog))
end

onPlayerDialogCallback(function(world, player, data)
    if not data or not data.dialog_name then return false end
    if data.dialog_name ~= "autoconvert_main" then return false end

    local userID = player:getUserID()
    if data.buttonClicked == "enable_autoconvert" then
        autoConvertEnabled[userID] = true
        ac_saveData()
        player:onConsoleMessage("`2[AutoConvert] Enabled ✅")
        showAutoConvertMenu(player)
        return true
    elseif data.buttonClicked == "disable_autoconvert" then
        autoConvertEnabled[userID] = false
        ac_saveData()
        player:onConsoleMessage("`4[AutoConvert] Disabled ❌")
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
        local status = autoConvertEnabled[userID] and "Enabled ✅" or "Disabled ❌"
        player:onConsoleMessage("`wAutoConvert: " .. status)
        return true
    end

    showAutoConvertMenu(player)
    return true
end)

onTick(function()
    for _, player in ipairs(getServerPlayers()) do
        ac_checkPlayer(player)
    end
end)

onAutoSaveRequest(function()
    ac_saveData()
end)

ac_loadData()
