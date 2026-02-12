print("(Loaded) Quick Drop Script for GrowSoft")

-- /drops <setNumber>
local dropSets = {
    [1] = {
        { itemID = 242, amount = 5000 },
    },

    [2] = {
        { itemID = 20614, amount = 1000 },
        { itemID = 20616, amount = 1000 }
    }
}

local Roles = {
    ROLE_DEVELOPER = 51
}

local dropCommand = {
    command = "drops",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Drops a predefined set of items. Usage: /drops <setNumber>"
}

registerLuaCommand(dropCommand)

local function executeDropSet(player, world, dropSet)
    local x, y = player:getPosX(), player:getPosY()
    local maxPerDrop = 200

    local direction = player:isFacingLeft() and -32 or 32
    local dropX = x + direction

    for _, drop in ipairs(dropSet) do
        local remaining = drop.amount
        while remaining > 0 do
            local dropAmount = math.min(remaining, maxPerDrop)
            world:spawnItem(dropX, y, drop.itemID, dropAmount)
            remaining = remaining - dropAmount
        end
    end

    player:onConsoleMessage("Drop Complete")
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, arg = fullCommand:match("^(%S+)%s*(%d*)$")

    if command == dropCommand.command then
        if not player:hasRole(dropCommand.roleRequired) then
            player:onConsoleMessage("`4Unknown Command.")
            return true
        end

        local setNumber = tonumber(arg)
        if not setNumber or not dropSets[setNumber] then
            player:onConsoleMessage("Invalid or missing drop set number. Usage: /drops <setNumber>")
            return true
        end

        executeDropSet(player, world, dropSets[setNumber])
        return true
    end

    return false
end)