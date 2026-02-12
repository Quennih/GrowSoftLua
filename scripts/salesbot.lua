print("(Loaded) Sales Bot Admin Panel System")

local CURRENCY = {
    wl = 242,
    dl = 1796,
    bgl = 7188,
    bbl = 20628,
    gtoken = 1486,
    mega_gtoken = 6802,
    pwl = 20234
}

local SERVER_NAME = "GrowSoft Server"  -- Ganti dengan nama server Anda

local SHOP_CONFIG = {
    NPC_ID = 25010,
    
    CATEGORIES = {
        custom1 = {
            name = "Custom Shop 1",
            description = "Shop menggunakan Lock currency",
            currency = "lock",
            icon = CURRENCY.wl
        },
        custom2 = {
            name = "Custom Shop 2", 
            description = "Shop menggunakan Premium World Lock",
            currency = "pwl",
            icon = CURRENCY.pwl
        },
        custom3 = {
            name = "Custom Shop 3",
            description = "Shop menggunakan Growtoken",
            currency = "gtoken",
            icon = CURRENCY.gtoken
        }
    },
    
    DEFAULT_ITEMS = {
        custom1 = {
            { id = 2, name = "Dirt", price = 1, currency = "wl" }
        },
        custom2 = {
            { id = 2, name = "Dirt", price = 1, currency = "pwl" }
        },
        custom3 = {
            { id = 2, name = "Dirt", price = 1, currency = "gtoken" }
        }
    }
}

local SHOP_ITEMS = {}

for category, items in pairs(SHOP_CONFIG.DEFAULT_ITEMS) do
    SHOP_ITEMS[category] = {}
    for _, item in ipairs(items) do
        table.insert(SHOP_ITEMS[category], {
            id = item.id,
            name = item.name,
            price = item.price,
            currency = item.currency
        })
    end
end

local function getItemName(itemID)
    local item = getItem(itemID)
    return item and item:getName() or "Item " .. itemID
end

local function formatNumber(num)
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function getPlayerCurrencyAmount(player, currencyType)
    if currencyType == "lock" then
        local wl = player:getItemAmount(CURRENCY.wl)
        local dl = player:getItemAmount(CURRENCY.dl)
        local bgl = player:getItemAmount(CURRENCY.bgl)
        local bbl = player:getItemAmount(CURRENCY.bbl)
        
        local totalWL = wl + (dl * 100) + (bgl * 10000) + (bbl * 1000000)
        
        return {
            wl = wl,
            dl = dl,
            bgl = bgl,
            bbl = bbl,
            total = totalWL,
            breakdown = string.format("%s WL + %s DL + %s BGL + %s BBL = %s WL total", 
                formatNumber(wl), formatNumber(dl), formatNumber(bgl), formatNumber(bbl), formatNumber(totalWL))
        }
    elseif currencyType == "wl" then
        return player:getItemAmount(CURRENCY.wl)
    elseif currencyType == "dl" then
        return player:getItemAmount(CURRENCY.dl)
    elseif currencyType == "bgl" then
        return player:getItemAmount(CURRENCY.bgl)
    elseif currencyType == "bbl" then
        return player:getItemAmount(CURRENCY.bbl)
    elseif currencyType == "gtoken" then
        local gtoken = player:getItemAmount(CURRENCY.gtoken)
        local mega = player:getItemAmount(CURRENCY.mega_gtoken)
        return {
            gtoken = gtoken,
            mega = mega,
            total = gtoken + (mega * 100)
        }
    elseif currencyType == "pwl" then
        return player:getItemAmount(CURRENCY.pwl)
    end
    return 0
end

local function getCurrencyName(currencyType)
    if currencyType == "lock" then return "Lock Series" end
    if currencyType == "wl" then return "World Lock" end
    if currencyType == "dl" then return "Diamond Lock" end
    if currencyType == "bgl" then return "Blue Gem Lock" end
    if currencyType == "bbl" then return "Custom Lock" end
    if currencyType == "gtoken" then return "Growtoken" end
    if currencyType == "pwl" then return "Premium World Lock" end
    return "Unknown"
