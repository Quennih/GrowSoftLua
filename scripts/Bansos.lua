print("Loaded Giveaway System by Marine")

-- Konfigurasi utama
local GIVEAWAY_SAVE_KEY = "MARINE_GIVEAWAY_DATA"
local MAX_GIVEAWAY_ITEMS = 15 -- Batas maksimum item yang bisa di-giveaway

-- Konfigurasi untuk Discord Webhook
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1439338121295565134/rmHKuf4zHfWycSwxoKS2ZtdoxoykOZl6BtRagz-o-SueDCYDqu11MXLlUXS_teLaneH" -- Ganti dengan URL webhook Discord Anda

-- Global storage untuk data giveaway
_G.MarineGiveaway = _G.MarineGiveaway or {
    active = false,
    items = {},
    creatorUserID = nil,
    creatorName = nil,
    giveawayStartTime = nil,
    claimedPlayers = {},
}

-- Konfigurasi perintah
local giveawayAdminCommandData = {
    command = "bansos",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Mengelola giveaway item untuk semua pemain."
}

local claimCommandData = {
    command = "claim",
    roleRequired = Roles.ROLE_NONE,
    description = "Mengambil hadiah giveaway yang aktif."
}

-- Session data untuk dialog item picker admin
local adminGiveawaySession = {}
local ITEMS_PER_PICKER_PAGE = 28

-- --- Helper Functions ---
local function findPlayerByNameInsensitive(inputName)
    local target = string.lower(inputName)
    for _, p in ipairs(getServerPlayers()) do
        if string.lower(p:getCleanName()) == target then
            return p
        end
    end
    return nil
end

local function getItemNameByID(itemID)
    local item = getItem(itemID)
    return (item and item:getName()) or "Unknown Item"
end

local function formatItemList(items)
    if not items or #items == 0 then return "`cTidak ada item yang diatur.``" end
    local itemStrings = {}
    for _, itemData in ipairs(items) do
        table.insert(itemStrings, "`w" .. itemData.itemCount .. "x " .. getItemNameByID(itemData.itemID) .. " (ID: " .. itemData.itemID .. ")``")
    end
    return table.concat(itemStrings, "\n")
end

-- --- Persistent Data Handling ---
local function saveGiveawayData()
    saveDataToServer(GIVEAWAY_SAVE_KEY, _G.MarineGiveaway)
end

local function loadGiveawayData()
    local loadedData = loadDataFromServer(GIVEAWAY_SAVE_KEY)
    if loadedData and type(loadedData) == "table" then
        if loadedData.itemID ~= nil and loadedData.itemCount ~= nil then
            if not loadedData.items then loadedData.items = {} end
            table.insert(loadedData.items, { itemID = loadedData.itemID, itemCount = loadedData.itemCount })
            loadedData.itemID = nil
            loadedData.itemCount = nil
        end
        for k, v in pairs(loadedData) do
            _G.MarineGiveaway[k] = v
        end
    end
end

-- --- Dialog Builders ---
local function buildGiveawayAdminMainDialog(player)
    local s = "set_default_color|`w\nset_bg_color|30,30,30,220|\n"
    s = s .. "add_label_with_icon|big|Giveaway Admin|left|6016|\n"
    s = s .. "add_textbox|Kelola giveaway item untuk semua pemain.|\n"
    s = s .. "add_spacer|small|\n"

    if _G.MarineGiveaway.active then
        local claimedCount = 0
        for _, v in pairs(_G.MarineGiveaway.claimedPlayers) do
            if v then claimedCount = claimedCount + 1 end
        end

        s = s .. "add_textbox|`2Giveaway Aktif:|\n"
        s = s .. formatItemList(_G.MarineGiveaway.items) .. "\n"
        s = s .. "add_textbox|Dibuat oleh: `w" .. (_G.MarineGiveaway.creatorName or "Developer") .. " |\n"
        s = s .. "add_textbox|Telah diklaim oleh: `w" .. claimedCount .. " pemain|\n"
        s = s .. "add_spacer|small|\n"
        s = s .. "add_button|btn_cancel_giveaway|`4Batalkan Giveaway Aktif|noflags|\n"
    else
        s = s .. "add_textbox|`oTidak ada giveaway aktif saat ini. Buat yang baru!|\n"
    end

    s = s .. "add_spacer|small|\n"
    s = s .. "add_button|btn_configure_giveaway_items|`2Konfigurasi Item Giveaway|noflags|\n"
    s = s .. "add_quick_exit|\n"
    s = s .. "end_dialog|giveaway_admin_main|Tutup|\n"
    return s
