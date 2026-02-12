print("(Loaded) Sigil Of K'tesh Script for GrowSoft")

onPlayerConsumableCallback(function(world, player, tile, clickedPlayer, itemID)

    local SIGIL_OF_KTESH_ID = 1220
    local currentWorld = player:getWorldName()
    local currentEvent = getTodaysEvents()

    if itemID ~= SIGIL_OF_KTESH_ID then return false end

    if not string.find(currentEvent, "Halloween Day") then
        player:onTalkBubble(player:getNetID(), "`#The sigil has no power today...", 0)
        return true
    end

    if string.upper(currentWorld) ~= "GROWGANOTH" then 
        player:onTalkBubble(player:getNetID(), "`#The sigil fizzles... try using it near Growganoth!", 0)
        return true
    end

    if player:changeItem(itemID, -1, 0) then
        world:setPlayerPosition(player, 1650, 440)
        player:onTalkBubble(player:getNetID(), "`#Growganoth pulls you closer!", 0)
        return true
    end

    return true
end)