end

local function getCurrencyID(currencyType)
    if currencyType == "wl" then return CURRENCY.wl end
    if currencyType == "dl" then return CURRENCY.dl end
    if currencyType == "bgl" then return CURRENCY.bgl end
    if currencyType == "bbl" then return CURRENCY.bbl end
    if currencyType == "gtoken" then return CURRENCY.gtoken end
    if currencyType == "pwl" then return CURRENCY.pwl end
    return 0
end

-- ====================
-- ADMIN PANEL FUNCTIONS
-- ====================
local function adminPanelDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wSales Bot Admin Panel``|left|" .. SHOP_CONFIG.NPC_ID .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|Hi Owner of `9" .. SERVER_NAME .. "`o! In this menu you can edit Sales Bot.|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`wSales Bot Admin Menu:|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|rename_categories|Rename Categories|\n"
    dialog = dialog .. "add_button|add_new_item|Add New Item|\n"
    dialog = dialog .. "add_button|edit_items|Edit Items|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "end_dialog|salesbot_admin_main|Close|\n"
    
    return dialog
end

local function renameCategoriesDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wRename Categories``|left|" .. SHOP_CONFIG.NPC_ID .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    -- Kategori 1
    dialog = dialog .. "add_smalltext|`wCategory 1 (Current: " .. SHOP_CONFIG.CATEGORIES.custom1.name .. ")|left|\n"
    dialog = dialog .. "add_text_input|cat1_name|New Name:|" .. SHOP_CONFIG.CATEGORIES.custom1.name .. "|20|\n"
    dialog = dialog .. "add_button|save_cat1|Save Category 1|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    -- Kategori 2
    dialog = dialog .. "add_smalltext|`wCategory 2 (Current: " .. SHOP_CONFIG.CATEGORIES.custom2.name .. ")|left|\n"
    dialog = dialog .. "add_text_input|cat2_name|New Name:|" .. SHOP_CONFIG.CATEGORIES.custom2.name .. "|20|\n"
    dialog = dialog .. "add_button|save_cat2|Save Category 2|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    -- Kategori 3
    dialog = dialog .. "add_smalltext|`wCategory 3 (Current: " .. SHOP_CONFIG.CATEGORIES.custom3.name .. ")|left|\n"
    dialog = dialog .. "add_text_input|cat3_name|New Name:|" .. SHOP_CONFIG.CATEGORIES.custom3.name .. "|20|\n"
    dialog = dialog .. "add_button|save_cat3|Save Category 3|\n"
    
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. "add_button|back_admin|Back to Admin Panel|\n"
    dialog = dialog .. "end_dialog|salesbot_rename_categories|Close|\n"
    
    return dialog
end

local function addNewItemDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wAdd New Item``|left|" .. SHOP_CONFIG.NPC_ID .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|In this menu you can add new items to specific category.|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    dialog = dialog .. "add_smalltext|`wItem Details:|left|\n"
    dialog = dialog .. "add_text_input|new_item_id|Item ID:|2|5|\n"
    dialog = dialog .. "add_text_input|new_item_amount|Amount (1-200):|1|3|\n"
    dialog = dialog .. "add_text_input|new_item_price|Price (1-200):|1|3|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    dialog = dialog .. "add_smalltext|`wSelect Category:|left|\n"
    dialog = dialog .. "add_button|select_cat1|Category 1|\n"
    dialog = dialog .. "add_button|select_cat2|Category 2|\n"
    dialog = dialog .. "add_button|select_cat3|Category 3|\n"
    
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. "add_button|back_admin|Back to Admin Panel|\n"
    dialog = dialog .. "end_dialog|salesbot_add_item|Close|\n"
    
    return dialog
end

