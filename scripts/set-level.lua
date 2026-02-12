local BLUE_NAME_TITLE_ID = 2

-- Konstanta peran (untuk memastikan ketersediaan ROLE_DEVELOPER)
local Roles = {
  ROLE_NONE = 0, ROLE_VIP = 1, ROLE_SUPER_VIP = 2, ROLE_MODERATOR = 3,
  ROLE_ADMIN = 4, ROLE_COMMUNITY_MANAGER = 5, ROLE_CREATOR = 6,
  ROLE_GOD = 7, ROLE_MANAGER = 9, ROLE_OWNER = 10, ROLE_TESTER = 11,
  ROLE_DEVELOPER = 51 -- ID Developer
}

local setLevelCommandData = {
    command = "setlevel",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Sets a player's level to a specific value and gives title at level 125."
}

local setLevelInfo = "`oUsage: /setlevel <playerName> <amount> - Sets a player's level to the given value."

-- Fungsi bantu untuk format angka (asumsi formatNum sudah ada di skrip lain/global)
local function formatNum(n) return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end

-- Register the command
registerLuaCommand(setLevelCommandData)


-- Fungsi untuk memproses perubahan level (dipisahkan agar bisa dipanggil dari GUI)
function processSetLevel(world, player, targetName, levelAmount, maxLevel)
    
    levelAmount = tonumber(levelAmount)
    if not levelAmount or levelAmount < 0 then
        player:onConsoleMessage("`4Error: `oInvalid level amount.")
        return
    end

    -- Check for exceeding max level
    if levelAmount > maxLevel then
        player:onConsoleMessage("`4Error: `oYou cannot set level above the maximum server level (" .. maxLevel .. ").")
        return
    end

    -- Find player (asumsi getPlayerByName & findMatch sudah ada)
    -- Karena fungsi-fungsi ini tidak ada di konteks, saya akan menggunakan implementasi sederhana
    local function findPlayer(name)
        local t = string.lower(name)
        for _, p in ipairs(getServerPlayers()) do
            if string.lower(p:getCleanName()) == t then return p end
        end
        return nil
    end

    local targetPlayer = findPlayer(targetName)
    if not targetPlayer then
        player:onConsoleMessage("`4Oops: `oNo player found with name starting with w" .. targetName .. ". (Searching by exact clean name for simplicity).")
        return
    end

    -- Apply level change (menggunakan targetPlayer.setLevel)
    if targetPlayer.setLevel then
        targetPlayer:setLevel(levelAmount)
    -- ... (logic alternatif level change yang lain dihilangkan untuk fokus pada inti)
    else
        player:onConsoleMessage("`4Error: `oLevel modification functions are unavailable in this server version.")
        return
    end

    -- Check for Blue Name Title at level 125
    if targetPlayer.getLevel then
        local newLevel = targetPlayer:getLevel()
        if newLevel >= 125 then
            if targetPlayer.addTitle and not targetPlayer:hasTitle(BLUE_NAME_TITLE_ID) then
                targetPlayer:addTitle(BLUE_NAME_TITLE_ID)
                player:onConsoleMessage(">> `w" .. targetPlayer:getCleanName() .. "`2 reached level 125! Blue Name Title awarded.")
            end
        else
            if targetPlayer.removeTitle and targetPlayer:hasTitle(BLUE_NAME_TITLE_ID) then
                targetPlayer:removeTitle(BLUE_NAME_TITLE_ID)
                player:onConsoleMessage(">> `w" .. targetPlayer:getCleanName() .. "`4 dropped below level 125. Blue Name Title removed.")
            end
        end
    end

    -- Confirmation message
    player:onConsoleMessage(">> Set level of `w" .. targetPlayer:getCleanName() .. " to `$" .. (levelAmount) .. ".")
end


-- Fungsi untuk menampilkan GUI (Diubah ke format string dialog)
function showSetLevelGui(player)
    local maxLevel = getMaxLevel and getMaxLevel() or 125
    local dialogName = "setlevel_gui"
    
    local gui = table.concat({
        "set_bg_color|50,0,100,180|", -- Custom Background Color: Ungu tua transparan
        "set_border_color|255,100,0,255|", -- Custom Border Color: Oranye
        "add_label_with_icon|big|Set Player Level `2(" .. maxLevel .. " Max`w)|left|242|",
        "add_spacer|small|",
        "add_textbox|`oThis script is used to set player level.|left|",
        "add_spacer|small|",
        "add_text_input|target_name|Player name:||20|",
        "add_text_input|level_amount|Amount  :| " .. 0 .. "|5|",
        "add_spacer|small|",
        "add_button|submit_level|`2SET LEVEL|noflags|0|0|",
        "add_quick_exit|",
        "end_dialog|" .. dialogName .. "|||"
    }, "\n")

    player:onDialogRequest(gui)
end


-- Command logic yang telah dimodifikasi
onPlayerCommandCallback(function(world, player, fullCommand)
    local command, message = fullCommand:match("^(%S+)%s*(.*)")
    if command == setLevelCommandData.command then
        -- Permission check
        if not player:hasRole(setLevelCommandData.roleRequired) then
            player:onConsoleMessage("`4Error: `oYou do not have permission to use this command.")
            return true
        end

        -- Parse arguments
        local targetName, levelAmount = message:match("^(%S+)%s+(%d+)$")

        -- Dynamically get the maximum level from the server
        local maxLevel = getMaxLevel and getMaxLevel() or 125

        if targetName and levelAmount then
            -- Jika argumen lengkap, proses langsung (seperti skrip asli)
            processSetLevel(world, player, targetName, levelAmount, maxLevel)
        else
            -- Jika tidak ada argumen atau tidak lengkap, tampilkan GUI
            showSetLevelGui(player)
        end
        return true
    end
    return false
end)

-- Dialog callback untuk memproses input dari GUI yang baru
onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"]
    local buttonClicked = data["buttonClicked"]

    if dialogName == "setlevel_gui" and buttonClicked == "submit_level" then
        local targetName = data.target_name or ""
        local levelAmount = data.level_amount or ""
        
        -- Panggil fungsi pemrosesan utama
        if targetName:len() > 0 and levelAmount:len() > 0 then
             -- Dynamically get the maximum level from the server inside the callback too
            local currentMaxLevel = getMaxLevel and getMaxLevel() or 125
            processSetLevel(world, player, targetName, levelAmount, currentMaxLevel)
        else
            player:onConsoleMessage("`4Error: `oNama pemain dan Jumlah Level harus diisi.")
        end
        return true
    end
    return false
end)
