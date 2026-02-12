print("(Loaded) Item Scanner Script v3.1")

local CONFIG = {
    command = "scanitem",
    adminRole = 51,
    saveKey = "scanitem_registered"
}

local registeredItem = nil
local sessionState = {}
local allItems = {}

local function loadRegisteredItem()
    local data = loadDataFromServer(CONFIG.saveKey)
    if data and type(data) == "table" and data.itemID then
        registeredItem = data.itemID
    end
end

local function saveRegisteredItem()
    local data = {
        itemID = registeredItem
    }
    saveDataToServer(CONFIG.saveKey, data)
end

local function initializeItemDatabase()
    print("[SCANITEM] Initializing item database...")
    for id = 0, getItemsCount() - 1 do
        local item = getItem(id)
        if item then
            local name = item:getName()
            if name and name ~= "" and name ~= "ERROR!" and not name:lower():find("^null_item") then
                table.insert(allItems, { id = id, name = name, lowerName = name:lower() })
            end
        end
    end
    print("[SCANITEM] Database initialized with " .. #allItems .. " items.")
end

local function showMainPanel(player)
    local dialog = {}
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wItem Scanner``|left|32|\n")
    table.insert(dialog, "add_smalltext|`oKelola item yang akan dilacak di server.``|\n")
    table.insert(dialog, "add_spacer|small|\n")
    
    if registeredItem then
        local item = getItem(registeredItem)
        local itemName = item and item:getName() or ("ID " .. registeredItem)
        table.insert(dialog, "add_label|medium|`9Item Terdaftar``|\n")
        table.insert(dialog, "add_smalltext|`o(Klik item untuk menghapus)``|\n")
        table.insert(dialog, string.format("add_button_with_icon|remove_registered|%s|staticBlueFrame|%d|\n", itemName, registeredItem))
        table.insert(dialog, "add_spacer|small|\n")
        
        local totalInEconomy = getEcoQuantity(registeredItem)
        local totalInPlayers = getEcoQuantityPlayers(registeredItem)
        local totalInWorlds = getEcoQuantityWorlds(registeredItem)
        
        table.insert(dialog, "add_custom_break|\n")
        table.insert(dialog, "add_label|small|`9Statistik Ekonomi``|\n")
        table.insert(dialog, string.format("add_textbox|`oTotal di Server: `2%d``|left|\n", totalInEconomy))
        table.insert(dialog, string.format("add_textbox|`oTotal di Pemain (`2Online `o+ `4Offline`o): `^%d``|left|\n", totalInPlayers))
        table.insert(dialog, string.format("add_textbox|`oTotal di World: `5%d``|left|\n", totalInWorlds))
        table.insert(dialog, "add_spacer|small|\n")
        
        table.insert(dialog, "add_button|scan_online|`^Scan Pemain Online``|noflags|\n")
        table.insert(dialog, "add_spacer|small|\n")
        table.insert(dialog, "add_button|change_item|`9Ganti Item``|noflags|\n")
    else
        table.insert(dialog, "add_textbox|`4Belum ada item yang terdaftar.``|left|\n")
        table.insert(dialog, "add_spacer|small|\n")
        table.insert(dialog, "add_button|browse_item|`2Pilih Item``|noflags|\n")
    end
    
    table.insert(dialog, "add_quick_exit|\n")
    table.insert(dialog, "end_dialog|scanitem_main|||\n")
    
    player:onDialogRequest(table.concat(dialog))
end

local function buildItemBrowser(player, page)
    local state = sessionState[player:getNetID()]
    state.page = page or 1
    local itemList = state.isSearching and state.searchResults or allItems
    local maxPage = math.ceil(#itemList / 35)
    if state.page > maxPage and maxPage > 0 then state.page = maxPage end
    if state.page < 1 then state.page = 1 end
    local startIndex = (state.page - 1) * 35 + 1

    local dialog = {}
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wPilih Item``|left|6016|\n")
    table.insert(dialog, "add_smalltext|`oPilih item yang akan didaftarkan untuk scan.``|\n")
    table.insert(dialog, "add_text_input|scan_search_query|Cari Item:||30|\n")
    table.insert(dialog, "add_button|scan_search|Cari|noflags|\n")
    if state.isSearching then table.insert(dialog, "add_button|scan_clear_search|Clear|noflags|\n") end
    table.insert(dialog, "add_spacer|small|\n")
    if state.page > 1 then table.insert(dialog, "add_button|scan_prev_page|`w<< Prev|noflags|\n") end
    if state.page < maxPage then table.insert(dialog, "add_button|scan_next_page|`wNext >>|noflags|\n") end
    table.insert(dialog, "add_label|small|`wPage " .. state.page .. " / " .. maxPage .. "``|right|\n")
    
    for i = startIndex, math.min(startIndex + 34, #itemList) do
        local item = itemList[i]
        table.insert(dialog, string.format("add_checkicon|scan_picker_item_%d|%s|noflags|%d||0|\n", item.id, item.name, item.id))
    end
    table.insert(dialog, "add_spacer|small|\nadd_custom_break|\n")
    table.insert(dialog, "add_button|scan_confirm_select|`2Daftarkan Item``|noflags|\n")
    table.insert(dialog, "add_button|scan_cancel_select|Batal|noflags|\n")
    table.insert(dialog, "end_dialog|scanitem_browser|||\n")

    player:onDialogRequest(table.concat(dialog))
end

local function showScanResultPanel(player, scanType, results)
    local item = getItem(registeredItem)
    local itemName = item and item:getName() or ("ID " .. registeredItem)
    
    local modeText = "`^Pemain Online``"
    
    local dialog = {}
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, string.format("add_label_with_icon|big|`wHasil Scan Item``|left|%d|\n", registeredItem))
    table.insert(dialog, string.format("add_textbox|`wItem: `2%s `w(ID: %d)``|left|\n", itemName, registeredItem))
    table.insert(dialog, string.format("add_textbox|`wMode: %s|left|\n", modeText))
    table.insert(dialog, "add_spacer|small|\n")
    
    if results.playersFoundCount == 0 then
        table.insert(dialog, "add_textbox|`4Tidak ada item yang ditemukan.``|left|\n")
    else
        table.insert(dialog, "add_label|medium|`9Pemain Ditemukan``|\n")
        local sortedPlayers = {}
        for name, amount in pairs(results.foundPlayers) do
            table.insert(sortedPlayers, {name = name, amount = amount})
        end
        table.sort(sortedPlayers, function(a, b) return a.amount > b.amount end)
        
        local displayCount = 0
        for _, data in ipairs(sortedPlayers) do
            if displayCount < 50 then
                table.insert(dialog, string.format("add_textbox|`w- `5%s`w: `2%d buah``|left|\n", data.name, data.amount))
                displayCount = displayCount + 1
            end
        end
        
        if results.playersFoundCount > 50 then
            table.insert(dialog, string.format("add_textbox|`o... dan %d pemain lainnya``|left|\n", results.playersFoundCount - 50))
        end
        
        table.insert(dialog, "add_spacer|small|\n")
        table.insert(dialog, string.format("add_textbox|`oTotal: `2%d item `opada `2%d pemain.``|left|\n", results.totalItemCount, results.playersFoundCount))
    end
    
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|back|`wKembali``|noflags|\n")
    table.insert(dialog, "end_dialog|scanitem_result|||\n")
    
    player:onDialogRequest(table.concat(dialog))
    player:playAudio("audio/success.wav", 0)
end

local function performScan(player)
    player:onConsoleMessage("`2Memulai scan... Harap tunggu.")
    player:playAudio("audio/click.wav", 0)
    
    timer.setTimeout(0.5, function()
        local results = {
            foundPlayers = {},
            totalItemCount = 0,
            playersFoundCount = 0
        }
        
        for _, p in ipairs(getServerPlayers()) do
            if p then
                local amount = p:getItemAmount(registeredItem)
                if amount > 0 then
                    local name = p:getCleanName()
                    results.foundPlayers[name] = (results.foundPlayers[name] or 0) + amount
                    results.totalItemCount = results.totalItemCount + amount
                end
            end
        end
        
        for _ in pairs(results.foundPlayers) do
            results.playersFoundCount = results.playersFoundCount + 1
        end
        
        showScanResultPanel(player, "online", results)
        player:onConsoleMessage("`2Scan selesai! Ditemukan `w" .. results.playersFoundCount .. " `2pemain dengan item tersebut.")
    end)
end

local scanItemCommand = {
    command = CONFIG.command,
    roleRequired = CONFIG.adminRole,
    description = "Membuka panel untuk melacak item di server."
}
registerLuaCommand(scanItemCommand)

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if cmd == CONFIG.command then
        if not player:hasRole(CONFIG.adminRole) then
            player:onConsoleMessage("`4Anda tidak memiliki izin.")
            player:playAudio("audio/bleep_fail.wav", 0)
            return true
        end
        showMainPanel(player)
        player:playAudio("audio/dialog_open.wav", 0)
        return true
    end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local netID = player:getNetID()
    local state = sessionState[netID]
    local dialogName = data.dialog_name
    local button = data.buttonClicked
    
    if dialogName == "scanitem_main" then
        if button == "browse_item" or button == "change_item" then
            sessionState[netID] = { page = 1, isSearching = false, searchResults = {} }
            buildItemBrowser(player, 1)
            player:playAudio("audio/dialog_open.wav", 0)
            return true
        end
        
        if button == "remove_item" or button == "remove_registered" then
            registeredItem = nil
            saveRegisteredItem()
            player:onConsoleMessage("`2Item terdaftar telah dihapus.")
            player:playAudio("audio/trash.wav", 0)
            showMainPanel(player)
            return true
        end
        
        if button == "scan_online" then
            performScan(player)
            return true
        end
        
        return true
    end
    
    if dialogName == "scanitem_browser" then
        if button == "scan_cancel_select" then
            showMainPanel(player)
            player:playAudio("audio/dialog_close.wav", 0)
            return true
        end
        
        if button == "scan_prev_page" then
            buildItemBrowser(player, state.page - 1)
            return true
        end
        
        if button == "scan_next_page" then
            buildItemBrowser(player, state.page + 1)
            return true
        end
        
        if button == "scan_search" then
            state.isSearching = true
            state.searchResults = {}
            local query = (data.scan_search_query or ""):lower()
            for _, item in ipairs(allItems) do
                if item.lowerName:find(query, 1, true) then
                    table.insert(state.searchResults, item)
                end
            end
            buildItemBrowser(player, 1)
            return true
        end
        
        if button == "scan_clear_search" then
            state.isSearching = false
            state.searchResults = {}
            buildItemBrowser(player, 1)
            return true
        end
        
        if button == "scan_confirm_select" then
            local selectedID
            for key, val in pairs(data) do
                if key:match("scan_picker_item_") and val == "1" then
                    selectedID = tonumber(key:match("scan_picker_item_(%d+)"))
                    break
                end
            end
            
            if not selectedID then
                player:onConsoleMessage("`4Error: Anda harus memilih item terlebih dahulu!")
                player:playAudio("audio/bleep_fail.wav", 0)
                return true
            end
            
            registeredItem = selectedID
            saveRegisteredItem()
            local item = getItem(selectedID)
            local itemName = item and item:getName() or ("ID " .. selectedID)
            player:onConsoleMessage("`2Item berhasil didaftarkan: `w" .. itemName)
            player:playAudio("audio/success.wav", 0)
            showMainPanel(player)
            return true
        end
        
        return true
    end
    
    if dialogName == "scanitem_result" then
        if button == "back" then
            showMainPanel(player)
            player:playAudio("audio/dialog_open.wav", 0)
        end
        return true
    end
    
    return false
end)

onPlayerDisconnectCallback(function(player)
    local netID = player:getNetID()
    if sessionState[netID] then
        sessionState[netID] = nil
    end
end)

onPlayerLoginCallback(function(player)
    if registeredItem == nil then
        loadRegisteredItem()
    end
end)

loadRegisteredItem()
initializeItemDatabase()