local function editItemsDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wEdit Items``|left|" .. SHOP_CONFIG.NPC_ID .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|Select item you want to edit:|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    -- Tampilkan semua item dari semua kategori
    local itemCount = 0
    local allItems = {}
    
    -- Kumpulkan semua item
    for categoryKey, category in pairs(SHOP_CONFIG.CATEGORIES) do
        if SHOP_ITEMS[categoryKey] then
            for i, item in ipairs(SHOP_ITEMS[categoryKey]) do
                table.insert(allItems, {
                    category = categoryKey,
                    index = i,
                    item = item,
                    categoryName = category.name
                })
            end
        end
    end
    
    if #allItems == 0 then
        dialog = dialog .. "add_textbox|`4No items available to edit!|left|\n"
    else
        local itemsPerRow = 4
        local currentRow = 0
        
        for i, data in ipairs(allItems) do
            local itemName = data.item.name or getItemName(data.item.id)
            local displayText = string.sub(itemName, 1, 10) .. (string.len(itemName) > 10 and "..." or "")
            
            dialog = dialog .. string.format("add_button_with_icon|edit_item_%s_%d|%s|option|%d||\n",
                data.category, data.index, displayText, data.item.id)
            
            currentRow = currentRow + 1
            if currentRow % itemsPerRow == 0 and i < #allItems then
                dialog = dialog .. "add_custom_break|\n"
            end
        end
    end
    
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. "add_button|back_admin|Back to Admin Panel|\n"
    dialog = dialog .. "end_dialog|salesbot_edit_items|Close|\n"
    
    return dialog
end

local function editItemDetailsDialog(player, categoryKey, itemIndex)
    local category = SHOP_CONFIG.CATEGORIES[categoryKey]
    if not category then return editItemsDialog(player) end
    
    local item = SHOP_ITEMS[categoryKey] and SHOP_ITEMS[categoryKey][itemIndex]
    if not item then return editItemsDialog(player) end
    
    local itemName = item.name or getItemName(item.id)
    
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wEdit Item``|left|" .. item.id .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`wEditing: " .. itemName .. "|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    dialog = dialog .. "add_smalltext|`wItem Details:|left|\n"
    dialog = dialog .. "add_text_input|edit_item_id|Item ID:|" .. item.id .. "|5|\n"
    dialog = dialog .. "add_text_input|edit_item_amount|Amount (1-200):|1|3|\n"
    dialog = dialog .. "add_text_input|edit_item_price|Price (1-200):|" .. item.price .. "|3|\n"
    
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`wSelect Category:|left|\n"
    dialog = dialog .. "add_button|edit_select_cat1|Category 1|\n"
    dialog = dialog .. "add_button|edit_select_cat2|Category 2|\n"
    dialog = dialog .. "add_button|edit_select_cat3|Category 3|\n"
    
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. string.format("add_button|save_edit_%s_%d|`2Save Changes|\n", categoryKey, itemIndex)
    dialog = dialog .. string.format("add_button|delete_%s_%d|`4Delete Item|\n", categoryKey, itemIndex)
    dialog = dialog .. "add_button|back_edit|Back to Edit Items|\n"
    dialog = dialog .. "end_dialog|salesbot_edit_item_details|Close|\n"
    
    return dialog
end

-- ====================
-- REGULAR SHOP FUNCTIONS
-- ====================
local function mainMenuDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wSales Bot``|left|" .. SHOP_CONFIG.NPC_ID .. "|\n"
    dialog = dialog .. "add_textbox|Hello! I'm Sales Bot. I sell various items using different currencies.|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|Choose a shop category:|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    for categoryKey, category in pairs(SHOP_CONFIG.CATEGORIES) do
        dialog = dialog .. string.format("add_button|%s|%s|left|\n", categoryKey, category.name)
    end
    
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|check_balance|Check Balance|\n"
    dialog = dialog .. "end_dialog|salesbot_main|Close|\n"
    
    return dialog
end

