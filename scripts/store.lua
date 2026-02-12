-- Store script
print("(Loaded) Store script for GrowSoft")

-- ==================== KONFIGURASI YANG MUDAH DIUBAH ====================
local CONFIG = {
    -- Nonaktifkan/hidupkan fitur tertentu
    FEATURES = {
        DAILY_OFFERS = true,          -- Menampilkan daily offers
        IOTM_STOCK = true,            -- Menampilkan stok IOTM dan notifikasi habis
        EVENT_SPECIALS = true,        -- Menampilkan item spesial event
        TOP_PLAYER_WORLD = true,      -- Menampilkan top player & world
        INVENTORY_UPGRADE = true,     -- Fitur upgrade inventory
        REDEEM_CODE = true,           -- Tombol redeem code
        GROW4GOOD = true,             -- Fitur donate (Grow4Good)
        WARP_GROWGANOTH = true,       -- Warp ke Growganoth
    },
    
    -- Pengaturan tampilan
    DISPLAY = {
        SHOW_GEM_BALANCE = true,      -- Tampilkan balance gems di banner
        SHOW_RPC_BALANCE = true,      -- Tampilkan balance RPC di banner
        SHOW_ITEM_DESCRIPTION = true, -- Tampilkan deskripsi item
        SHOW_STOCK_INFO = true,       -- Tampilkan informasi stok
    },
    
    -- Pengaturan validasi
    VALIDATIONS = {
        CHECK_INVENTORY_SPACE = true, -- Cek space inventory sebelum beli
        CHECK_EVENT_REQUIREMENT = true, -- Cek event requirement
        CHECK_DAILY_PURCHASE = true,  -- Cek apakah daily offer sudah dibeli
        CHECK_IOTM_STOCK = true,      -- Cek stok IOTM
    },
    
    -- Pengaturan notifikasi
    NOTIFICATIONS = {
        IOTM_SOLD_OUT = true,         -- Notifikasi saat IOTM habis
        PLAY_SOUND_EFFECTS = true,    -- Mainkan sound effect
        SHOW_PURCHASE_MESSAGE = true, -- Tampilkan pesan pembelian
    },
    
    -- Pengaturan harga khusus (override jika perlu)
    PRICES = {
        INVENTORY_UPGRADE_MULTIPLIER = 62.5, -- 1000/16 = 62.5 per slot
    },
    
    -- Warna dan tema
    COLORS = {
        TITLE = "`o",      -- Warna judul item
        PRICE = "`$",      -- Warna harga
        DESCRIPTION = "`5", -- Warna deskripsi
        RECEIVED = "`2",   -- Warna received items
        ERROR = "`4",      -- Warna error
    }
}
-- ==================== AKHIR KONFIGURASI ====================

function startsWith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

function formatNum(num)
    local formattedNum = tostring(num)
    formattedNum = formattedNum:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formattedNum = formattedNum:gsub("^,", "")
    return formattedNum
end

StoreCat = {
    MAIN_MENU = 0,
    LOCKS_MENU = 1,
    ITEMPACK_MENU = 2,
    BIGITEMS_MENU = 3,
    IOTM_MENU = 4,
    TOKEN_MENU = 5
}

ServerEvents = {
    EVENT_VALENTINE = 1,
    EVENT_ECO = 2,
    EVENT_HALLOWEEN = 3,
    EVENT_NIGHT_OF_THE_COMET = 4,
    EVENT_HARVEST = 5,
    EVENT_GROW4GOOD = 6,
    EVENT_EASTER = 7,
    EVENT_ANNIVERSARY = 8
};

DailyEvents = {
    DAILY_EVENT_GEIGER_DAY = 40,
    DAILY_EVENT_DARKMAGE_DAY = 41,
    DAILY_EVENT_SURGERY_DAY = 42,
    DAILY_EVENT_VOUCHER_DAYZ = 43,
    DAILY_EVENT_RAYMAN_DAY = 44,
    DAILY_EVENT_LOCKE_DAY = 45,
    DAILY_EVENT_XP_DAY = 46
};

