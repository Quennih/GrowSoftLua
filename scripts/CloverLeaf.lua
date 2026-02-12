onPlayerConsumableCallback(function(world, player, tile, clickedPlayer, itemID)
    if itemID ~= 2412 then -- Cloverleaf
        return false
    end

    if player:changeItem(2412, -4, 0) then
        player:changeItem(528, 1, 0) -- Clover Normal

        player:onConsoleMessage("You crafted a Lucky Clover!")
        return true    
    else
        player:onConsoleMessage("You need 4 clover leaves to craft a Lucky Clover.")
        return true    
    end
end)