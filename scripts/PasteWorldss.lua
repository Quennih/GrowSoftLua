-- World Copy System for GrowSoft Server
local copiedWorlds = {}
local playerWorlds = {} -- Untuk melacak world setiap player

-- Register commands
registerLuaCommand({ command = "copy", roleRequired = 5, description = "Salin world saat ini" })
registerLuaCommand({ command = "paste", roleRequired = 5, description = "Tempel world yang telah disalin" })
registerLuaCommand({ command = "copied", roleRequired = 5, description = "Lihat daftar world yang tersimpan" })
registerLuaCommand({ command = "clearcopy", roleRequired = 5, description = "Hapus semua world yang tersimpan" })

-- Daftar block khusus yang perlu penanganan khusus
local SPECIAL_BLOCKS = {
    SIGN = 3856,           -- Sign block
    EMERALD_LOCK = 2408,
    CONSOLE_SIGN = 25258,
    PATH_MAKER = 4482,
    DOOR = 858,            -- Door block
    WORLD_LOCK = 242,      -- World Lock
    DARK_LOCK = 1796,      -- Diamond Lock
    GOLD_LOCK = 7188,      -- Golden Lock
    BLUE_LOCK = 20628,     -- Blue Lock
    MAKER = 3386,          -- Path Maker
    PORTAL = 4640,         -- Portal
    GATE = 3868,           -- Gate
    MAILBOX = 3600,        -- Mailbox
    BUNNY_GATE = 4948,     -- Bunny Gate
    HEART_GATE = 4946,     -- Heart Gate
    CRYSTAL_GATE = 4944    -- Crystal Gate
}

-- Simpan world ketika player masuk
onPlayerEnterWorldCallback(function(world, player)
    if world and world.getName then
        local userID = player:getUserID()
        playerWorlds[userID] = world
    end
end)

-- Fungsi untuk mendapatkan world player yang valid
local function getValidWorld(player)
    -- Coba dari cache
    local userID = player:getUserID()
    if playerWorlds[userID] then
        return playerWorlds[userID]
    end
    
    -- Fallback: coba player:getWorld()
    local world = player:getWorld()
    if world and world.getName then
        return world
    end
    
    return nil
end

-- Fungsi sederhana untuk format waktu tanpa os.date
local function getSimpleTime()
    return "today"
end

-- Fungsi untuk mendapatkan daftar world yang tersimpan
local function getWorldList()
    local list = {}
    for name, _ in pairs(copiedWorlds) do
        table.insert(list, name)
    end
    if #list == 0 then
        return "Tidak ada"
    end
    return table.concat(list, ", ")
end

-- Fungsi untuk spawn item berdasarkan itemID
local function spawnDroppedItem(world, x, y, itemID, count, player)
    -- Method 1: Coba spawnItem seperti di script gacha
    if world.spawnItem and type(world.spawnItem) == "function" then
        world:spawnItem(x, y, itemID, count, player)
        return true
    end
    
    -- Method 2: Fallback ke spawnGems untuk gems
    if itemID == 112 and world.spawnGems then
        world:spawnGems(x, y, count, player)
        return true
    end
    
    return false
end

-- Fungsi untuk mendapatkan nama item
local function getItemName(itemID)
    local item = getItem(itemID)
    if item and item.getName then 
        return item:getName() 
    end
    return "Item#" .. tostring(itemID)
end

-- Fungsi untuk mengecek apakah block adalah block khusus
local function isSpecialBlock(blockID)
    for _, specialID in pairs(SPECIAL_BLOCKS) do
        if blockID == specialID then
            return true
        end
    end
    return false
end

-- Fungsi untuk mendapatkan nama block khusus
local function getSpecialBlockName(blockID)
    for name, id in pairs(SPECIAL_BLOCKS) do
        if blockID == id then
            return name
        end
    end
    return "UNKNOWN"
end

-- Fungsi untuk konversi nilai ke number (0 atau 1) - SEDERHANA
local function toTileDataValue(value)
    if value == nil then
        return 0
    elseif type(value) == "boolean" then
        return value and 1 or 0
    elseif type(value) == "number" then
        return value
    else
        return 0
    end