local storeNavigation = {
    {name = "Features", target = "main_menu", cat = StoreCat.MAIN_MENU, texture = "interface/large/gtps_shop_btn.rttex", texture_y = "0", description = ""},
    {name = "Player Items", target = "locks_menu", cat = StoreCat.LOCKS_MENU, texture = "interface/large/gtps_shop_btn.rttex", texture_y = "1", description = ""},
    {name = "World Building", target = "itempack_menu", cat = StoreCat.ITEMPACK_MENU, texture = "interface/large/gtps_shop_btn.rttex", texture_y = "3", description = ""},
    {name = "Custom Items", target = "bigitems_menu", cat = StoreCat.BIGITEMS_MENU, texture = "interface/large/gtps_shop_btn.rttex", texture_y = "4", description = ""},
    {name = "IOTM", target = "iotm_menu", cat = StoreCat.IOTM_MENU, texture = "interface/large/btn_iotm_store.rttex", texture_y = "4", description = ""},
    {name = "Growtokens", target = "token_menu", cat = StoreCat.TOKEN_MENU, texture = "interface/large/gtps_shop_btn.rttex", texture_y = "2", description = ""}
}

-- Helper function untuk mengecek konfigurasi
function isFeatureEnabled(feature)
    return CONFIG.FEATURES[feature] == true
end

function isValidationEnabled(validation)
    return CONFIG.VALIDATIONS[validation] == true
end

function shouldShow(display)
    return CONFIG.DISPLAY[display] == true
end

function shouldNotify(notification)
    return CONFIG.NOTIFICATIONS[notification] == true
end

function getColor(colorType)
    return CONFIG.COLORS[colorType] or ""
end

function onPurchaseInventoryUpgrade(player)
    if not isFeatureEnabled("INVENTORY_UPGRADE") then
        return
    end
    
    if player:isMaxInventorySpace() then
        return
    end
    
    local priceMultiplier = CONFIG.PRICES.INVENTORY_UPGRADE_MULTIPLIER or 62.5
    local price = math.floor(priceMultiplier * player:getInventorySize())
    
    if player:getGems() < price then
        player:onStorePurchaseResult(
            "You can't afford " .. getColor("TITLE") .. "Upgrade Backpack (10 slots)``!  You're " .. 
            getColor("PRICE") .. formatNum(price - player:getGems()) .. "`` Gems short."
        )
        if shouldNotify("PLAY_SOUND_EFFECTS") then
            player:playAudio("bleep_fail.wav");
        end
        return
    end
    
    local purchaseResult = "You've purchased " .. getColor("TITLE") .. "Upgrade Backpack (10 slots)`` for " .. 
        getColor("PRICE") .. formatNum(price) .. "`` Gems.\n" .. 
        "You have " .. getColor("PRICE") .. formatNum(player:getGems()) .. "`` Gems left."
    
    if player:removeGems(price, 1, 1) then
        player:upgradeInventorySpace(10) -- Size slots
        player:onStorePurchaseResult(
            purchaseResult .. "\n\n" ..
            getColor("RECEIVED") .. "Received: ``Backpack Upgrade"
        )
        
        if shouldNotify("SHOW_PURCHASE_MESSAGE") then
            player:onConsoleMessage(purchaseResult);
        end
        
        if shouldNotify("PLAY_SOUND_EFFECTS") then
            player:playAudio("piano_nice.wav");
        end
        
        onStore(player, StoreCat.LOCKS_MENU)
    end
end

