print("(Loaded) Bonus Drop Script for GrowSoft")

math.randomseed(os.time())

-- [tileID] = { dropID, amount, chance (0.01 = 1%, 100 = 100%) }
local drops = {
    [2] = {
        { dropID = 242, amount = 1, chance = 10 }, -- 10% chance
        { dropID = 500, amount = 1, chance = 5 },  -- 5% chance
    },
}

local function shouldDrop(chancePercent)
    local roll = math.random() * 100
    return roll <= chancePercent
end

onTileBreakCallback(function(world, player, tile)
    local tileID = tile:getTileID()
    local possibleDrops = drops[tileID]

    if possibleDrops then
        local eligibleDrops = {}

        for _, drop in ipairs(possibleDrops) do
            if shouldDrop(drop.chance) then
                table.insert(eligibleDrops, drop)
            end
        end

        if #eligibleDrops > 0 then
            local selectedDrop = eligibleDrops[math.random(1, #eligibleDrops)]

            for i = 1, selectedDrop.amount do
                world:spawnItem(tile:getPosX(), tile:getPosY(), selectedDrop.dropID, 1)
            end
            
        end

        return false
    end

    return false
end)