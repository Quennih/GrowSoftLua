print("Winterfest Special Edition by @Nperma")

local data = loadDataFromServer("winterfest_event") or {}
local data_pack = {}

if data ~= nil then data_pack = data end

local function LogMessage(p, msg, use)
    use = use or 0
    if use ~= 1 then p:onTalkBubble(p:getNetID(), msg, 1) end
    if use ~= 2 then p:onConsoleMessage(msg) end
end

function SendNotifSuccess(player)
    player:sendVariant({
        "OnAddNotification",
        "interface/large/special_event.rttex",
        "`2Royal Winter: `#Royal Winter Seals `oSuccess! All items found.",
        "audio/success.wav",
        0
    })
end

local WinterFestivalEventData = {
    id = 22,
    title = "`3Winter Festival``",
    description = "During Winter Festival nothing happens!",
    message = "`8It's time for the `3Winter Festival!````"
}

registerLuaEvent(WinterFestivalEventData)

onEventChangedCallback(function(newEventID, oldEventID)
    if WinterFestivalEventData.id == newEventID then
        print(WinterFestivalEventData.title .. " Has started!")
    elseif WinterFestivalEventData.id == oldEventID then
        print(WinterFestivalEventData.title .. " Has ended!")
    end
end)

local WinterFestivalSidebarButton = {
    active = true,
    buttonAction = "winterfestivalmenu",
    buttonTemplate = "BaseEventButton",
    counter = 0,
    counterMax = 0,
    itemIdIcon = 9186,
    name = "WinterFestival",
    order = WinterFestivalEventData.id,
    rcssClass = "daily_challenge",
    text = "`#Winterfest Quest``"
}

addSidebarButton(json.encode(WinterFestivalSidebarButton))

onPlayerLoginCallback(function(player)
    player:sendVariant({
        "OnEventButtonDataSet",
        WinterFestivalSidebarButton.name,
        (getCurrentServerEvent() == WinterFestivalEventData.id) and 1 or 0,
        json.encode(WinterFestivalSidebarButton)
    })
end)

onPlayerEnterWorldCallback(function(world, player)
    player:sendVariant({
        "OnEventButtonDataSet",
        WinterFestivalSidebarButton.name,
        (getCurrentServerEvent() == WinterFestivalEventData.id) and 1 or 0,
        json.encode(WinterFestivalSidebarButton)
    })
end)

function randomVector2(sizeX, sizeY)
    local minX = math.min(0, sizeX)
    local maxX = math.max(0, sizeX)
    local minY = math.min(0, sizeY)
    local maxY = math.max(0, sizeY)
    local x = math.random(minX, maxX)
    local y = math.random(minY, maxY)
    return x, y
end

local function findSurfaceY(world, x, startY)
    if world:getTile(x/32, startY/32):getTileForeground() == 0 then
        return startY
    end
    local y = startY
    for _ = 1, 50 do
        y = y - 32
        if y < 0 then break end
        if world:getTile(math.floor(x/32), math.floor(y/32)):getTileForeground() == 0 then
            return y
        end
    end
    return startY
end

local function findValidDropPosition(world, sizeX, sizeY, playerY)
    for _ = 1, 40 do
        local x, y = randomVector2(sizeX, sizeY)
        if math.random() <= 0.5 then
            y = findSurfaceY(world, x, playerY)
        else
            local offsetY = playerY + (math.random(-2, 2) * 32)
            y = findSurfaceY(world, x, offsetY)
        end
        local tile = world:getTile(x/32, y/32)
        local drops = world:getTileDroppedItems(tile)
        local same = false
        for _, d in ipairs(drops) do
            if d:getItemID() == 9186 then
                same = true
                break
            end
        end
        if not same then return x, y end
    end
    return nil, nil
end