function onPurchaseItem(player, storeItem, isDailyOffer)
    -- Validasi event requirement
    if isValidationEnabled("CHECK_EVENT_REQUIREMENT") then
        local requiredServerEvent = storeItem:getRequiredEvent()
        if requiredServerEvent ~= -1 and requiredServerEvent ~= getCurrentServerEvent() then
            return
        end
    end

    -- Validasi voucher day
    if storeItem:isVoucher() and getCurrentServerDailyEvent() ~= DailyEvents.DAILY_EVENT_VOUCHER_DAYZ then
        return
    end

    -- Validasi special event items
    if storeItem:getItemID() == 10756 then -- Golden egg carton validation
        if getCurrentServerEvent() ~= ServerEvents.EVENT_EASTER then
            return
        end
        local offerActiveTill = getEasterBuyTime(player:getUserID());
        local currentTime = os.time()
        if offerActiveTill - currentTime <= 0 then
            return;
        end
    end

    local itemTitle = storeItem:getTitle()

    -- Validasi stok IOTM
    if isValidationEnabled("CHECK_IOTM_STOCK") and isFeatureEnabled("IOTM_STOCK") then
        if storeItem:getCategory() == "iotm" then
            local IOTMItemObj = getIOTMItem(storeItem:getItemID())
            if IOTMItemObj ~= nil then
                if IOTMItemObj:getAmount() == 0 then
                    return
                end
            end
        end
    end

    -- Validasi daily offer purchase
    if isValidationEnabled("CHECK_DAILY_PURCHASE") then
        if isDailyOffer then
            if isDailyOfferPurchased(player:getUserID(), storeItem:getItemID()) then
                return
            end
        end
    end

    local getItems = storeItem:makePurchaseItems(1)
    
    if #getItems == 0 then
        return
    end

    -- Validasi inventory space
    if isValidationEnabled("CHECK_INVENTORY_SPACE") then
        if not player:canFit(getItems) then
            player:onStorePurchaseResult(
                "You don't have enough space in your inventory for that. You may be carrying too many of one of the items you are trying to purchase or you don't have enough free spaces to fit them all in your backpack!"
            )
            if shouldNotify("PLAY_SOUND_EFFECTS") then
                player:playAudio("bleep_fail.wav");
            end
            return
        end
    end

    local price = storeItem:getPrice()
    local currencyName = "Gems"
    local currencyLeft = 0

    -- Proses pembayaran berdasarkan jenis currency
    if storeItem:isRPC() then
        currencyName = getCurrencyLongName() .. "s"
        if player:getCoins() < price then
            player:onStorePurchaseResult(
                "You can't afford " .. getColor("TITLE") .. itemTitle .. "``!  You're " .. 
                getColor("PRICE") .. formatNum(price - player:getCoins()) .. "`` " .. currencyName .. " short."
            )
            if shouldNotify("PLAY_SOUND_EFFECTS") then
                player:playAudio("bleep_fail.wav");
            end
            return
        end
        if not player:removeCoins(price, 1) then
            return
        end
        currencyLeft = player:getCoins()
    elseif storeItem:isGrowtoken() or storeItem:isVoucher() then
        if storeItem:isGrowtoken() then
            currencyName = "Growtokens"
        else
            currencyName = "Vouchers"
        end
        local neededItem = (storeItem:isGrowtoken()) and 1486 or 10858
        local hasItemAmount = player:getItemAmount(neededItem)
        if hasItemAmount < price then
            player:onStorePurchaseResult(
                "You can't afford " .. getColor("TITLE") .. itemTitle .. "``!  You're " .. 
                getColor("PRICE") .. formatNum(price - hasItemAmount) .. "`` " .. currencyName .. " short."
            )
            if shouldNotify("PLAY_SOUND_EFFECTS") then
                player:playAudio("bleep_fail.wav");
            end
            return
        end
        if not player:changeItem(neededItem, -price, 0) then
            return
        end
        currencyLeft = player:getItemAmount(neededItem)
    else
        if player:getGems() < price then
            player:onStorePurchaseResult(
                "You can't afford " .. getColor("TITLE") .. itemTitle .. "``!  You're " .. 
                getColor("PRICE") .. formatNum(price - player:getGems()) .. "`` " .. currencyName .. " short."
            )
            if shouldNotify("PLAY_SOUND_EFFECTS") then
                player:playAudio("bleep_fail.wav");
            end
            return
        end
        if not player:removeGems(price, 1, 1) then
            return
        end
        currencyLeft = player:getGems()
    end

    -- Proses pemberian item
    local purchasedItems = {}
    local purchasedItemsMessage = {}
    for i = 1, #getItems do
        local itemID = getItems[i][1]
        local itemCount = getItems[i][2]
        player:progressQuests(itemID, itemCount)
        player:changeItem(itemID, itemCount, 0)
        table.insert(purchasedItems, (itemCount == 1) and getItem(itemID):getName() or itemCount .. " " .. getItem(itemID):getName())
        table.insert(purchasedItemsMessage, itemCount .. " " .. getColor("TITLE") .. getItem(itemID):getName() .. "``")
    end

    local purchaseResult = "You've purchased " .. getColor("TITLE") .. itemTitle .. "`` for " .. 
        getColor("PRICE") .. formatNum(price) .. "`` " .. currencyName .. ".\n" .. 
        "You have " .. getColor("PRICE") .. formatNum(currencyLeft) .. "`` " .. currencyName .. " left."

    player:onStorePurchaseResult(
        purchaseResult .. "\n\n" ..
        getColor("RECEIVED") .. "Received: ``" .. table.concat(purchasedItems, ", ")
    )

    if shouldNotify("SHOW_PURCHASE_MESSAGE") then
        player:onConsoleMessage(purchaseResult);
        for i = 1, #purchasedItemsMessage do
            player:onConsoleMessage("Got " .. purchasedItemsMessage[i] .. ".");
        end
    end

    if shouldNotify("PLAY_SOUND_EFFECTS") then
        player:playAudio("piano_nice.wav");
    end

    player:updateGems(0)

    -- Update stok IOTM
    if isFeatureEnabled("IOTM_STOCK") and storeItem:getCategory() == "iotm" then
        local IOTMItemObj = getIOTMItem(storeItem:getItemID())
        if IOTMItemObj ~= nil then
            IOTMItemObj:setAmount(IOTMItemObj:getAmount() - 1)
            if IOTMItemObj:getAmount() == 0 and shouldNotify("IOTM_SOLD_OUT") then
                local players = getServerPlayers()
                for i = 1, #players do
                    local itPlayer = players[i]
                    itPlayer:onConsoleMessage("ĭ " .. getColor("ERROR") .. "All " .. getItem(storeItem:getItemID()):getName() .. " have been sold out from the store!``");
                    if shouldNotify("PLAY_SOUND_EFFECTS") then
                        itPlayer:playAudio("gauntlet_spawn.wav");
                    end
                end
            end
        end
    end

    -- Tandai daily offer sebagai sudah dibeli
    if isDailyOffer then
        addDailyOfferPurchased(player:getUserID(), storeItem:getItemID())
    end

    -- Kembali ke kategori yang sesuai
    local currentCategory = storeItem:getCategory()

    if isDailyOffer then
        currentCategory = "main"
    else
        if currentCategory ~= "iotm" and currentCategory ~= "voucher" then
            if requiredServerEvent == -1 and storeItem:getItemID() > getRealGTItemsCount() then
                currentCategory = "bigitems"
            end
        end
    end

    for i, category in ipairs(storeNavigation) do
        if startsWith(category.target, currentCategory) then
            onStore(player, category.cat)
            return
        end
    end
