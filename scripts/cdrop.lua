print("(Loaded) Drop Command for Custom Locks")

local CUSTOM_LOCK_ID = 2

local dropCommandData = {
    command = "cd",
    roleRequired = Roles.ROLE_NONE,
    description = "Drop a specified number of Custom Locks."
}

registerLuaCommand(dropCommandData)

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, amount = fullCommand:match("^(%S+)%s*(%d*)")

    if command == dropCommandData.command then
        local dropAmount = tonumber(amount) or 1 

        if dropAmount < 1 then
            player:onTalkBubble(player:getNetID(), "You must drop at least 1 Custom Lock!", 1)
            return true
        end

        local currentAmount = player:getItemAmount(CUSTOM_LOCK_ID)

        if currentAmount < dropAmount then
            player:onTalkBubble(player:getNetID(), "You don't have enough Custom Locks to drop that amount!", 1)
            return true
        end

        player:changeItem(CUSTOM_LOCK_ID, -dropAmount, 0)

        local dropX = player:getPosX()
        local dropY = player:getPosY()

        if player:isFacingLeft() then
            dropX = dropX - 25  -- Drop to the left
        else
            dropX = dropX + 25  -- Drop to the right
        end

        world:spawnItem(dropX, dropY, CUSTOM_LOCK_ID, dropAmount)

        player:onTalkBubble(player:getNetID(), string.format("Dropped %d Custom Lock(s).", dropAmount), 0)
        return true
    end

    return false
end)