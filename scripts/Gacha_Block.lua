-- Gacha script
print("(Loaded) Gacha script for GrowSoft")

local config = {
    
    triggerBlockID = 25120,
    
    minItemID = 2,
    maxItemID = 25120,
    forceEvenIDs = true,
    
    blockedNames = {"null_item", "test", "invalid"},
    maxRegenAttempts = 20,
    
    fallbackItemID = 25120,
    fallbackName = "Infinity Mystery Box",
    
    rareItemThreshold = 25000,
    dropMessage = "`2You found: `w{ITEM}`6 ({ID})",
    rareMessage = "`4(love) RARE! ",
    fallbackMessage = "`5(fallback)",
    
    -- Discord BOT Configuration
    -- Change your discord bot token
    discordBotToken = "YOUR_BOT_TOKEN_HERE", 
    -- Change your discord channel id
    discordChannelID = "YOUR_DISCORD_CHANNEL_ID_HERE", 
    
    -- Change your id emoji
    discordBoxEmoji = "<:MysteryChest:987654321098765432>",
}

math.randomseed(os.time())

-- FUNCTION TO SEND TO DISCORD USING BOT TOKEN
local function sendToDiscordBot(message) 
    -- Ensure Token and Channel ID are configured
    if not config.discordBotToken or config.discordChannelID == "" then
        print("Discord Bot Token or Channel ID is not configured. Skipping Discord notification.")
        return
    end

    local url = "https://discord.com/api/v10/channels/" .. config.discordChannelID .. "/messages"
    
    -- Prepare JSON data for Discord (content only)
    local payload = {
        content = message -- The message as plain content
    }
    
    -- Encode payload to JSON string
    -- CATATAN: Anda mungkin perlu mengaktifkan atau memastikan library JSON didukung oleh GrowSoft.
    -- Asumsi: Fungsi json.encode() tersedia.
    local json_payload = json.encode(payload)
    
    -- Required headers for Discord Bot API
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. config.discordBotToken
    }
    
    -- Send POST request
    -- Note: Ensure GrowSoft supports http.post with custom 'Authorization' header.
    -- Asumsi: Fungsi http.post() tersedia.
    http.post(url, headers, json_payload)
end

local function adjustID(id)
    if config.forceEvenIDs and id % 2 == 1 then
        return (id > config.minItemID) and (id - 1) or config.minItemID
    end
    return id
end

local function isAllowed(item)
    if not item then return false end
    local name = string.lower(item:getName() or "")
    for _, bad in ipairs(config.blockedNames) do
        if name:find(bad) then return false end
    end
    return true
end

local function generateDrop()
    local attempts, item, id = 0, nil, nil
    
    repeat
        attempts = attempts + 1
        id = adjustID(math.random(config.minItemID, config.maxItemID))
        item = getItem(id)
    until (item and isAllowed(item)) or attempts >= config.maxRegenAttempts
    
    if attempts >= config.maxRegenAttempts then
        return {
            id = config.fallbackItemID,
            name = config.fallbackName,
            isFallback = true
        }
    end
    
    return {
        id = id,
        name = item:getName(),
        isRare = (id >= config.rareItemThreshold)
    }
end

onTileBreakCallback(function(world, player, tile)
    if tile:getTileID() ~= config.triggerBlockID then return false end
    
    local drop = generateDrop()
    world:spawnItem(tile:getPosX(), tile:getPosY(), drop.id, 1)
    
    local msg = config.dropMessage
        :gsub("{ITEM}", drop.name)
        :gsub("{ID}", drop.id)
    
    if drop.isRare then
        msg = msg .. " " .. config.rareMessage
        player:onTalkBubble(player:getNetID(), "`6★ RARE DROP ★", 0)
    elseif drop.isFallback then
        msg = msg .. " " .. config.fallbackMessage
    end
    
    player:onConsoleMessage(msg, 0)

    -- SEND TO DISCORD USING BOT (Plain Text Message with Emojis)
    local playerName = player:getCleanName()
    local worldName = world:getName()
    -- Box name is taken from the broken item (triggerBlockID)
    local boxItem = getItem(config.triggerBlockID)
    local boxName = boxItem and boxItem:getName() or "Unknown Box"
    
    -- Determine the emoji prefix and status message
    local prefix, status
    if drop.isRare then
        prefix = "🎉 **RARE DROP!** 💎"
        status = "successfully obtained"
    else
        prefix = "🎁 Gacha Drop 🍀"
        status = "obtained"
    end

    -- NEW: Gabungkan emoji kustom dengan nama box
    local boxContext = string.format("%s %s", config.discordBoxEmoji, boxName)

    -- Final Discord message in English (menggunakan boxContext yang sudah ada ikon)
    local discordMessage = string.format("%s %s (%s) %s item: **%s** (ID: %d) in world **%s**!", 
        prefix, playerName, boxContext, status, drop.name, drop.id, worldName)

    sendToDiscordBot(discordMessage) -- Send the plain text message
    
    return true
end)