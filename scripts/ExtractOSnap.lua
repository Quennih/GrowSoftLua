print("(Loaded) Extract-O-Snap Script for GrowSoft")

function getItemNameByID(itemID)
    local item = getItem(itemID)
    if item then
        return item:getName() or "Unknown Item"
    else
        return "Unknown Item"
    end
end

local Roles = {
    ROLE_DEVELOPER = 51
}

local extractor_snap_data = {}
local inventorySlot = 200

onPlayerConsumableCallback(function(world, player, tile, clickedPlayer, itemID)

    if itemID ~= 6140 then return false end

    local worldOwner = world:getOwner()
    local isOwnerless = (worldOwner == nil)
    local isOwner = (not isOwnerless and worldOwner:getUserID() == player:getUserID())

    if not isOwnerless and not isOwner then
        if not player:hasRole(Roles.ROLE_DEVELOPER) then
            player:onTalkBubble(player:getNetID(), "Only the world owner can use Extract-O-Snap here.", 1)
            return true
        end
    end

    local drops = world:getTileDroppedItems(tile)
    if #drops == 0 then
        player:onTalkBubble(player:getNetID(), "No items found on this tile", 1)
        return true
    end

    extractor_snap_data[player:getUserID()] = {}

    local dialog = "add_label_with_icon|big|`wExtract-O-Snap                                          ``|left|6140|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`oGrowTech: Use the Extract-O-Snap to pick out the items from the|\n"
    dialog = dialog .. "add_smalltext|`ofloating items in your world! - Thanks, Technician Dave.|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`oPress on the icon to extract the item into your inventory.|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_smalltext|`oItem List:|\n"
    dialog = dialog .. "add_custom_break|\n"

    for i, drop in ipairs(drops) do
        local uid = drop:getUID()
        local itemID = drop:getItemID()
        local count = drop:getItemCount()
        local itemName = getItemNameByID(itemID)
        local buttonID = "extract_uid_" .. uid

        extractor_snap_data[player:getUserID()][buttonID] = {
            itemID = itemID,
            amount = count,
            uid = uid
        }

        dialog = dialog .. "text_scaling_string|aaaaaaaaaaaaaa|\n"
        dialog = dialog .. string.format("add_button_with_icon|%s|%s x%d|staticYellowFrame|%d|\n", buttonID, itemName, count, itemID)

        if i % 8 == 0 then
            dialog = dialog .. "add_custom_break|\n"
            dialog = dialog .. "add_spacer|small|\n"
        end
    end

    dialog = dialog .. "add_custom_break|\n"
    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|extractor_snap_dialog|Close|\n"
    player:onDialogRequest(dialog)

    return true
end)

onPlayerDialogCallback(function(world, player, data)

    if data["dialog_name"] ~= "extractor_snap_dialog" then return false end

    local clicked = data["buttonClicked"]
    if not clicked or not clicked:find("^extract_uid_") then return false end

    local userID = player:getUserID()
    local storedData = extractor_snap_data[userID] and extractor_snap_data[userID][clicked]

    if not storedData then
        player:onTalkBubble(player:getNetID(), "Invalid Item Selection", 1)
        return true
    end

    local uid = storedData.uid
    local itemID = storedData.itemID
    local amount = storedData.amount

    local found = false
    for _, drop in ipairs(world:getDroppedItems()) do
        if drop:getUID() == uid then
            found = true
            break
        end
    end

    if not found then
        player:onTalkBubble(player:getNetID(), "Someone already picked that up.", 1)
        return true
    end

    local currentAmount = player:getItemAmount(itemID)
    if currentAmount + amount > inventorySlot then
        player:onTalkBubble(player:getNetID(), "Clear your inventory first before collecting", 1)
        return true
    end

    local added = player:changeItem(itemID, amount, 0)
    if not added then
        added = player:changeItem(itemID, amount, 1)
    end

    if not added then
        player:onTalkBubble(player:getNetID(), "Failed to collect item", 1)
        return true
    end

    world:removeDroppedItem(uid)
    player:changeItem(6140, -1, 0)
    player:onTalkBubble(player:getNetID(), "Collected `2" .. amount .. " " .. getItemNameByID(itemID), 1)
    player:onConsoleMessage("Collected " .. amount .. " " .. getItemNameByID(itemID))

    extractor_snap_data[userID][clicked] = nil

    return true
end)

onPlayerDisconnectCallback(function(player)
    local userID = player:getUserID()
    extractor_snap_data[userID] = nil
    print("[Extract-O-Snap] Temporary Data Cleared: " .. userID)
end)