onPlayerActionCallback(function(world, player, data)
    local action = data["action"]
    if action == WinterFestivalSidebarButton.buttonAction then
    if getCurrentServerEvent() == WinterFestivalEventData.id then

    if world:getOwner():getUserID() ~= player:getUserID() then
        LogMessage(player, "`4You can't start Event in this world")
        return true
    end

    if not data_pack[player:getUserID()] then
        data_pack[player:getUserID()] = {temporary = os.time(), list = {}, countdownInterval = os.time()}
    end

    local pdata = data_pack[player:getUserID()]
    local allFound = true

    for _, v in pairs(pdata.list) do
        if not v[3] then allFound = false break end
    end

    if pdata.countdownInterval > os.time() and not allFound then
        LogMessage(player, "`eEvent already running")
        return true
    end

    if pdata.temporary > os.time() then
        LogMessage(player, "`ePlease wait before starting again")
        return true
    end

    pdata.temporary = os.time() + 3600
    pdata.list = {}

    local sizeX = world:getWorldSizeX() * 32
    local sizeY = world:getWorldSizeY() * 32
    local playerY = player:getPosY()

    for i = 1, 5 do
        local x, y = findValidDropPosition(world, sizeX, sizeY, playerY)
        if not x then break end
        world:spawnItem(x, y, 9186, 1)
        pdata.list[tostring((x/32) .. "-" .. (y/32))] = {x, y, false}
    end
    for _, pl in ipairs(world:getPlayers()) do
    pl:sendVariant({
        "OnAddNotification",
        "interface/large/special_event.rttex",
        "`2Royal Winter: `#Royal Winter Seals `ofor everyone! Be Quick you have `230 `oseconds to collect them!",
        "audio/hub_open.wav",
        0
    })
  end

    pdata.countdownInterval = os.time() + 30

    timer.setTimeout(30.0, function()
        local pdata2 = data_pack[player:getUserID()]
        if not pdata2 then return end

        local foundCount = 0
        for _, v in pairs(pdata2.list) do
            if v[3] then foundCount = foundCount + 1 end
        end

        if foundCount < 5 then
          for _, pl in ipairs(world:getPlayers()) do
            pl:sendVariant({
                "OnAddNotification",
                "interface/large/special_event.rttex",
                string.format("`2Royal Winter: `oTime's up! %d of %d items found.", foundCount, 5),
                "",
                0
            })
          end
          for _,drop in ipairs(world:getDroppedItems()) do 
            if drop:getItemID() == 9186 then world:removeDroppedItem(drop:getUID()) end
            end
        end
      end)
      return true
     end
     return true
    end
    return false
end)

onPlayerPickupItemCallback(function(world, player, itemID, itemCount)
  if itemID == 9186 and data_pack[player:getUserID()] and data_pack[player:getUserID()].countdownInterval > os.time() then
    timer.setTimeout(0.2, function()
        local pdata = data_pack[player:getUserID()]
        if not pdata then return end

        local list = pdata.list
        local drops = world:getDroppedItems()

        for _, drop in ipairs(drops) do
            local tx = math.floor(drop:getPosX() / 32)
            local ty = math.floor(drop:getPosY() / 32)
            local keys = {
                tostring(tx .. "-" .. ty),
                tostring((tx - 1) .. "-" .. ty),
                tostring((tx + 1) .. "-" .. ty)
            }
            for _, k in ipairs(keys) do
                if list[k] then
                    list[k][3] = true
                    break
                end
            end
        end

        for key, value in pairs(list) do
            if not value[3] then
                local ox, oy = value[1], value[2]
                local vx = math.floor(ox / 32)
                local vy = math.floor(oy / 32)
                local exists = false

                for _, drop in ipairs(drops) do
                    local dx = math.floor(drop:getPosX() / 32)
                    local dy = math.floor(drop:getPosY() / 32)
                    if dy == vy and (dx == vx or dx == vx - 1 or dx == vx + 1) then
                        exists = true
                        break
                    end
                end

                if not exists then
                    value[3] = true
                end
            end
        end

        local allFound = true
        for _, v in pairs(list) do
            if not v[3] then allFound = false break end
        end

        if allFound then
          for _, pl in ipairs(world:getPlayers()) do
            SendNotifSuccess(pl)
            end
        end
    end)
  end
end)

onAutoSaveRequest(function()
    saveDataToServer("winterfest_event", data_pack)
end)