end

function onPurchaseItemReq(player, storeItemID)
    if storeItemID == 9412 then
        onPurchaseInventoryUpgrade(player)
        return
    end
    local storeItems = getStoreItems()
    for i = 1, #storeItems do
        local storeItem = storeItems[i]
        if storeItem:getItemID() == storeItemID then
            onPurchaseItem(player, storeItem, false)
            return
        end
    end
    
    -- Cek event offers hanya jika fitur aktif
    if isFeatureEnabled("EVENT_SPECIALS") then
        local eventOffers = getEventOffers()
        for i = 1, #eventOffers do
            local storeItem = eventOffers[i]
            if storeItem:getItemID() == storeItemID then
                onPurchaseItem(player, storeItem, true)
                return
            end
        end
    end
    
    -- Cek daily offers hanya jika fitur aktif
    if isFeatureEnabled("DAILY_OFFERS") then
        local activeDailyOffers = getActiveDailyOffers()
        for i = 1, #activeDailyOffers do
            local storeItem = activeDailyOffers[i]
            if storeItem:getItemID() == storeItemID then
                onPurchaseItem(player, storeItem, true)
                return
            end
        end
    end
end

function makeStoreButton(player, storeItem, isDailyOffer)
    local itemTitle = storeItem:getTitle()
    local itemDescription = storeItem:getDescription()
    
    local getItems = {}
    local giveItems = storeItem:getItems()
    for i = 1, #giveItems do
        local itemID = giveItems[i][1]
        local itemCount = giveItems[i][2]
        table.insert(getItems, itemCount .. " " .. getItem(itemID):getName())
    end

    local itemsDescription = table.concat(getItems, ", ") .. "."

    if storeItem:getItemsDescription() ~= "" then
        itemsDescription = storeItem:getItemsDescription()
    end
    
    local isUnlocked = true
    local iotmItemStock = ""
    local extraDescription = ""
    
    -- Tampilkan info stok IOTM hanya jika fitur aktif
    if isFeatureEnabled("IOTM_STOCK") and shouldShow("SHOW_STOCK_INFO") then
        if storeItem:getCategory() == "iotm" then
            local IOTMItemObj = getIOTMItem(storeItem:getItemID())
            if IOTMItemObj ~= nil then
                if IOTMItemObj:getAmount() == 0 then
                    iotmItemStock = getColor("ERROR") .. "Out of Stock``"
                    isUnlocked = false
                    extraDescription = "<CR><CR>" .. getColor("DESCRIPTION") .. "Note:`` This item is sold out, check again later."
                else
                    iotmItemStock = "`wIn stock: " .. formatNum(IOTMItemObj:getAmount()) .. "``"
                    extraDescription = "<CR><CR>" .. getColor("DESCRIPTION") .. "Note:`` There are " .. formatNum(IOTMItemObj:getAmount()) .. " items in stock."
                end
            end
        end
    end

    if isDailyOffer then
        if isDailyOfferPurchased(player:getUserID(), storeItem:getItemID()) then
            iotmItemStock = getColor("RECEIVED") .. "Purchased``"
            isUnlocked = false
            extraDescription = "<CR><CR>" .. getColor("DESCRIPTION") .. "Note:`` You already purchased this offer."
        end
    end
    
    local descriptionText = ""
    if shouldShow("SHOW_ITEM_DESCRIPTION") then
        descriptionText = getColor("RECEIVED") .. "You Get:`` " .. itemsDescription .. 
                         "<CR><CR>" .. getColor("DESCRIPTION") .. "Description:`` " .. 
                         itemDescription .. extraDescription
    else
        descriptionText = itemsDescription
    end

    if storeItem:getItemID() == 10756 then
        local progressStr = ""
        local bigButtonTitleStr = ""
        
        if storeItem:getItemID() == 10756 then
            local offerActiveTill = getEasterBuyTime(player:getUserID());
            local currentTime = os.time()
            if offerActiveTill - currentTime <= 0 then
                local hasEggs = getEasterEggs(player:getUserID());
                isUnlocked = false
                progressStr = hasEggs .. " / 1000 Magic Eggs Used"
            else
                bigButtonTitleStr = formatStoreTime(offerActiveTill, currentTime) .. " left"
            end
        end

        local eventSpecialButtonString = string.format(
            "add_button|%s|%s%s``|%s|%s|%s|%s|%s|0|%s||-1|-1||-1|-1|%s|%s|%s|0|%s|    %s    |%s|%s|%s|CustomParams:|",
            storeItem:getItemID(),
            getColor("TITLE"),
            itemTitle,
            storeItem:getTexture(),
            (storeItem:isRPC()) and "" or descriptionText,
            storeItem:getTexturePosX(),
            storeItem:getTexturePosY(),
            (storeItem:isRPC() or storeItem:isVoucher()) and "" or (storeItem:isGrowtoken()) and -storeItem:getPrice() or storeItem:getPrice(),
            (storeItem:isRPC()) and getCurrencyIcon() .. " " .. formatNum(storeItem:getPrice()) .. " " .. getCurrencyMediumName() or "",
            (storeItem:isRPC()) and descriptionText or "",
            (isUnlocked == true) and "1" or "0",
            storeItem:getTexture(),
            (isUnlocked == false) and tonumber(storeItem:getTexturePosY()) + 1 or storeItem:getTexturePosY(),
            progressStr,
            (bigButtonTitleStr == "") and iotmItemStock or bigButtonTitleStr,
            (storeItem:isRPC()) and "-1" or "0",
            (storeItem:isVoucher()) and storeItem:getPrice() or "0"
        )
        return eventSpecialButtonString
    end

    local buttonString = string.format(
        "add_button|%s|%s%s``|%s|%s|%s|%s|%s|0|%s||-1|-1||-1|-1|%s|%s|||||%s|%s|%s|CustomParams:|",
        storeItem:getItemID(),
        getColor("TITLE"),
        itemTitle,
        storeItem:getTexture(),
        (storeItem:getItemID() == 0) and "OPENDIALOG&warptogrowganoth" or (storeItem:getItemID() == 10794) and "OPENDIALOG&donatemenu" or (storeItem:isRPC()) and "" or descriptionText,
        storeItem:getTexturePosX(),
        storeItem:getTexturePosY(),
        (storeItem:isRPC() or storeItem:isVoucher()) and "" or (storeItem:isGrowtoken()) and -storeItem:getPrice() or storeItem:getPrice(),
        (storeItem:isRPC()) and getCurrencyIcon() .. " " .. formatNum(storeItem:getPrice()) .. " " .. getCurrencyMediumName() or "",
        (storeItem:isRPC()) and descriptionText or "",
        (isUnlocked == true) and "1" or "0",
        iotmItemStock,
        (storeItem:isRPC()) and "-1" or "0",
        (storeItem:isVoucher()) and storeItem:getPrice() or "0"
    )
    return buttonString
