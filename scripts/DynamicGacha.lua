print("(Loaded) Dynamic Gacha System Script for GrowSoft")

-- 0.01 = 1%, 0.50 = 50%, and 1 = 100%
local dropSets = {
    -- Set 1: Regular Drops (No Events)
    {
        {itemID = 2, chance = 0.90},
        {itemID = 10, chance = 1},
        {itemID = 10170, chance = 0.01},
        {itemID = 10168, chance = 1},
    },

    -- Set 2: Event 2 (Ex. Phoenix Rising)
    {
        {itemID = 2, chance = 0.10},
        {itemID = 10, chance = 0.25},
        {itemID = 1674, chance = 0.01},
        {itemID = 9730, chance = 0.15},
        {itemID = 8588, chance = 0.10},
    },

    -- Set 3: Event 3 (Ex. Summer Surprise)
    {
        {itemID = 2, chance = 0.10},
        {itemID = 10, chance = 0.10},
        {itemID = 12188, chance = 0.01},
        {itemID = 9758, chance = 0.01},
    },
}

-- Choose Active Drop Set
local activeDropSetIndex = 2

math.randomseed(os.time())

local function rareItem(player)
    return player:onTalkBubble(player:getNetID(), "`2I got rare item!", 0)
end

local function getItemName(itemID)
    local item = getItem(itemID)
    if item then
        return item:getName()
    else
        return "Unknown Item"
    end
end

local function getRandomDrop(player)
    local dropItems = dropSets[activeDropSetIndex]
    local totalChance = 0

    for _, drop in ipairs(dropItems) do
        totalChance = totalChance + (drop.chance * 100)
    end

    local randomRoll = math.random(1, totalChance)
    local cumulativeChance = 0

    for _, drop in ipairs(dropItems) do
        cumulativeChance = cumulativeChance + (drop.chance * 100)
        if randomRoll <= cumulativeChance then
            local itemName = getItemName(drop.itemID)
            print("name: " .. itemName .. " itemid: " .. drop.itemID .. " chance: " .. drop.chance)

            if drop.chance <= 0.05 then
                rareItem(player)
            end

            return {name = itemName, itemID = drop.itemID}
        end
    end

    return nil

end

-- Change tileID with your Gacha Block ID. Check itemID of an item using info.
onTileBreakCallback(function(world, player, tile)
    local tileID = tile:getTileID()
    if tileID == 25018 then
        local drop = getRandomDrop(player)
        if drop then
            world:spawnItem(tile:getPosX(), tile:getPosY(), drop.itemID, 1)
            player:onConsoleMessage("`2You found " .. drop.name .. "!", 0)
            return true
        end
    end

    return false

end)