local function categoryDialog(player, categoryKey)
    local category = SHOP_CONFIG.CATEGORIES[categoryKey]
    if not category then return mainMenuDialog(player) end
    
    local currencyType = category.currency
    local balance = getPlayerCurrencyAmount(player, currencyType)
    local balanceText
    
    if currencyType == "lock" then
        local bal = balance
        balanceText = string.format("WL: %s | DL: %s | BGL: %s | BBL: %s", 
            formatNumber(bal.wl), formatNumber(bal.dl), 
            formatNumber(bal.bgl), formatNumber(bal.bbl))
    elseif currencyType == "gtoken" then
        local bal = balance
        balanceText = string.format("Growtoken: %s | Mega Growtoken: %s", 
            formatNumber(bal.gtoken), formatNumber(bal.mega))
    else
        balanceText = formatNumber(balance)
    end
    
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. string.format("add_label_with_icon|big|%s``|left|%d|\n", category.name, category.icon)
    dialog = dialog .. string.format("add_textbox|%s|left|\n", category.description)
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. string.format("add_smalltext|Currency: `9%s`o|left|\n", getCurrencyName(currencyType))
    dialog = dialog .. string.format("add_smalltext|Your Balance: `2%s`o|left|\n", balanceText)
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|Available Items:|left|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    if not SHOP_ITEMS[categoryKey] or #SHOP_ITEMS[categoryKey] == 0 then
        dialog = dialog .. "add_textbox|`4No items available in this shop!|left|\n"
    else
        local itemsPerRow = 4
        local itemCount = 0
        
        for i, item in ipairs(SHOP_ITEMS[categoryKey]) do
            local itemName = item.name or getItemName(item.id)
            local currencyName = getCurrencyName(item.currency)
            
            dialog = dialog .. string.format("add_button_with_icon|buy_%s_%d|%s - %d %s|option|%d||\n",
                categoryKey, i, itemName, item.price, currencyName, item.id)
            
            itemCount = itemCount + 1
            
            if itemCount % itemsPerRow == 0 and i < #SHOP_ITEMS[categoryKey] then
                dialog = dialog .. "add_custom_break|\n"
            end
        end
    end
    
    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|big|\n"
    dialog = dialog .. "add_button|back|Back to Main|\n"
    if player:hasRole(2) then
        dialog = dialog .. "add_button|admin_panel|`9Admin Panel|\n"
    end
    dialog = dialog .. "end_dialog|salesbot_category|Close|\n"
    
    return dialog
end

local function balanceDialog(player)
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wYour Balance``|left|" .. SHOP_CONFIG.NPC_ID .. "|\n"
    dialog = dialog .. "add_spacer|small|\n"
    
    -- Lock Series dengan konversi ke WL
    local lockBal = getPlayerCurrencyAmount(player, "lock")
    dialog = dialog .. "add_smalltext|`wLock Series (Converted to WL):|left|\n"
    dialog = dialog .. string.format("add_label_with_icon|small|World Lock: `2%s`o = `2%s WL`o|left|%d|\n", 
        formatNumber(lockBal.wl), formatNumber(lockBal.wl), CURRENCY.wl)
    dialog = dialog .. string.format("add_label_with_icon|small|Diamond Lock: `2%s`o = `2%s WL`o (1 DL = 100 WL)|left|%d|\n", 
        formatNumber(lockBal.dl), formatNumber(lockBal.dl * 100), CURRENCY.dl)
    dialog = dialog .. string.format("add_label_with_icon|small|Blue Gem Lock: `2%s`o = `2%s WL`o (1 BGL = 10,000 WL)|left|%d|\n", 
        formatNumber(lockBal.bgl), formatNumber(lockBal.bgl * 10000), CURRENCY.bgl)
    dialog = dialog .. string.format("add_label_with_icon|small|Custom Lock: `2%s`o = `2%s WL`o (1 BBL = 1,000,000 WL)|left|%d|\n", 
        formatNumber(lockBal.bbl), formatNumber(lockBal.bbl * 1000000), CURRENCY.bbl)
    dialog = dialog .. string.format("add_smalltext|`wTotal Lock Value: `2%s WL`o|left|\n", formatNumber(lockBal.total))
    
    dialog = dialog .. "add_spacer|small|\n"
    
    -- GToken
    local gtokenBal = getPlayerCurrencyAmount(player, "gtoken")
    dialog = dialog .. "add_smalltext|`wGrowtoken:|left|\n"
    dialog = dialog .. string.format("add_label_with_icon|small|Growtoken: `2%s`o|left|%d|\n", 
        formatNumber(gtokenBal.gtoken), CURRENCY.gtoken)
    dialog = dialog .. string.format("add_label_with_icon|small|Mega Growtoken: `2%s`o|left|%d|\n", 
        formatNumber(gtokenBal.mega), CURRENCY.mega_gtoken)
    
    dialog = dialog .. "add_spacer|small|\n"
    
    -- PWL
    dialog = dialog .. "add_smalltext|`wPremium World Lock:|left|\n"
    local pwlBal = getPlayerCurrencyAmount(player, "pwl")
    dialog = dialog .. string.format("add_label_with_icon|small|Premium World Lock: `2%s`o|left|%d|\n", 
        formatNumber(pwlBal), CURRENCY.pwl)
    
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|back|Back|\n"
    dialog = dialog .. "end_dialog|salesbot_balance|Close|\n"
    
    return dialog