end

function onStore(player, cat)
    local currentCategory = ""
    local storeCategories = {}
    for i, category in ipairs(storeNavigation) do
        local isCurrentCategory = (category.cat == cat) and "1" or "0"
        if isCurrentCategory == "1" then
            currentCategory = category.target
        end
        local tabString = string.format(
            "add_tab_button|%s|%s|%s|%s|%s|%s|0|0||||-1|-1|||0|0|CustomParams:|",
            category.target,
            category.name,
            category.texture,
            category.description,
            isCurrentCategory,
            category.texture_y
        )
        table.insert(storeCategories, tabString)
    end

    local storeContent = {}

    if cat == StoreCat.MAIN_MENU then
        -- Banner dengan balance info
        local balanceText = ""
        if shouldShow("SHOW_RPC_BALANCE") then
            balanceText = "You have `9" .. formatNum(player:getCoins()) .. " " .. getCurrencyLongName() .. "s " .. getCurrencyIcon() .. "``. "
        end
        if shouldShow("SHOW_GEM_BALANCE") then
            balanceText = balanceText .. "You have `$" .. formatNum(player:getGems()) .. "`` Gems. "
        end
        balanceText = balanceText .. "You can purchase more by joining our discord via `$/discord`` command!"
        
        table.insert(storeContent, "add_big_banner|interface/large/gui_store_alert.rttex|0|0|" .. balanceText .. "|")

        -- Top Player & World button
        if isFeatureEnabled("TOP_PLAYER_WORLD") then
            local topPlayer = getTopPlayerByBalance()
            local topWorld = getTopWorldByVisitors()
            if topWorld ~= nil and topPlayer ~= nil then
                local worldOwner = topWorld:getOwner()
                local worldInfo = ""
                if worldOwner ~= nil then
                    worldInfo = " (By " .. worldOwner:getName() .. ")"
                end
                table.insert(storeContent, "add_button|top_players_and_worlds|" .. getColor("TITLE") .. "Top Player & World ĕ``|interface/large/gtps/store_buttons/store_new_p.rttex||2|5|0|0|||-1|-1||-1|-1|`#Best Player``: " .. topPlayer:getCleanName() .. " (ā " .. formatNum(topPlayer:getTotalWorldLocks()) .. ")<CR>`#Best World``:  " .. topWorld:getName() .. worldInfo .. "|0|||||World: " .. topWorld:getName() .. " Player: " .. topPlayer:getCleanName() .. "|0|0|CustomParams:|")
            elseif topWorld ~= nil then
                local worldOwner = topWorld:getOwner()
                local worldInfo = ""
                if worldOwner ~= nil then
                    worldInfo = " (By " .. worldOwner:getName() .. ")"
                end
                table.insert(storeContent, "add_button|top_players_and_worlds|" .. getColor("TITLE") .. "Top Player & World ĕ``|interface/large/gtps/store_buttons/store_new_p.rttex||2|5|0|0|||-1|-1||-1|-1|`#Best Player``: None!<CR>`#Best World``:  " .. topWorld:getName() .. worldInfo .. "|0|||||World: " .. topWorld:getName() .. " Player: None!|-1|0|CustomParams:|")
            elseif topPlayer ~= nil then
                table.insert(storeContent, "add_button|top_players_and_worlds|" .. getColor("TITLE") .. "Top Player & World ĕ``|interface/large/gtps/store_buttons/store_new_p.rttex||2|5|0|0|||-1|-1||-1|-1|`#Best Player``: " .. topPlayer:getCleanName() .. " (ā " .. formatNum(topPlayer:getTotalWorldLocks()) .. ")<CR>`#Best World``:  None!|0|||||World: None! Player: " .. topPlayer:getCleanName() .. "|0|0|CustomParams:|")
            end
        end

        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|0|") -- "GTPS Store" banner
    elseif cat == StoreCat.LOCKS_MENU then
        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|7|") -- "Player Items" banner
        if isFeatureEnabled("INVENTORY_UPGRADE") and not player:isMaxInventorySpace() then
            local priceMultiplier = CONFIG.PRICES.INVENTORY_UPGRADE_MULTIPLIER or 62.5
            local inventoryUpgradePrice = math.floor(priceMultiplier * player:getInventorySize())
            table.insert(storeContent, "add_button|9412|" .. getColor("TITLE") .. "Upgrade Backpack`` (`w10 Slots``)|interface/large/store_buttons/store_buttons.rttex|" .. getColor("RECEIVED") .. "You Get:`` 10 Additional Backpack Slots.<CR><CR>" .. getColor("DESCRIPTION") .. "Description:`` Sewing an extra pocket onto your backpack will allow you to store " .. getColor("PRICE") .. "10`` additional item types.  How else are you going to fit all those toilets and doors?|0|1|" .. inventoryUpgradePrice .. "|0|||-1|-1||-1|-1||1||||||0|0|CustomParams:|")
        end
    elseif cat == StoreCat.ITEMPACK_MENU then
        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|8|") -- "Tool Items" banner
    elseif cat == StoreCat.BIGITEMS_MENU then
        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|9|") -- "Custom Items" banner
    elseif cat == StoreCat.IOTM_MENU then
        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|19|") -- "Creative Items" banner
    elseif cat == StoreCat.TOKEN_MENU then
        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|11|") -- "Token Items" banner
    end

    -- Menampilkan item store reguler
    local storeItems = getStoreItems()
    for i = 1, #storeItems do
        local storeItem = storeItems[i]

        if storeItem:getTexture() ~= "_label_" then
            local itemCategory = storeItem:getCategory()
            local requiredServerEvent = storeItem:getRequiredEvent()

            if itemCategory ~= "iotm" and itemCategory ~= "voucher" then
                if requiredServerEvent == -1 and storeItem:getItemID() > getRealGTItemsCount() then
                    itemCategory = "bigitems"
                end
            end
            
            if itemCategory == "voucher" and getCurrentServerDailyEvent() == DailyEvents.DAILY_EVENT_VOUCHER_DAYZ then
                itemCategory = "main"
            end

            if startsWith(currentCategory, itemCategory) then
                if requiredServerEvent == -1 or requiredServerEvent == getCurrentServerEvent() then
                    table.insert(storeContent, makeStoreButton(player, storeItem, false))
                end
            end
        end
    end

    -- Menampilkan event offers dan daily offers hanya jika fitur aktif
    if cat == StoreCat.MAIN_MENU then
        -- Event offers
        if isFeatureEnabled("EVENT_SPECIALS") then
            local eventOffers = getEventOffers()
            local bannerInserted = false
            for i = 1, #eventOffers do
                local eventOffer = eventOffers[i]
                if eventOffer:getRequiredEvent() == getCurrentServerEvent() then
                    if not bannerInserted then
                        table.insert(storeContent, "add_banner|interface/large/gtps_store_overlays.rttex|0|19|") -- Limited Items
                        bannerInserted = true
                    end
                    table.insert(storeContent, makeStoreButton(player, eventOffer, true))
                end
            end
        end
        
        -- Daily offers
        if isFeatureEnabled("DAILY_OFFERS") then
            table.insert(storeContent, "add_banner|interface/large/gui_shop_featured_header.rttex|0|2|") -- Get More Gems
            local activeDailyOffers = getActiveDailyOffers()
            for i = 1, #activeDailyOffers do
                local activeDailyOffer = activeDailyOffers[i]
                table.insert(storeContent, makeStoreButton(player, activeDailyOffer, true))
            end
        end
        
        -- Redeem code button
        if isFeatureEnabled("REDEEM_CODE") then
            table.insert(storeContent, "add_button|redeem_code|Redeem Code|interface/large/store_buttons/store_buttons40.rttex|OPENDIALOG&showredeemcodewindow|1|5|0|0|||-1|-1||-1|-1||1||||||0|0|CustomParams:|")
        end
    end

    player:onStoreRequest(
        "set_description_text|Welcome to the " .. getColor("RECEIVED") .. "Growtopia Store``! Select the item you'd like more info on." .. getColor("TITLE") .. " ` " .. getColor("DESCRIPTION") .. "Want to get `5Supporter`` status? Any Gem purchase (or `526000`` Gems earned with free `5Tapjoy`` offers) will make you one. You'll get new skin colors, the `5Recycle`` tool to convert unwanted items into Gems, and more bonuses!\n" ..
        "enable_tabs|1\n" ..
        table.concat(storeCategories, "\n") .. "\n" ..
        table.concat(storeContent, "\n")
    )
