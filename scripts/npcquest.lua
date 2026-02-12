-- Script untuk: NPC Quest System
local NPC_ID = 25154
local ROLE_ADMIN = 51
local CFG_KEY = "NPC_QUEST_CONFIG_V1"
local PLAYER_DATA_PREFIX = "NPC_QUEST_PLAYER_V1_"
local cfg = nil
local playerCache = {}
-- Default configuration (akan di-load atau diinisialisasi)
local DEFAULT_CONFIG = {
    req_item_id = 18, -- Default: Dirt
    req_item_count = 100,
    reward_item_id = 20234, -- Default dari prompt
    reward_item_count = 1
}
local function getItemName(itemID)
    local item = getItem(itemID)
    if item and item.getName then
        return item:getName()
    end
    return "Unknown Item (" .. tostring(itemID) .. ")"
end
local function stripColors(s)
    if not s then return "" end
    s = tostring(s)
    s = s:gsub("`.", "") -- Menghapus kode warna Growtopia
    return s
end
local function loadConfig()
    local data = loadDataFromServer(CFG_KEY)
    if type(data) == "table" then
        cfg = data
    else
        cfg = DEFAULT_CONFIG
    end
    -- Memastikan semua field ada dan tipe data benar
    cfg.req_item_id = tonumber(cfg.req_item_id) or DEFAULT_CONFIG.req_item_id
    cfg.req_item_count = tonumber(cfg.req_item_count) or DEFAULT_CONFIG.req_item_count
    cfg.reward_item_id = tonumber(cfg.reward_item_id) or DEFAULT_CONFIG.reward_item_id
    cfg.reward_item_count = tonumber(cfg.reward_item_count) or DEFAULT_CONFIG.reward_item_count
    saveDataToServer(CFG_KEY, cfg) -- Simpan untuk memastikan default terisi jika baru
end
local function saveConfig()
    saveDataToServer(CFG_KEY, cfg)
end
local function getPlayerKey(userID)
    return PLAYER_DATA_PREFIX .. tostring(userID)
end
local function loadPlayerQuest(player)
    local userID = player:getUserID()
    if playerCache[userID] then
        return playerCache[userID]
    end
    local data = loadDataFromServer(getPlayerKey(userID))
    if type(data) == "table" then
        playerCache[userID] = data
    else
        playerCache[userID] = { progress = 0, claimed = false }
    end
    -- Memastikan semua field ada dan tipe data benar
    playerCache[userID].progress = tonumber(playerCache[userID].progress) or 0
    playerCache[userID].claimed = (playerCache[userID].claimed == true)
    return playerCache[userID]
end
local function savePlayerQuest(player)
    local userID = player:getUserID()
    if playerCache[userID] then
        saveDataToServer(getPlayerKey(userID), playerCache[userID])
    end
end
-- Callback untuk menyimpan data secara otomatis
onAutoSaveRequest(function()
    saveConfig()
    for userID, _ in pairs(playerCache) do
        -- Hanya simpan pemain yang masih online atau yang datanya di-cache
        local p = getPlayer(userID)
        if p and p:isOnline() then
            savePlayerQuest(p)
        end
    end
end)
-- Helper untuk menambahkan item atau menjatuhkannya jika inventori penuh
local function addOrDrop(world, player, itemID, amount)
    if amount <= 0 then return true end
    local remaining = amount
    while remaining > 0 do
        local chunk = math.min(remaining, 250) -- Max stack size
        local success = player:changeItem(itemID, chunk, 0) -- Coba tambahkan ke inventori
        if not success then
            -- Jika gagal, coba jatuhkan di dunia
            if world and world.spawnItem then
                world:spawnItem(player:getPosX(), player:getPosY(), itemID, chunk)
                player:onConsoleMessage("`4Inventory full! Dropped " .. chunk .. "x " .. stripColors(getItemName(itemID)) .. " on the ground.")
            else
                player:onConsoleMessage("`4Failed to add " .. chunk .. "x " .. stripColors(getItemName(itemID)) .. ". Inventory full and cannot drop.")
                return false
            end
        end
        remaining = remaining - chunk
    end
    return true
end
-- Helper untuk menghapus item dari inventori
local function removeItems(player, itemID, amount)
    if amount <= 0 then return true end
    local currentAmount = player:getItemAmount(itemID) or 0
    if currentAmount < amount then
        return false -- Tidak cukup item
    end
    return player:changeItem(itemID, -amount, 0)
