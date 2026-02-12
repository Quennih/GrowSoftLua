
print("Xvent See")

local data = loadDataFromServer("xvent_nperma") or {}
data.everyone_temp = data.everyone_temp or 0

local webhook_discord = "Webhook_URL" -- set to nil if you not need this
local offsetCoin = -10 -- make mutipleEvent x11 price changeToPwl 11pwl -> 1pwl start
local pricePerGems = 1000000 -- pricePerBoost in Gems
local changeToPWL = 10 -- change to pwl after multipleEvent x10, set to 0 if you want make currency only pwl
local durationInSecond = 3600 -- Multiple Event Duration

local function getTemp()
    local expire = data.temp or 0
    local now = os.time()
    local remain = expire - now
    if remain <= 0 then return 0 end
    return remain
end

local function setTemp()
    local now = os.time()
    if (data.temp or 0) > now then
        data.temp = data.temp + durationInSecond
    else
        data.temp = now + durationInSecond
    end
end

function formatNum(num)
    local formattedNum = tostring(num)
    formattedNum = formattedNum:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formattedNum = formattedNum:gsub("^,", "")
    return formattedNum
end

local function formatTime(t)
    if t <= 0 then return "Temporary Inactive" end
    local h = math.floor(t / durationInSecond)
    t = t % durationInSecond
    local m = math.floor(t / 60)
    local s = t % 60
    if h > 0 then return string.format("%d Hours %d Minutes %d Seconds Left", h, m, s) end
    if m > 0 then return string.format("%d Minutes %d Seconds Left", m, s) end
    return string.format("%d Seconds Left", s)
end

registerLuaCommand({
    command = "xvent",
    description = "See Multiple Events",
    roleRequired = 0
})

if data and (data.temp or 0) > os.time() and data.xvent ~= getGemEvent() then 
  setGemEvent(data.xvent)
  setXPEvent(data.xvent)
end

onPlayerCommandCallback(function(_, user, cmd)
    if cmd:lower() == "xvent" then

        local gemEvent = (data and (data.temp or 0) > os.time()) and data.xvent or getGemEvent()
        local xpEvent = (data and (data.temp or 0) > os.time()) and data.xvent or getXPEvent()

        local currencyMode = (gemEvent > changeToPWL or xpEvent > changeToPWL) and "PWL" or "GEMS"
        local cost = currencyMode == "GEMS" and (gemEvent*pricePerGems) or (gemEvent+offsetCoin)

        local remain = getTemp()
        local tempText = formatTime(remain)

        user:onDialogRequest(table.concat({
            "set_default_color|`o",
            "set_bg_color|43,34,74,200|",
            "set_border_color|112,86,191,255|",
            "add_label|big|Multiple Events|left|",
            "add_spacer|small|",
            string.format("add_label_with_icon|small|x%d|left|9438|", gemEvent),
            string.format("add_label_with_icon|small|x%d|left|1488|", xpEvent),
            string.format("add_smalltext|%s|", tempText),
            string.format("add_smalltext|Price: %s %s|", formatNum(cost), currencyMode),
            "add_spacer|small|",
            "add_button|boost|`2Boost|noflags|0|0|",
            "add_quick_exit|",
            "end_dialog|xevnt_dialog|||"
        }, "\n"))
        return true
    end
    return false
end)

onTick(function() 
  if getTemp() == 0 then
    if getGemEvent() > 1 then setGemEvent(1) end if getXPEvent() > 1 then setXPEvent(1) end
    end
end)

local temporary = {}

onPlayerDialogCallback(function(_, user, dialog)
    if dialog.dialog_name == "xevnt_dialog" and dialog.buttonClicked == "boost" then
        
        local gemEvent = (data and (data.temp or 0) > os.time()) and data.xvent or getGemEvent()
        local xpEvent = (data and (data.temp or 0) > os.time()) and data.xvent or getXPEvent()

        local currencyMode = (gemEvent > changeToPWL or xpEvent > changeToPWL) and "PWL" or "GEMS"

        if currencyMode == "GEMS" then
            local cost = pricePerGems * gemEvent
            if user:getGems() < cost then 
                user:onTalkBubble(user:getNetID(), "`4Not enough Gems!", 0)
                return true
            end
            user:removeGems(cost, 1, 1)
        else
            local cost = gemEvent+offsetCoin
            if user:getCoins() < cost then
                user:onTalkBubble(user:getNetID(), "`4Not enough PWL!", 0)
                return true
            end
            user:removeCoins(cost, 1)
        end

        setGemEvent(gemEvent + 1)
        setXPEvent(xpEvent + 1)
        data.xvent = ((data and data.xvent) or 1) + 1
        setTemp()
        
      local uid = user:getUserID()
      if not temporary[uid] or os.time() > temporary[uid] then temporary[uid] = os.time()+30 end
        user:onTalkBubble(user:getNetID(), "`2Boost Success!", 0)

        for _, pl in ipairs(getServerPlayers()) do
            pl:onConsoleMessage("`#** [BOOST] " .. user:getName() .. "`2 just boosted → x" .. getGemEvent())
            pl:playAudio("success.wav")
        end
        
        if webhook_discord then coroutine.wrap(function()
          local headers = {
              ["Content-Type"] = "application/json",
              ["User-Agent"] = "Mozilla/5.0"
          }
          
          local rawID = tostring(user:getDiscordID())
local playerDiscordID = rawID:match("%d+")
local mentionUser = playerDiscordID and ("<@" .. playerDiscordID .. ">") or user:getCleanName() -- Bug

          
          local jsonData = {
              content = player:getCleanName() .. " just boosted the server! " .. (sendEveryone and "@everyone" or ""),
              embeds = {{
                  title = "BOOST XVENT",
                  description = "Server Just Received a Boost <a:Bot:1358132757590577194>",
                  footer = { text = "play.growp.my.id" },
                  color = 65280,
                  fields = {
                      {
                          name = "Boost",
                          value = "`x" .. getGemEvent() .. "` <a:prices:1441681247435751464>"
                      }
                  }
              }}
          }
          
          http.post(webhook_discord, headers, json.encode(jsonData))

          end)() end

        return true
    end
    return false
end)

onAutoSaveRequest(function()
    saveDataToServer("xvent_nperma", data)
end)