end

local function buildGiveawayConfigureItemsDialog(player)
    local s = "set_default_color|`w\n"
    s = s .. "add_label_with_icon|big|Konfigurasi Item Giveaway|left|1434|\n"
    s = s .. "add_textbox|Atur item yang akan menjadi hadiah giveaway (maksimal " .. MAX_GIVEAWAY_ITEMS .. "). Ketuk ikon untuk menghapus.|\n"
    s = s .. "add_spacer|small|\n"
    
    if #_G.MarineGiveaway.items > 0 then
        local perRow = 4
        local col = 0
        for i, itemData in ipairs(_G.MarineGiveaway.items) do
            s = s .. "add_button_with_icon|btn_remove_item_"..i.."||staticWhiteFrame|"..itemData.itemID.."|"..itemData.itemCount.."|left|\n"
            col = col + 1
            if col >= perRow then
                s = s .. "add_custom_break|\n"
                col = 0
            end
        end
        if col ~= 0 then s = s .. "add_custom_break|\n" end
    else
        s = s .. "add_smalltext|`oBelum ada item giveaway yang diatur.|left|\n"
    end

    s = s .. "add_spacer|small|\n"

    if #_G.MarineGiveaway.items < MAX_GIVEAWAY_ITEMS then
        s = s .. "add_textbox|`2Tambah Item Baru:|\n"
        s = s .. "add_text_input|field_item_id|ID Item Manual|0|9|numeric|\n"
        s = s .. "add_text_input|field_item_qty|Jumlah Manual|1|9|numeric|\n"
        s = s .. "add_button|btn_add_manual_item|Tambah Item (Manual)|noflags|\n"
        s = s .. "add_spacer|small|\n"
        s = s .. "add_button|btn_open_picker|Buka Item Picker Inventaris|noflags|\n"
    else
        s = s .. "add_textbox|`4Anda telah mencapai batas maksimum " .. MAX_GIVEAWAY_ITEMS .. " item giveaway.|\n"
    end
    
    s = s .. "add_spacer|small|\n"
    if #_G.MarineGiveaway.items > 0 then
        s = s .. "add_button|btn_start_manual_giveaway|`2Mulai Giveaway MANUAL Sekarang!|noflags|\n"
    else
        s = s .. "add_button|btn_start_manual_giveaway|`sMulai Giveaway MANUAL Sekarang!|off|\n"
    end
    s = s .. "add_button|btn_back_admin_main|Kembali ke Admin Utama|noflags|\n"
    s = s .. "end_dialog|giveaway_configure_items||\n"
    return s
end

local function buildGiveawayItemPicker(player, page)
    local net = player:getNetID()
    local sess = adminGiveawaySession[net] or { page = 1, items = {}, filteredItems = {} }
    adminGiveawaySession[net] = sess

    local inv = player:getInventoryItems() or {}
    sess.items = {}
    for _, it in ipairs(inv) do
        local id = (it.getItemID and it:getItemID()) or it.id
        local c  = (it.getItemCount and it:getItemCount()) or it.count or 0
        if id and c and c > 0 then table.insert(sess.items, { id=id, count=c, name=getItemNameByID(id) }) end
    end
    table.sort(sess.items, function(a,b) return a.name < b.name end)

    local total = #sess.items
    local maxp = math.max(1, math.ceil(total / ITEMS_PER_PICKER_PAGE))
    sess.page = math.min(math.max(tonumber(page or sess.page or 1) or 1, 1), maxp)

    local start = (sess.page-1)*ITEMS_PER_PICKER_PAGE + 1
    local finish = math.min(total, start + ITEMS_PER_PICKER_PAGE - 1)

    local s = "set_default_color|`w\n"
    s = s .. "add_label_with_icon|big|Pilih dari Inventaris Anda|left|1434|\n"
    s = s .. "add_textbox|Halaman "..tostring(sess.page).." / "..tostring(maxp).."|left|\n"
    if sess.page > 1 then s = s .. "add_button|picker_prev|Sebelumnya|noflags|\n" end
    if sess.page < maxp then s = s .. "add_button|picker_next|Berikutnya|noflags|\n" end
    s = s .. "add_spacer|small|\n"

    if total == 0 then
        s = s .. "add_textbox|`cInventaris Anda kosong.|left|\n"
    else
        for i=start, finish do
            local it = sess.items[i]
            s = s .. "add_checkicon|picker_item_"..it.id.."|"..it.name.." (ID:"..it.id..") x"..it.count.."|noflags|"..it.id.."||0|\n"
        end
        s = s .. "add_custom_break|\nadd_spacer|small|\n"
        s = s .. "add_text_input|picker_qty|Jumlah Giveaway|1|9|numeric|\n"
        s = s .. "add_button|picker_confirm|Konfirmasi Pilihan|noflags|\n"
    end
    s = s .. "add_button|picker_back|Kembali|noflags|\n"
    s = s .. "end_dialog|giveaway_item_picker||\n"
    player:onDialogRequest(s)