end
-- Dialog utama NPC Quest
local function showNpcQuestDialog(player)
    local pData = loadPlayerQuest(player)
    local reqItemName = getItemName(cfg.req_item_id)
    local rewardItemName = getItemName(cfg.reward_item_id)
    local playerHasReq = player:getItemAmount(cfg.req_item_id) or 0
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wNPC Quest: Collect " .. stripColors(reqItemName) .. "|left|" .. tostring(NPC_ID) .. "|\n"
    dialog = dialog .. "text_scaling_string|Subscribtions++++++++|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "`wHello, `2" .. player:getName() .. "`w! I need your help to collect some items.|\n"
    dialog = dialog .. "add_textbox|`wYour task: Collect `2" .. cfg.req_item_count .. "`w x `2" .. stripColors(reqItemName) .. "`w.|\n"
    dialog = dialog .. "add_textbox|`wYour progress: `2" .. pData.progress .. "`w / `2" .. cfg.req_item_count .. "`w.|\n"
    dialog = dialog .. "add_textbox|`wYou have: `2" .. playerHasReq .. "`w x `2" .. stripColors(reqItemName) .. "`w in your inventory.|\n"
    dialog = dialog .. "add_spacer|small|\n"
    if pData.claimed then
        dialog = dialog .. "add_textbox|`5You have already claimed your reward for this quest.|\n"
    elseif pData.progress >= cfg.req_item_count then
        dialog = dialog .. "add_button|claim_reward|`2Claim Reward: `w" .. cfg.reward_item_count .. " x " .. stripColors(rewardItemName) .. "|noflags|0|0|\n"
    else
        dialog = dialog .. "add_button|submit_items|`2Submit Items`w (You have `2" .. playerHasReq .. "`w)|\n"
    end
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|npc_quest_main|||\n"
    player:onDialogRequest(dialog)
end
-- Dialog konfirmasi submit item
local function showSubmitConfirmDialog(player, amountToSubmit)
    local reqItemName = getItemName(cfg.req_item_id)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wConfirm Submission|left|" .. tostring(NPC_ID) .. "|\n"
    dialog = dialog .. "text_scaling_string|Subscribtions++++++++|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`wAre you sure you want to submit `2" .. amountToSubmit .. "`w x `2" .. stripColors(reqItemName) .. "`w?|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|confirm_submit|`2Confirm|\n"
    dialog = dialog .. "add_button|cancel_submit|`4Cancel|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|npc_quest_submit|||\n"
    player:onDialogRequest(dialog)
end
-- Admin: Dialog utama pengaturan quest
local function showSetNpcQuestMain(player)
    local reqItemName = getItemName(cfg.req_item_id)
    local rewardItemName = getItemName(cfg.reward_item_id)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wNPC Quest Settings|left|" .. tostring(NPC_ID) .. "|\n"
    dialog = dialog .. "text_scaling_string|Subscribtions++++++++|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`wCurrent Quest Configuration:|\n"
    dialog = dialog .. "add_textbox|`wRequired Item: `2" .. cfg.req_item_count .. "`w x `2" .. stripColors(reqItemName) .. "`w (ID: `2" .. cfg.req_item_id .. "`w)|\n"
    dialog = dialog .. "add_textbox|`wReward Item: `2" .. cfg.reward_item_count .. "`w x `2" .. stripColors(rewardItemName) .. "`w (ID: `2" .. cfg.reward_item_id .. "`w)|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|set_req_item|`2Set Required Item|\n"
    dialog = dialog .. "add_button|set_reward_item|`2Set Reward Item|\n"
    dialog = dialog .. "add_button|reset_player_progress|`4Reset Player Quest Progress|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|set_npc_quest_main|||\n"
    player:onDialogRequest(dialog)
end
-- Admin: Dialog pengaturan item yang dibutuhkan
local function showSetReqItemDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wSet Required Item|left|" .. tostring(NPC_ID) .. "|\n"
    dialog = dialog .. "text_scaling_string|Subscribtions++++++++|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`wEnter the Item ID and Count required for the quest.|\n"
    dialog = dialog .. "add_text_input|req_item_id|Item ID|" .. tostring(cfg.req_item_id) .. "|6|\n"
    dialog = dialog .. "add_text_input|req_item_count|Item Count|" .. tostring(cfg.req_item_count) .. "|6|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|save_req_item|`2Save|\n"
    dialog = dialog .. "add_button|back_to_set_main|`4Back|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|set_npc_quest_req_item|||\n"
    player:onDialogRequest(dialog)
end
-- Admin: Dialog pengaturan item hadiah
local function showSetRewardItemDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wSet Reward Item|left|" .. tostring(NPC_ID) .. "|\n"
    dialog = dialog .. "text_scaling_string|Subscribtions++++++++|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`wEnter the Item ID and Count for the quest reward.|\n"
    dialog = dialog .. "add_text_input|reward_item_id|Item ID|" .. tostring(cfg.reward_item_id) .. "|6|\n"
    dialog = dialog .. "add_text_input|reward_item_count|Item Count|" .. tostring(cfg.reward_item_count) .. "|6|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|save_reward_item|`2Save|\n"
    dialog = dialog .. "add_button|back_to_set_main|`4Back|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|set_npc_quest_reward_item|||\n"
    player:onDialogRequest(dialog)