end

local function purchaseDialog(player, categoryKey, itemIndex)
    local category = SHOP_CONFIG.CATEGORIES[categoryKey]
    if not category then return mainMenuDialog(player) end
    
    local item = SHOP_ITEMS[categoryKey] and SHOP_ITEMS[categoryKey][itemIndex]
    if not item then return categoryDialog(player, categoryKey) end
    
    local itemName = item.name or getItemName(item.id)
    local currencyName = getCurrencyName(item.currency)
    
    local dialog = "set_default_color|`o\n"
    dialog = dialog .. string.format("add_label_with_icon|big|Purchase %s``|left|%d|\n", itemName, item.id)
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. string.format("add_textbox|Buy `9%s`o for `2%d %s`o each|left|\n", 
        itemName, item.price, currencyName)
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|How many would you like to buy? (Max: 200)|left|\n"
    dialog = dialog .. "add_text_input|quantity|Quantity:|1|3|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. string.format("add_button|confirm_%s_%d|`2Confirm Purchase|\n", categoryKey, itemIndex)
    dialog = dialog .. "add_button|cancel|Cancel|\n"
    dialog = dialog .. "end_dialog|salesbot_purchase|Close|\n"
    
    return dialog
end

-- ====================
-- TRANSACTION PROCESSING
-- ====================
local function processPurchase(player, categoryKey, itemIndex, quantity)
    local category = SHOP_CONFIG.CATEGORIES[categoryKey]
    if not category then return false, "Invalid category" end
    
    local item = SHOP_ITEMS[categoryKey] and SHOP_ITEMS[categoryKey][itemIndex]
    if not item then return false, "Item not found" end
    
    quantity = math.floor(tonumber(quantity) or 1)
    if quantity <= 0 then return false, "Invalid quantity" end
    if quantity > 200 then quantity = 200 end
    
    local currentAmount = player:getItemAmount(item.id)
    if currentAmount + quantity > 200 then
        quantity = 200 - currentAmount
        if quantity <= 0 then
            return false, "Inventory full (max 200)"
        end
    end
    
    local totalPrice = item.price * quantity
    
    local playerBalance = getPlayerCurrencyAmount(player, item.currency)
    local balance
    
    if item.currency == "lock" then
        balance = playerBalance.total
    elseif item.currency == "gtoken" then
        balance = playerBalance.total
    else
        balance = playerBalance
    end
    
    if balance < totalPrice then
        return false, "Not enough " .. getCurrencyName(item.currency)
    end
    
    -- Process transaction
    if item.currency == "lock" then
        local remaining = playerBalance.total - totalPrice
        
        player:changeItem(CURRENCY.wl, -playerBalance.wl, 0)
        player:changeItem(CURRENCY.dl, -playerBalance.dl, 0)
        player:changeItem(CURRENCY.bgl, -playerBalance.bgl, 0)
        player:changeItem(CURRENCY.bbl, -playerBalance.bbl, 0)
        
        local newBBL = math.floor(remaining / 1000000)
        local newBGL = math.floor((remaining % 1000000) / 10000)
        local newDL = math.floor((remaining % 10000) / 100)
        local newWL = remaining % 100
        
        if newWL > 0 then player:changeItem(CURRENCY.wl, newWL, 0) end
        if newDL > 0 then player:changeItem(CURRENCY.dl, newDL, 0) end
        if newBGL > 0 then player:changeItem(CURRENCY.bgl, newBGL, 0) end
        if newBBL > 0 then player:changeItem(CURRENCY.bbl, newBBL, 0) end
        
    elseif item.currency == "gtoken" then
        local remaining = playerBalance.total - totalPrice
        
        player:changeItem(CURRENCY.gtoken, -playerBalance.gtoken, 0)
        player:changeItem(CURRENCY.mega_gtoken, -playerBalance.mega, 0)
        
        local newMega = math.floor(remaining / 100)
        local newGToken = remaining % 100
        
        if newGToken > 0 then player:changeItem(CURRENCY.gtoken, newGToken, 0) end
        if newMega > 0 then player:changeItem(CURRENCY.mega_gtoken, newMega, 0) end
        
    else
        player:changeItem(getCurrencyID(item.currency), -totalPrice, 0)
    end
    
    player:changeItem(item.id, quantity, 0)
    
    return true, string.format("Purchased %d %s for %d %s", 
        quantity, item.name or getItemName(item.id), totalPrice, getCurrencyName(item.currency))
end

-- ====================
-- CALLBACK HANDLERS
-- ====================
onPlayerDialogCallback(function(world, player, data)
    local dialogName = data["dialog_name"] or ""
    local button = data["buttonClicked"] or ""
    
    -- Admin Panel Dialogs
    if dialogName == "salesbot_admin_main" then
        if button == "rename_categories" then
            player:onDialogRequest(renameCategoriesDialog(player))
            return true
        elseif button == "add_new_item" then
            player:onDialogRequest(addNewItemDialog(player))
            return true
        elseif button == "edit_items" then
            player:onDialogRequest(editItemsDialog(player))
            return true
        elseif button == "back_admin" then
            player:onDialogRequest(adminPanelDialog(player))
            return true
        end
    end
    
    -- Rename Categories Dialog
    if dialogName == "salesbot_rename_categories" then
        if button == "save_cat1" then
            local newName = data["cat1_name"] or SHOP_CONFIG.CATEGORIES.custom1.name
            if newName and newName ~= "" then
                SHOP_CONFIG.CATEGORIES.custom1.name = newName
                player:onTalkBubble(player:getNetID(), "`2Category 1 renamed to: " .. newName, 0)
            end
            player:onDialogRequest(renameCategoriesDialog(player))
            return true
            
        elseif button == "save_cat2" then
            local newName = data["cat2_name"] or SHOP_CONFIG.CATEGORIES.custom2.name
            if newName and newName ~= "" then
                SHOP_CONFIG.CATEGORIES.custom2.name = newName
                player:onTalkBubble(player:getNetID(), "`2Category 2 renamed to: " .. newName, 0)
            end
            player:onDialogRequest(renameCategoriesDialog(player))
            return true
            
        elseif button == "save_cat3" then
            local newName = data["cat3_name"] or SHOP_CONFIG.CATEGORIES.custom3.name
            if newName and newName ~= "" then
                SHOP_CONFIG.CATEGORIES.custom3.name = newName
                player:onTalkBubble(player:getNetID(), "`2Category 3 renamed to: " .. newName, 0)
            end
            player:onDialogRequest(renameCategoriesDialog(player))
            return true
            
        elseif button == "back_admin" then
            player:onDialogRequest(adminPanelDialog(player))
            return true
        end
    end
    
    -- Add New Item Dialog
    if dialogName == "salesbot_add_item" then
        if button == "select_cat1" or button == "select_cat2" or button == "select_cat3" then
            local categoryNum = button:match("select_cat(%d)")
            local categoryKey = "custom" .. categoryNum
            
            local itemID = tonumber(data["new_item_id"] or "2")
            local amount = tonumber(data["new_item_amount"] or "1")
            local price = tonumber(data["new_item_price"] or "1")
            
            if not itemID or itemID <= 0 then
                player:onTalkBubble(player:getNetID(), "`4Invalid Item ID!", 1)
                player:onDialogRequest(addNewItemDialog(player))
                return true
            end
            
            if not amount or amount < 1 or amount > 200 then
                player:onTalkBubble(player:getNetID(), "`4Amount must be 1-200!", 1)
                player:onDialogRequest(addNewItemDialog(player))
                return true
            end
            
            if not price or price < 1 or price > 200 then
                player:onTalkBubble(player:getNetID(), "`4Price must be 1-200!", 1)
                player:onDialogRequest(addNewItemDialog(player))
                return true
            end
            
            local category = SHOP_CONFIG.CATEGORIES[categoryKey]
            if not category then
                player:onTalkBubble(player:getNetID(), "`4Invalid category!", 1)
                player:onDialogRequest(addNewItemDialog(player))
                return true
            end
            
            -- Determine currency based on category
            local currency
            if categoryKey == "custom1" then currency = "wl"
            elseif categoryKey == "custom2" then currency = "pwl"
            elseif categoryKey == "custom3" then currency = "gtoken"
            else currency = "wl" end
            
            local itemName = getItemName(itemID)
            
            if not SHOP_ITEMS[categoryKey] then
                SHOP_ITEMS[categoryKey] = {}
            end
            
            table.insert(SHOP_ITEMS[categoryKey], {
                id = itemID,
                name = itemName,
                price = price,
                currency = currency
            })
            
            player:onTalkBubble(player:getNetID(), 
                string.format("`2Added %s to %s!", itemName, category.name), 0)
            player:onDialogRequest(addNewItemDialog(player))
            return true
            
        elseif button == "back_admin" then
            player:onDialogRequest(adminPanelDialog(player))
            return true
        end
    end
    
    -- Edit Items Dialog
    if dialogName == "salesbot_edit_items" then
        if button:find("^edit_item_") then
            local categoryKey, itemIndex = button:match("^edit_item_(%w+)_(%d+)")
            if categoryKey and itemIndex then
                player:onDialogRequest(editItemDetailsDialog(player, categoryKey, tonumber(itemIndex)))
                return true
            end
        elseif button == "back_admin" then
            player:onDialogRequest(adminPanelDialog(player))
            return true
        end
    end
    
    -- Edit Item Details Dialog
    if dialogName == "salesbot_edit_item_details" then
        if button:find("^save_edit_") then
            local categoryKey, itemIndex = button:match("^save_edit_(%w+)_(%d+)")
            if categoryKey and itemIndex and SHOP_ITEMS[categoryKey] then
                local itemID = tonumber(data["edit_item_id"] or "2")
                local amount = tonumber(data["edit_item_amount"] or "1")
                local price = tonumber(data["edit_item_price"] or "1")
                
                if itemID and amount and price and amount >= 1 and amount <= 200 and price >= 1 and price <= 200 then
                    SHOP_ITEMS[categoryKey][tonumber(itemIndex)] = {
                        id = itemID,
                        name = getItemName(itemID),
                        price = price,
                        currency = SHOP_ITEMS[categoryKey][tonumber(itemIndex)].currency or "wl"
                    }
                    
                    player:onTalkBubble(player:getNetID(), "`2Item updated successfully!", 0)
                    player:onDialogRequest(editItemsDialog(player))
                end
                return true
            end
            
        elseif button:find("^delete_") then
            local categoryKey, itemIndex = button:match("^delete_(%w+)_(%d+)")
            if categoryKey and itemIndex and SHOP_ITEMS[categoryKey] then
                table.remove(SHOP_ITEMS[categoryKey], tonumber(itemIndex))
                player:onTalkBubble(player:getNetID(), "`2Item deleted!", 0)
                player:onDialogRequest(editItemsDialog(player))
                return true
            end
            
        elseif button == "back_edit" then
            player:onDialogRequest(editItemsDialog(player))
            return true
        end
    end
    
    -- Regular Shop Dialogs (tetap sama)
    if dialogName == "salesbot_main" then
        if button == "check_balance" then
            player:onDialogRequest(balanceDialog(player))
            return true
        elseif button == "admin_panel" and player:hasRole(2) then
            player:onDialogRequest(adminPanelDialog(player))
            return true
        end
        
        if SHOP_CONFIG.CATEGORIES[button] then
            player:onDialogRequest(categoryDialog(player, button))
            return true
        end
    end
    
    if dialogName == "salesbot_category" then
        if button == "back" then
            player:onDialogRequest(mainMenuDialog(player))
            return true
        elseif button == "check_balance" then
            player:onDialogRequest(balanceDialog(player))
            return true
        elseif button == "admin_panel" and player:hasRole(2) then
            player:onDialogRequest(adminPanelDialog(player))
            return true
        elseif button:find("^buy_") then
            local categoryKey, itemIndex = button:match("^buy_(%w+)_(%d+)")
            if categoryKey and itemIndex then
                player:onDialogRequest(purchaseDialog(player, categoryKey, tonumber(itemIndex)))
                return true
            end
        end
    end
    
    if dialogName == "salesbot_purchase" then
        if button == "cancel" then
            player:onDialogRequest(mainMenuDialog(player))
            return true
        elseif button:find("^confirm_") then
            local categoryKey, itemIndex = button:match("^confirm_(%w+)_(%d+)")
            if categoryKey and itemIndex then
                local quantity = tonumber(data["quantity"] or "1") or 1
                local success, message = processPurchase(player, categoryKey, tonumber(itemIndex), quantity)
                
                if success then
                    player:onTalkBubble(player:getNetID(), "`2" .. message, 0)
                    player:playAudio("cash_register.wav")
                else
                    player:onTalkBubble(player:getNetID(), "`4" .. message, 1)
                    player:playAudio("bleep_fail.wav")
                end
                
                player:onDialogRequest(categoryDialog(player, categoryKey))
                return true
            end
        end
    end
    
    if dialogName == "salesbot_balance" then
        if button == "back" then
            player:onDialogRequest(mainMenuDialog(player))
            return true
        end
    end
    
    return false