end

local function buildGiveawayConfirmStartManualDialog(player)
    local s = "set_default_color|`w\n"
    s = s .. "add_label_with_icon|big|Konfirmasi Item Giveaway|left|6016|\n"
    s = s .. "add_textbox|`oAnda akan memulai giveaway untuk item-item berikut:|\n"
    s = s .. formatItemList(_G.MarineGiveaway.items) .. "\n"
    s = s .. "add_spacer|small|\n"
    s = s .. "add_textbox|`4Ini akan memicu giveaway `wMANUAL`o oleh `wDeveloper`o. Semua pemain (online dan offline) akan dapat mengklaim item ini satu kali.|\n"
    s = s .. "add_textbox|`4Kalau Mau Buat Lagi Matikan GA Yang Sedang Berjalan Bos.|\n"
    s = s .. "add_spacer|small|\n"
    s = s .. "add_button|btn_confirm_manual_giveaway|`2Mulai Giveaway Sekarang!|noflags|\n"
    s = s .. "add_button|btn_back_configure_items|Batalkan|noflags|\n"
    s = s .. "end_dialog|giveaway_confirm_start_manual||\n"
    player:onDialogRequest(s)
end

-- --- Callbacks ---
registerLuaCommand(giveawayAdminCommandData)
registerLuaCommand(claimCommandData)

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, args = fullCommand:match("^(%S+)%s*(.*)")

    if command == giveawayAdminCommandData.command then
        if not player:hasRole(giveawayAdminCommandData.roleRequired) then
            player:onConsoleMessage("`4Perintah tidak dikenal. `oKetik /? untuk daftar perintah yang valid.")
            return true
        end
        player:onDialogRequest(buildGiveawayAdminMainDialog(player))
        return true
    end

    if command == claimCommandData.command then
        if not _G.MarineGiveaway.active then
            player:onConsoleMessage("`4Tidak ada giveaway aktif saat ini. `oPantau pengumuman!")
            player:playAudio("bleep_fail.wav")
            return true
        end

        local userID = player:getUserID()
        if _G.MarineGiveaway.claimedPlayers[userID] then
            player:onConsoleMessage("`4Anda sudah mengklaim giveaway ini. `oSilakan tunggu giveaway berikutnya!")
            player:playAudio("bleep_fail.wav")
            return true
        end

        local itemsToGive = _G.MarineGiveaway.items
        if not itemsToGive or #itemsToGive == 0 then
            player:onConsoleMessage("`4Terjadi kesalahan: `oTidak ada item yang terdaftar untuk giveaway ini.")
            player:playAudio("bleep_fail.wav")
            return true
        end

        local allItemsGiven = true
        local givenItemStrings = {}
        local failedItemStrings = {}

        for _, itemData in ipairs(itemsToGive) do
            local itemID = itemData.itemID
            local itemCount = itemData.itemCount
            local itemName = getItemNameByID(itemID)

            local success = player:changeItem(itemID, itemCount, 0)
            if success then
                table.insert(givenItemStrings, "`w" .. itemCount .. "x " .. itemName .. "``")
            else
                allItemsGiven = false
                table.insert(failedItemStrings, "`4" .. itemCount .. "x " .. itemName .. "``")
            end
        end

        if allItemsGiven then
            _G.MarineGiveaway.claimedPlayers[userID] = true
            saveGiveawayData()

            player:onConsoleMessage("`2Berhasil! `oAnda telah mengklaim:\n" .. table.concat(givenItemStrings, ", ") .. ".")
            player:onTextOverlay("`2DIKLAIM! " .. #itemsToGive .. " item hadiah!")
            player:playAudio("cash_register.wav")
        else
            player:onConsoleMessage("`4Gagal mengklaim beberapa item. `oMungkin inventaris Anda penuh atau terjadi kesalahan. Item yang gagal:\n" .. table.concat(failedItemStrings, ", ") .. ".")
            player:playAudio("bleep_fail.wav")
        end
        return true
    end

    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"]
    local button = data["buttonClicked"]
    local userID = player:getUserID()
    local netID = player:getNetID()

    if dialogName == "giveaway_admin_main" then
        if button == "btn_configure_giveaway_items" then
            adminGiveawaySession[netID] = adminGiveawaySession[netID] or { page = 1, items = {}, filteredItems = {}, searchQuery = {} }
            player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
            return true
        elseif button == "btn_cancel_giveaway" then
            if _G.MarineGiveaway.active then
                _G.MarineGiveaway.active = false
                _G.MarineGiveaway.items = {}
                _G.MarineGiveaway.creatorUserID = nil
                _G.MarineGiveaway.creatorName = nil
                _G.MarineGiveaway.giveawayStartTime = nil
                _G.MarineGiveaway.claimedPlayers = {}
                saveGiveawayData()
                player:onConsoleMessage("`2Giveaway aktif telah dibatalkan.")
                for _, p in ipairs(getServerPlayers()) do
                    p:onTextOverlay("`4GIVEAWAY DIBATALKAN!")
                    p:onConsoleMessage("`4Giveaway telah dibatalkan oleh developer. `oNantikan giveaway baru!")
                end
            else
                player:onConsoleMessage("`4Tidak ada giveaway aktif untuk dibatalkan.")
            end
            player:onDialogRequest(buildGiveawayAdminMainDialog(player))
            return true
        end
        return false
    end

    if dialogName == "giveaway_configure_items" then
        local currentItemsCount = #_G.MarineGiveaway.items

        if button == "btn_add_manual_item" then
            if currentItemsCount >= MAX_GIVEAWAY_ITEMS then
                player:onConsoleMessage("`4Gagal menambah: `oAnda telah mencapai batas maksimum " .. MAX_GIVEAWAY_ITEMS .. " item giveaway.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                return true
            end
            local id = tonumber(data.field_item_id or "")
            local qty = tonumber(data.field_item_qty or "")
            if id and qty and qty > 0 then
                table.insert(_G.MarineGiveaway.items, { itemID = id, itemCount = qty })
                saveGiveawayData()
                player:onConsoleMessage("`2Item `w" .. getItemNameByID(id) .. " x" .. qty .. "`` berhasil ditambahkan.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                return true
            else
                player:onConsoleMessage("`4Gagal menambah: `oIsi ID Item & Jumlah yang valid.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                return true
            end
        elseif button == "btn_open_picker" then
            if currentItemsCount >= MAX_GIVEAWAY_ITEMS then
                player:onConsoleMessage("`4Gagal menambah: `oAnda telah mencapai batas maksimum " .. MAX_GIVEAWAY_ITEMS .. " item giveaway.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                return true
            end
            buildGiveawayItemPicker(player, 1)
            return true
        elseif button == "btn_start_manual_giveaway" then
            if #_G.MarineGiveaway.items > 0 then
                adminGiveawaySession[netID].pendingManualStartConfirm = true
                player:onDialogRequest(buildGiveawayConfirmStartManualDialog(player))
            else
                player:onConsoleMessage("`4Tidak ada item giveaway yang diatur untuk memulai manual giveaway.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
            end
            return true
        elseif button == "btn_back_admin_main" then
            player:onDialogRequest(buildGiveawayAdminMainDialog(player))
            return true
        else
            local itemIndex = button:match("^btn_remove_item_(%d+)$")
            if itemIndex then
                local index = tonumber(itemIndex)
                if index and _G.MarineGiveaway.items[index] then
                    local removedItem = table.remove(_G.MarineGiveaway.items, index)
                    saveGiveawayData()
                    player:onConsoleMessage("`2Item `w" .. getItemNameByID(removedItem.itemID) .. " x" .. removedItem.itemCount .. "`` berhasil dihapus.")
                    player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                    return true
                end
            end
        end
        return false
    end

    if dialogName == "giveaway_item_picker" then
        local sess = adminGiveawaySession[netID]
        if not sess then return false end

        if button == "picker_prev" then
            buildGiveawayItemPicker(player, sess.page - 1)
            return true
        elseif button == "picker_next" then
            buildGiveawayItemPicker(player, sess.page + 1)
            return true
        elseif button == "picker_confirm" then
            if #_G.MarineGiveaway.items >= MAX_GIVEAWAY_ITEMS then
                player:onConsoleMessage("`4Gagal menambah: `oAnda telah mencapai batas maksimum " .. MAX_GIVEAWAY_ITEMS .. " item giveaway.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                return true
            end
            
            local selectedID
            for k, v in pairs(data) do
                if type(k) == "string" and k:match("^picker_item_%d+$") and v == "1" then selectedID = tonumber(k:match("^picker_item_(%d+)$")); break end
            end
            local qty = tonumber(data.picker_qty or "") or 1
            if selectedID and qty > 0 then
                table.insert(_G.MarineGiveaway.items, { itemID = selectedID, itemCount = qty })
                saveGiveawayData()
                player:onConsoleMessage("`2Item `w" .. getItemNameByID(selectedID) .. " x" .. qty .. "`` berhasil ditambahkan.")
                player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
                return true
            else
                player:onConsoleMessage("`4Gagal memilih: `oPilih item dan isi Jumlah Giveaway.")
                buildGiveawayItemPicker(player, sess.page)
                return true
            end
        elseif button == "picker_back" then
            player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
            return true
        end
        return false
    end

    if dialogName == "giveaway_confirm_start_manual" then
        local sess = adminGiveawaySession[netID]
        if not sess or not sess.pendingManualStartConfirm then return false end

        if button == "btn_confirm_manual_giveaway" then
            _G.MarineGiveaway.active = true
            _G.MarineGiveaway.creatorUserID = userID
            _G.MarineGiveaway.creatorName = player:getCleanName()
            _G.MarineGiveaway.giveawayStartTime = os.time()
            _G.MarineGiveaway.claimedPlayers = {}
            saveGiveawayData()

            player:onConsoleMessage("`2Giveaway manual baru berhasil dimulai untuk item-item berikut:\n" .. formatItemList(_G.MarineGiveaway.items) .. "``.")
            player:playAudio("bleep_success.wav")

            local itemListString = formatItemList(_G.MarineGiveaway.items)

            for _, p in ipairs(getServerPlayers()) do
                p:onTextOverlay("`2GIVEAWAY BARU DIMULAI! `wKetik /claim")
                p:onConsoleMessage("`2PEMBERITAHUAN GIVEAWAY: `w" .. _G.MarineGiveaway.creatorName .. "`o telah memulai giveaway untuk item-item berikut:\n" .. itemListString .. "``! `oKetik `w/claim `ountuk mengambilnya.")
                p:playAudio("grow_growtopia.wav")
            end

            local fields = {}
            for _, itemData in ipairs(_G.MarineGiveaway.items) do
                table.insert(fields, {name = getItemNameByID(itemData.itemID) .. " (ID: " .. itemData.itemID .. ")", value = tostring(itemData.itemCount), inline = true})
            end

            local payload = {
                embeds = {{
                    title = "Giveaway Manual Dimulai!",
                    description = "`" .. _G.MarineGiveaway.creatorName .. "` telah memulai giveaway manual untuk item-item berikut.\nSemua pemain (online dan offline) dapat mengklaim dengan `/claim`.",
                    color = 5763719,
                    fields = fields,
                    footer = { text = "Giveaway dimulai pada " .. os.date("%Y-%m-%d %H:%M:%S") }
                }}
            }
            
            coroutine.wrap(function()
                local data = json.encode(payload)
                http.post(DISCORD_WEBHOOK_URL, {["Content-Type"] = "application/json"}, data)
            end)()

            adminGiveawaySession[netID].pendingManualStartConfirm = false
            player:onDialogRequest(buildGiveawayAdminMainDialog(player))
            return true
        elseif button == "btn_back_configure_items" then
            adminGiveawaySession[netID].pendingManualStartConfirm = false
            player:onDialogRequest(buildGiveawayConfigureItemsDialog(player))
            return true
        end
        return false
    end

    return false
end)

onPlayerLoginCallback(function(player)
    if _G.MarineGiveaway.active then
        local userID = player:getUserID()
        if not _G.MarineGiveaway.claimedPlayers[userID] then
            player:onTextOverlay("`2GIVEAWAY TERSISA! `wKetik /claim untuk hadiah!")
            player:onConsoleMessage("`2PEMBERITAHUAN: `oAda giveaway aktif yang belum Anda klaim! Ketik `w/claim `ountuk mendapatkan item-item berikut:\n" .. formatItemList(_G.MarineGiveaway.items) .. "``.")
            player:playAudio("grow_growtopia.wav")
        end
    end
end)

onPlayerDisconnectCallback(function(player)
    adminGiveawaySession[player:getNetID()] = nil
end)

loadGiveawayData()

onAutoSaveRequest(function()
    saveGiveawayData()
end)

print("Marine Giveaway System v1.0 - Fully Loaded & Ready! (Manual Only)")