end
-- Admin: Dialog reset progress pemain
local function showResetPlayerProgressDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wReset Player Progress|left|" .. tostring(NPC_ID) .. "|\n"
    dialog = dialog .. "text_scaling_string|Subscribtions++++++++|\n"
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`wEnter the name of the player whose quest progress you want to reset.|\n"
    dialog = dialog .. "add_text_input|player_name|Player Name||24|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|confirm_reset_player|`4Reset|\n"
    dialog = dialog .. "add_button|back_to_set_main|`4Back|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|set_npc_quest_reset_player|||\n"
    player:onDialogRequest(dialog)
end
-- Inisialisasi konfigurasi saat script dimuat
loadConfig()
-- Daftarkan command admin
registerLuaCommand({
    command = "setnpcquest",
    roleRequired = ROLE_ADMIN,
    description = "Configure the NPC quest system."
})
-- Callback saat pemain menggunakan wrench pada NPC
onTileWrenchCallback(function(world, player, tile)
    if tile:getTileID() == NPC_ID then
        showNpcQuestDialog(player)
        return true
    end
    return false
end)
-- Callback saat pemain mengetik command
onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if cmd == "setnpcquest" then
        if player:hasRole(ROLE_ADMIN) then
            showSetNpcQuestMain(player)
        else
            player:onConsoleMessage("`4You do not have permission to use this command.")
        end
        return true
    end
    return false
