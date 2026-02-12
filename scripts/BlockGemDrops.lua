print("(Loaded) Block Gem Drops Script for GrowSoft")

math.randomseed(os.time())

local gemDropConfig = {
    [2] = { min = 100, max = 200 },
    [10] = { min = 5, max = 10 },
    [542] = { min = 1, max = 100 },
}

onTileBreakCallback(function(world, player, tile)
    local tileID = tile:getTileID()
    local config = gemDropConfig[tileID]

    if config then
        local dropAmount = math.random(config.min, config.max)
        world:spawnGems(tile:getPosX(), tile:getPosY(), dropAmount, player)
        return false
    end

    return false
end)