end)

-- ====================
-- COMMANDS REGISTRATION
-- ====================
registerLuaCommand({
    command = "shop",
    roleRequired = 0,
    description = "Open Sales Bot Shop"
})

registerLuaCommand({
    command = "salesbotadmin",
    roleRequired = 2,
    description = "Open Sales Bot Admin Panel"
})

onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)")
    
    if command == "shop" then
        player:onDialogRequest(mainMenuDialog(player))
        player:playAudio("spell1.wav")
        return true
        
    elseif command == "salesbotadmin" then
        if player:hasRole(2) then
            player:onDialogRequest(adminPanelDialog(player))
            player:playAudio("spell1.wav")
        else
            player:onTalkBubble(player:getNetID(), "`4Admin access required!", 1)
        end
        return true
    end
    
    return false
end)

onTileWrenchCallback(function(world, player, tile)
    local tileID = tile:getTileID()
    
    if tileID == SHOP_CONFIG.NPC_ID then
        player:onDialogRequest(mainMenuDialog(player))
        return true
    end
    
    return false
end)

print("Sales Bot Shop + Admin Panel loaded!")
print("NPC ID: " .. SHOP_CONFIG.NPC_ID)
print("Commands: /shop, /salesbotadmin (Admin)")
print("Server: " .. SERVER_NAME)