end)
-- Callback saat pemain berinteraksi dengan dialog
onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"] or ""
    local buttonClicked = data["buttonClicked"] or ""
    -- Dialog utama NPC Quest
    if dialogName == "npc_quest_main" then
        if buttonClicked == "submit_items" then
            local pData = loadPlayerQuest(player)
            local playerHasReq = player:getItemAmount(cfg.req_item_id) or 0
            local needed = cfg.req_item_count - pData.progress
            local amountToSubmit = math.min(playerHasReq, needed)
            if amountToSubmit <= 0 then
                player:onConsoleMessage("`4You don't have any " .. stripColors(getItemName(cfg.req_item_id)) .. " to submit or quest is complete.")
                showNpcQuestDialog(player)
                return true
            end
            showSubmitConfirmDialog(player, amountToSubmit)
            return true
        elseif buttonClicked == "claim_reward" then
            local pData = loadPlayerQuest(player)
            if pData.claimed then
                player:onConsoleMessage("`4You have already claimed your reward.")
                showNpcQuestDialog(player)
                return true
            end
            if pData.progress < cfg.req_item_count then
                player:onConsoleMessage("`4You have not completed the quest yet.")
                showNpcQuestDialog(player)
                return true
            end
            -- Berikan hadiah
            local success = addOrDrop(world, player, cfg.reward_item_id, cfg.reward_item_count)
            if success then
                pData.claimed = true
                savePlayerQuest(player)
                player:onConsoleMessage("`2You have claimed your reward: `w" .. cfg.reward_item_count .. " x " .. stripColors(getItemName(cfg.reward_item_id)) .. "`w!")
                player:playAudio("success.wav")
            else
                player:onConsoleMessage("`4Failed to give reward. Please make sure your inventory has space.")
            end
            showNpcQuestDialog(player)
            return true
        end
        -- Jika tombol lain atau quick_exit, tutup dialog
        return true
    end
    -- Dialog konfirmasi submit item
    if dialogName == "npc_quest_submit" then
        if buttonClicked == "confirm_submit" then
            local pData = loadPlayerQuest(player)
            local playerHasReq = player:getItemAmount(cfg.req_item_id) or 0
            local needed = cfg.req_item_count - pData.progress
            local amountToSubmit = math.min(playerHasReq, needed)
            if amountToSubmit <= 0 then
                player:onConsoleMessage("`4You don't have any " .. stripColors(getItemName(cfg.req_item_id)) .. " to submit or quest is complete.")
                showNpcQuestDialog(player)
                return true
            end
            local success = removeItems(player, cfg.req_item_id, amountToSubmit)
            if success then
                pData.progress = pData.progress + amountToSubmit
                savePlayerQuest(player)
                player:onConsoleMessage("`2You submitted `w" .. amountToSubmit .. "`w x `w" .. stripColors(getItemName(cfg.req_item_id)) .. "`w. Progress: `2" .. pData.progress .. "`w / `2" .. cfg.req_item_count .. "`w.")
                player:playAudio("item_collect.wav")
            else
                player:onConsoleMessage("`4Failed to remove items from your inventory.")
            end
            showNpcQuestDialog(player)
            return true
        elseif buttonClicked == "cancel_submit" then
            showNpcQuestDialog(player)
            return true
        end
        return true
    end
    -- Admin: Dialog utama pengaturan quest
    if dialogName == "set_npc_quest_main" then
        if buttonClicked == "set_req_item" then
            showSetReqItemDialog(player)
            return true
        elseif buttonClicked == "set_reward_item" then
            showSetRewardItemDialog(player)
            return true
        elseif buttonClicked == "reset_player_progress" then
            showResetPlayerProgressDialog(player)
            return true
        end
        return true
    end
    -- Admin: Dialog pengaturan item yang dibutuhkan
    if dialogName == "set_npc_quest_req_item" then
        if buttonClicked == "save_req_item" then
            local newReqItemID = tonumber(data["req_item_id"])
            local newReqItemCount = tonumber(data["req_item_count"])
            if not newReqItemID or newReqItemID <= 0 then
                player:onConsoleMessage("`4Invalid Required Item ID.")
                showSetReqItemDialog(player)
                return true
            end
            if not newReqItemCount or newReqItemCount <= 0 then
                player:onConsoleMessage("`4Invalid Required Item Count.")
                showSetReqItemDialog(player)
                return true
            end
            cfg.req_item_id = newReqItemID
            cfg.req_item_count = newReqItemCount
            saveConfig()
            player:onConsoleMessage("`2Required item updated to `w" .. newReqItemCount .. " x " .. stripColors(getItemName(newReqItemID)) .. "`w.")
            showSetNpcQuestMain(player)
            return true
        elseif buttonClicked == "back_to_set_main" then
            showSetNpcQuestMain(player)
            return true
        end
        return true
    end
    -- Admin: Dialog pengaturan item hadiah
    if dialogName == "set_npc_quest_reward_item" then
        if buttonClicked == "save_reward_item" then
            local newRewardItemID = tonumber(data["reward_item_id"])
            local newRewardItemCount = tonumber(data["reward_item_count"])
            if not newRewardItemID or newRewardItemID <= 0 then
                player:onConsoleMessage("`4Invalid Reward Item ID.")
                showSetRewardItemDialog(player)
                return true
            end
            if not newRewardItemCount or newRewardItemCount <= 0 then
                player:onConsoleMessage("`4Invalid Reward Item Count.")
                showSetRewardItemDialog(player)
                return true
            end
            cfg.reward_item_id = newRewardItemID
            cfg.reward_item_count = newRewardItemCount
            saveConfig()
            player:onConsoleMessage("`2Reward item updated to `w" .. newRewardItemCount .. " x " .. stripColors(getItemName(newRewardItemID)) .. "`w.")
            showSetNpcQuestMain(player)
            return true
        elseif buttonClicked == "back_to_set_main" then
            showSetNpcQuestMain(player)
            return true
        end
        return true
    end
    -- Admin: Dialog reset progress pemain
    if dialogName == "set_npc_quest_reset_player" then
        if buttonClicked == "confirm_reset_player" then
            local targetPlayerName = data["player_name"]
            if not targetPlayerName or targetPlayerName == "" then
                player:onConsoleMessage("`4Please enter a player name.")
                showResetPlayerProgressDialog(player)
                return true
            end
            local targetPlayer = getPlayerByName(targetPlayerName)
            if targetPlayer then
                local pData = loadPlayerQuest(targetPlayer)
                pData.progress = 0
                pData.claimed = false
                savePlayerQuest(targetPlayer)
                player:onConsoleMessage("`2Quest progress for `w" .. targetPlayer:getName() .. "`w has been reset.")
            else
                -- Jika pemain tidak online, coba load dari data server
                local allPlayers = getAllPlayers()
                local foundUserID = nil
                for _, p in ipairs(allPlayers) do
                    if p:getCleanName():lower() == targetPlayerName:lower() then
                        foundUserID = p:getUserID()
                        break
                    end
                end
                if foundUserID then
                    local offlinePlayerData = loadDataFromServer(getPlayerKey(foundUserID))
                    if type(offlinePlayerData) == "table" then
                        offlinePlayerData.progress = 0
                        offlinePlayerData.claimed = false
                        saveDataToServer(getPlayerKey(foundUserID), offlinePlayerData)
                        player:onConsoleMessage("`2Quest progress for offline player `w" .. targetPlayerName .. "`w has been reset.")
                    else
                        player:onConsoleMessage("`4Could not find player data for `w" .. targetPlayerName .. "`w.")
                    end
                else
                    player:onConsoleMessage("`4Player `w" .. targetPlayerName .. "`w not found (online or offline).")
                end
            end
            showSetNpcQuestMain(player)
            return true
        elseif buttonClicked == "back_to_set_main" then
            showSetNpcQuestMain(player)
            return true
        end
        return true
    end
    return false
end)

print("Script loaded")