end

-- Fungsi untuk menyalin world dengan semua data termasuk block khusus
local function copyWorld(player)
    local world = getValidWorld(player)
    
    if not world then
        player:onConsoleMessage("`4Error: Tidak dapat mengakses world!")
        return
    end

    local worldName = world:getName()
    if not worldName then
        player:onConsoleMessage("`4Error: Tidak bisa mendapatkan nama world!")
        return
    end

    player:onConsoleMessage("`2Memulai copy world: `6" .. worldName)

    -- Coba akses sizeX dengan error handling
    local sizeX, sizeY
    if world.getSizeX then
        sizeX = world:getSizeX()
        sizeY = world:getSizeY()
    else
        -- Default size untuk GrowTopia
        sizeX = 100
        sizeY = 60
        player:onConsoleMessage("`6Note: Menggunakan ukuran default 100x60")
    end

    -- Simpan data world
    copiedWorlds[worldName] = {
        originalName = worldName,
        sizeX = sizeX,
        sizeY = sizeY,
        tiles = {},
        droppedItems = {},
        specialBlocks = {},  -- Untuk block khusus
        timestamp = os.time()
    }

    local worldData = copiedWorlds[worldName]

    -- Salin semua tiles dengan data lengkap
    local tileCount = 0
    local specialBlockCount = 0
    
    if world.getTile then
        for x = 0, sizeX - 1 do
            for y = 0, sizeY - 1 do
                local tile = world:getTile(x, y)
                if tile then
                    local foreground = tile:getTileForeground()
                    local background = tile:getTileBackground()
                    
                    -- Simpan semua data tile
                    local tileData = {
                        x = x,
                        y = y,
                        foreground = foreground,
                        background = background,
                        data = {}
                    }
                    
                    -- Simpan hanya data tile yang penting (0-20) untuk menghindari error
                    for propIndex = 0, 20 do
                        local value = tile:getTileData(propIndex)
                        if value ~= nil then
                            tileData.data[propIndex] = toTileDataValue(value)
                        end
                    end
                    
                    table.insert(worldData.tiles, tileData)
                    tileCount = tileCount + 1
                    
                    -- Tangani block khusus
                    if isSpecialBlock(foreground) then
                        local specialData = {
                            x = x,
                            y = y,
                            blockID = foreground,
                            blockName = getSpecialBlockName(foreground),
                            data = {}
                        }
                        
                        -- Simpan data khusus untuk block tertentu
                        for propIndex = 0, 20 do
                            local value = tile:getTileData(propIndex)
                            if value ~= nil then
                                specialData.data[propIndex] = toTileDataValue(value)
                            end
                        end
                        
                        table.insert(worldData.specialBlocks, specialData)
                        specialBlockCount = specialBlockCount + 1
                        
                        player:onConsoleMessage("`2Block khusus: `6" .. specialData.blockName .. "`2 di " .. x .. "," .. y)
                    end
                end
            end
        end
        player:onConsoleMessage("`2Tiles berhasil disalin: `6" .. tileCount)
        player:onConsoleMessage("`2Block khusus ditemukan: `6" .. specialBlockCount)
    else
        player:onConsoleMessage("`4Error: Tidak dapat mengakses tiles world!")
        return
    end

    -- Salin dropped items dengan detail
    local droppedItemCount = 0
    if world.getDroppedItems then
        local droppedItems = world:getDroppedItems()
        if droppedItems then
            for _, drop in ipairs(droppedItems) do
                if drop.getItemID then
                    local itemID = drop:getItemID()
                    local itemCount = drop:getItemCount()
                    local itemName = getItemName(itemID)
                    
                    local dropData = {
                        x = math.floor(drop:getPosX()),
                        y = math.floor(drop:getPosY()),
                        itemID = itemID,
                        count = itemCount,
                        name = itemName
                    }
                    table.insert(worldData.droppedItems, dropData)
                    droppedItemCount = droppedItemCount + 1
                end
            end
        end
        player:onConsoleMessage("`2Floating items berhasil disalin: `6" .. droppedItemCount)
    end

    player:onConsoleMessage("`2✅ World berhasil disalin: `6" .. worldName)
    player:onConsoleMessage("`2Ukuran: `6" .. worldData.sizeX .. "x" .. worldData.sizeY)
    player:onConsoleMessage("`2Total tiles: `6" .. tileCount)
    player:onConsoleMessage("`2Total block khusus: `6" .. specialBlockCount)
    player:onConsoleMessage("`2Total floating items: `6" .. droppedItemCount)
    
    -- Tampilkan semua world yang tersimpan untuk debug
    player:onConsoleMessage("`2World tersimpan: `6" .. getWorldList())
