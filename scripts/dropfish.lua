print("dropfish by @Nperma")

local function LogMessage(p,msg,use)
    use = use or 0
    if use ~= 1 then p:onTalkBubble(p:getNetID(),msg,1) end
    if use ~= 2 then p:onConsoleMessage(msg) end
end

local function isFish(itemID)
    local item = getItem(itemID)
    return item and item:getActionType() == 64
end

registerLuaCommand({
    command = "dropfish",
    roleRequired = 0,
    description = "Drops all fish items in front of you."
})

onPlayerCommandCallback(function(world, player, command)
    if command == "dropfish" then 

    local playerTileX = math.floor(player:getPosX() / 32)
    local playerTileY = math.floor(player:getPosY() / 32)
    local frontTileX = player:isFacingLeft() and (playerTileX - 1) or (playerTileX + 1)
    local frontTileY = playerTileY

    local tile = world:getTile(frontTileX, frontTileY)
    if not tile then
        player:onTalkBubble(player:getNetID(), "`4No tile detected in front of you.", 0)
        return true
    end
   

    local inventoryItems = player:getInventoryItems()
    local itemsDropped = 0

    local dropX = frontTileX * 32
    local dropY = frontTileY * 32

    for _, item in ipairs(inventoryItems) do
    local itemID = item:getItemID()
    local itemAmount = player:getItemAmount(itemID)
    if isFish(itemID) then 
      player:changeItem(itemID,-itemAmount,0)
      world:spawnItem(dropX,dropY,itemID,itemAmount)
      itemsDropped=itemsDropped+1
      end
end


    if itemsDropped > 0 then
        player:onTalkBubble(player:getNetID(), "`2Successfully dropped all tradeable items.", 0)
        player:playAudio("success.wav")
    else
        player:onTalkBubble(player:getNetID(), "`7You have no fish items to drop.", 0)
        player:playAudio("error.wav")
    end

    return true
    end
 return false
end)