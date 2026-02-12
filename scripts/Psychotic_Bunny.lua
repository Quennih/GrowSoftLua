onPlayerConsumableCallback(function(world, player, tile, clickedPlayer, itemID)
    if itemID ~= 618 then
        return false  
    end

    if not clickedPlayer then
        player:onTalkBubble(player:getNetID(), "`wMust be used on a person!``", 1)
        return true
    end
    if player:changeItem(itemID, -1, 0) then
        
        local screams = {
            "`4ARGGH!!``",
            "`4MY EYES!!``",
            "`4IT BIT ME!!``",
            "`4HELP ME!!``",
            "`4THE PAIN!!``",
            "`4NOOO!!!``"
        }

        -- Select a random scream
        local randomScream = screams[math.random(1, #screams)]
        clickedPlayer:onTalkBubble(clickedPlayer:getNetID(), randomScream, 1)
        player:sendVariant({"OnPlayPositioned", "audio/punch.wav", clickedPlayer:getNetID()})
        world:kill(clickedPlayer)
        --clickedPlayer:onConsoleMessage("`rYou were devoured by a Psychotic Bunny!``")

        return true
    end

    return true
end)