end

onPlayerActionCallback(function(world, player, data)
    local actionName = data["action"] or ""
    if actionName == "donatemenu" then
        if isFeatureEnabled("GROW4GOOD") then
            player:onGrow4GoodDonate()
            return true
        end
        return false
    end
    if actionName == "warptogrowganoth" then
        if isFeatureEnabled("WARP_GROWGANOTH") then
            if player:getWorldName() == "GROWGANOTH" then
                player:onTextOverlay("You're already here!")
                return true
            end
            player:enterWorld("GROWGANOTH", "Entering Growganoth...")
            return true
        end
        return false
    end
    if actionName == "showredeemcodewindow" then
        if isFeatureEnabled("REDEEM_CODE") then
            player:onRedeemMenu()
            return true
        end
        return false
    end
    if actionName == "storenavigate" then
        if data["item"] ~= nil then
            if data["selection"] ~= nil then
                if startsWith(data["selection"], "s_") then
                    return false
                end
            end
            for i, category in ipairs(storeNavigation) do
                if startsWith(category.target, data["item"]) then
                    onStore(player, category.cat)
                    return true
                end
            end
            return true
        end
        return true
    end
    if actionName == "buy" then
        if data["item"] ~= nil then
            for i, category in ipairs(storeNavigation) do
                if startsWith(category.target, data["item"]) then
                    onStore(player, category.cat)
                    return true
                end
            end
            local itemID = tonumber(data["item"])
            onPurchaseItemReq(player, itemID)
            return true
        end
        return true
    end
    if actionName == "killstore" then
        return true
    end
    return false
end)

onStoreRequest(function(world, player)
    onStore(player, StoreCat.MAIN_MENU)
    return true
end)