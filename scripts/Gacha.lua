print("gacha loaded script for growsoft")

math.randomseed(os.time())

local GACHA_COMMAND = "gacha"
local COST_ITEM_ID  = 7188
local COST_AMOUNT   = 1
local MIN_ITEM_ID   = 50
local MAX_ITEM_ID   = 25000
local MIN_RARITY    = 5
local MAX_RARITY    = 999
local GACHA_SAVE_KEY = "GrowSoft_GachaRarityPool_v9"

_G.GachaPool = _G.GachaPool or {}
_G.GachaLoading = false 

registerLuaCommand({
    command = GACHA_COMMAND,
    roleRequired = Roles.ROLE_NONE,
    description = "Opens the Gacha Machine"
})
print("[Gacha] Command /" .. GACHA_COMMAND .. " registered successfully!")

local function isValidGachaItem(item)
    if not item then return false end
    
    local name = item:getName()
    if not name or name == "" or name == "?" then return false end

    local lowerName = string.lower(name)

    if string.find(lowerName, "null_item") then return false end
    if lowerName == "null" then return false end
    if string.find(name, "xx") or string.find(name, "Unused") then return false end

    if string.find(lowerName, "deleted_item") then return false end

    if string.find(lowerName, "seed") then return false end
    if item.getType and item:getType() == 3 then return false end

    local cat = item:getCategoryType()
    if not cat or cat == 0 then return false end

    return true
end

local function generateGachaPool()
    _G.GachaLoading = true
    print("[Gacha] Scanning items in background...")
    
    local tempPool = {}
    local count = 0

    for id = MIN_ITEM_ID, MAX_ITEM_ID do
        local item = getItem(id)
        if isValidGachaItem(item) then
            local rarity = math.random(MIN_RARITY, MAX_RARITY)
            local chance = 100.0 / rarity

            table.insert(tempPool, {
                itemID = id,
                rarity = rarity,
                chance = chance
            })
            count = count + 1
        end
    end

    _G.GachaPool = tempPool
    saveDataToServer(GACHA_SAVE_KEY, _G.GachaPool)
    
    _G.GachaLoading = false
    print("[Gacha] POOL READY! Total Valid Items: " .. count)
end

local function loadGachaPool()
    if runThread then
        runThread(function() generateGachaPool() end)
    else
        generateGachaPool()
    end
end

local function getRandomWeightedItem()
    if #_G.GachaPool == 0 then return nil end

    local total = 0
    for _, data in ipairs(_G.GachaPool) do
        total = total + data.chance
    end

    local roll = math.random() * total
    local current = 0

    for _, data in ipairs(_G.GachaPool) do
        current = current + data.chance
        if roll <= current then
            return data
        end
    end

    return _G.GachaPool[math.random(1, #_G.GachaPool)]
end

local function showGachaDialog(player)
    if _G.GachaLoading then
        player:onConsoleMessage("`6[Gacha] System is updating item list... Please wait.")
        return
    end

    local balance = player:getItemAmount(COST_ITEM_ID)
    local costItem = getItem(COST_ITEM_ID)
    local costName = costItem and costItem:getName() or ("ItemID " .. COST_ITEM_ID)
    local poolSize = #_G.GachaPool

    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wGrowfax Gacha Machine``|left|" .. COST_ITEM_ID .. "|\n"
    dialog = dialog .. "add_textbox|Spin and get prize item!``|\n"
    dialog = dialog .. "add_smalltext|Status: " .. poolSize .. " items loaded``|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|Cost: `w" .. COST_AMOUNT .. " " .. costName .. "``|\n"
    dialog = dialog .. "add_textbox|Your Balance: `w" .. balance .. "``|\n"
    dialog = dialog .. "add_spacer|small|\n"

    if poolSize == 0 then
        dialog = dialog .. "add_button|null|`4ERROR: POOL EMPTY``|off|\n"
    elseif balance >= COST_AMOUNT then
        dialog = dialog .. "add_button|spin|`2Spin Now!``|noflags|\n"
    else
        dialog = dialog .. "add_button|spin|`4Not Enough Currency``|off|\n"
    end

    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|GACHA_MAIN||\n"

    player:onDialogRequest(dialog)
end

local function showResultDialog(player, itemID, rarity)
    local item = getItem(itemID)
    local name = item and item:getName() or ("ItemID " .. itemID)

    local dialog = "set_default_color|`o\n"
    dialog = dialog .. "add_label_with_icon|big|`wSpin Result``|left|" .. itemID .. "|\n"
    dialog = dialog .. "add_textbox|You received: `w" .. name .. "``|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_button|again|Spin Again!|noflags|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|GACHA_RESULT||\n"

    player:onDialogRequest(dialog)
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if cmd ~= GACHA_COMMAND then return false end
    showGachaDialog(player)
    return true
end)

onPlayerDialogCallback(function(world, player, data)
    local dialog = data["dialog_name"]
    local button = data["buttonClicked"]

    if dialog == "GACHA_MAIN" then
        if button == "spin" then
            if _G.GachaLoading then
                player:onConsoleMessage("`6System is loading...")
                return true
            end

            if #_G.GachaPool == 0 then
                player:onConsoleMessage("`4Error: Gacha pool is empty!")
                return true
            end

            local balance = player:getItemAmount(COST_ITEM_ID)
            if balance < COST_AMOUNT then
                player:onConsoleMessage("`4Not enough item!")
                return true
            end

            if not player:changeItem(COST_ITEM_ID, -COST_AMOUNT, 0) then
                player:onConsoleMessage("`4Failed to deduct currency.")
                return true
            end

            local result = getRandomWeightedItem()
            if not result then
                player:onConsoleMessage("`4Error picking item.")
                return true
            end

            player:changeItem(result.itemID, 1, 0)
            showResultDialog(player, result.itemID, result.rarity)
            return true
        end
        return false
    end

    if dialog == "GACHA_RESULT" then
        if button == "again" then
            showGachaDialog(player)
            return true
        end
        return false
    end
end)

onAutoSaveRequest(function()
    if #_G.GachaPool > 0 then
        saveDataToServer(GACHA_SAVE_KEY, _G.GachaPool)
    end
end)

loadGachaPool()