end

-- Fungsi untuk mencari world (case insensitive)
local function findWorld(worldName)
    for name, data in pairs(copiedWorlds) do
        if name:lower() == worldName:lower() then
            return name, data
        end
    end
    return nil, nil
end

-- Fungsi untuk menempel world dengan semua data termasuk block khusus
local function pasteWorld(player, targetWorldName)
    -- Cari world (case insensitive)
    local actualName, worldData = findWorld(targetWorldName)
    if not worldData then
        player:onConsoleMessage("`4Error: World `6" .. targetWorldName .. "`4 tidak ditemukan!")
        player:onConsoleMessage("`2World yang tersimpan: `6" .. getWorldList())
        return
    end

    local world = getValidWorld(player)
    if not world then
        player:onConsoleMessage("`4Error: Tidak dapat mengakses world!")
        return
    end

    local currentWorldName = world:getName()
    player:onConsoleMessage("`2Memulai paste `6" .. actualName .. "`2 ke `6" .. currentWorldName)
    player:onConsoleMessage("`2Mohon tunggu, proses mungkin memakan waktu...")

    -- Clear world terlebih dahulu
    player:onConsoleMessage("`2Membersihkan world...")
    for x = 0, worldData.sizeX - 1 do
        for y = 0, worldData.sizeY - 1 do
            local tile = world:getTile(x, y)
            if tile then
                world:setTileForeground(tile, 0)
                world:setTileBackground(tile, 0)
                world:updateTile(tile)
            end
        end
    end

    -- Hapus semua dropped items yang ada
    if world.getDroppedItems then
        local droppedItems = world:getDroppedItems()
        if droppedItems then
            for _, drop in ipairs(droppedItems) do
                if drop.getUID then
                    world:removeDroppedItem(drop:getUID())
                end
            end
        end
    end

    -- Paste semua tiles dengan data lengkap - SEDERHANA
    player:onConsoleMessage("`2Memasang tiles...")
    local tilesPasted = 0
    for _, tileData in ipairs(worldData.tiles) do
        local tile = world:getTile(tileData.x, tileData.y)
        if tile then
            -- Set foreground dan background
            world:setTileForeground(tile, tileData.foreground)
            world:setTileBackground(tile, tileData.background)
            
            -- Set data tile yang penting saja
            for propIndex, value in pairs(tileData.data) do
                local numValue = toTileDataValue(value)
                tile:setTileData(propIndex, numValue)
            end
            
            world:updateTile(tile)
            tilesPasted = tilesPasted + 1
            
            -- Progress report
            if tilesPasted % 500 == 0 then
                player:onConsoleMessage("`2Progress tiles: `6" .. tilesPasted .. "/" .. #worldData.tiles)
            end
        end
    end

    -- Paste block khusus dengan perhatian ekstra - SEDERHANA
    player:onConsoleMessage("`2Memproses block khusus...")
    local specialBlocksPasted = 0
    for _, specialData in ipairs(worldData.specialBlocks) do
        local tile = world:getTile(specialData.x, specialData.y)
        if tile then
            -- Pastikan block khusus terpasang dengan benar
            world:setTileForeground(tile, specialData.blockID)
            
            -- Set semua data khusus
            for propIndex, value in pairs(specialData.data) do
                local numValue = toTileDataValue(value)
                tile:setTileData(propIndex, numValue)
            end
            
            world:updateTile(tile)
            specialBlocksPasted = specialBlocksPasted + 1
            
            player:onConsoleMessage("`2Block khusus: `6" .. specialData.blockName .. "`2 di " .. specialData.x .. "," .. specialData.y)
        end
    end
    player:onConsoleMessage("`2✅ Block khusus dipasang: `6" .. specialBlocksPasted .. "/" .. #worldData.specialBlocks)

    -- Paste dropped items menggunakan sistem seperti gacha
    local totalItems = #worldData.droppedItems
    if totalItems > 0 then
        player:onConsoleMessage("`2Memasang floating items: `6" .. totalItems)
        
        local itemsSpawned = 0
        for _, dropData in ipairs(worldData.droppedItems) do
            local success = spawnDroppedItem(world, dropData.x, dropData.y, dropData.itemID, dropData.count, player)
            
            if success then
                itemsSpawned = itemsSpawned + 1
            end
            
            -- Progress report
            if itemsSpawned % 10 == 0 then
                player:onConsoleMessage("`2Progress items: `6" .. itemsSpawned .. "/" .. totalItems)
            end
        end
        
        player:onConsoleMessage("`2✅ Floating items dipasang: `6" .. itemsSpawned .. "/" .. totalItems)
    end

    player:onConsoleMessage("`2✅ World `6" .. actualName .. "`2 berhasil dipaste ke `6" .. currentWorldName)
    player:onConsoleMessage("`2🎉 World telah berubah 1:1 sama persis!")
    player:onConsoleMessage("`2📊 Statistik: `6" .. tilesPasted .. "`2 tiles, `6" .. specialBlocksPasted .. "`2 block khusus, `6" .. totalItems .. "`2 items")
end

-- Fungsi untuk menampilkan dialog
local function showCopiedWorlds(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wDaftar World Tersimpan|left|7188|\n"
    dialog = dialog .. "add_spacer|small|\n"

    local hasWorlds = false
    for worldName, worldData in pairs(copiedWorlds) do
        hasWorlds = true
        
        dialog = dialog .. "add_button|paste_" .. worldName .. "|`2Paste `6" .. worldName .. "|noflags|0|0\n"
        dialog = dialog .. "add_textbox|`7" .. worldData.sizeX .. "x" .. worldData.sizeY .. " | Tiles: " .. #worldData.tiles .. " | Special: " .. #worldData.specialBlocks .. " | Items: " .. #worldData.droppedItems .. "|\n"
        dialog = dialog .. "add_smalltext|`oDisalin " .. getSimpleTime() .. "`o|\n"
        dialog = dialog .. "add_spacer|small|\n"
    end

    if not hasWorlds then
        dialog = dialog .. "add_textbox|`4Tidak ada world tersimpan|left|\n"
        dialog = dialog .. "add_smalltext|`oGunakan `/copy` di dalam world`o|\n"
    end

    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|copied_worlds|Tutup|OK|"
    player:onDialogRequest(dialog)
end

-- Command callback
onPlayerCommandCallback(function(world, player, fullCommand)
    local name, rest = fullCommand:match("^(%S+)%s*(.*)$")
    if not name then return false end

    if name == "copy" then
        copyWorld(player)
        return true

    elseif name == "paste" then
        if rest == "" then
            player:onConsoleMessage("`4Usage: /paste <world_name>")
            player:onConsoleMessage("`4Contoh: /paste FARM")
            return true
        end
        pasteWorld(player, rest)
        return true

    elseif name == "copied" then
        showCopiedWorlds(player)
        return true

    elseif name == "clearcopy" then
        copiedWorlds = {}
        player:onConsoleMessage("`2Semua world tersimpan dihapus!")
        return true
    end

    return false
end)

-- Dialog callback
onPlayerDialogCallback(function(world, player, data)
    if data.dialog_name == "copied_worlds" then
        local button = data.buttonClicked
        if button and button:match("^paste_(.+)$") then
            local worldName = button:match("^paste_(.+)$")
            pasteWorld(player, worldName)
            return true
        end
    end
    return false
end)

-- Event handlers
onPlayerFirstTimeLoginCallback(function(player)
    player:onConsoleMessage("`2World Copy System Loaded!")
end)

onPlayerLoginCallback(function(player)
    player:onConsoleMessage("`2World Copy Ready! `/copy`, `/paste <name>`, `/copied`")
end)

print("World Copy System for GrowSoft initialized!")