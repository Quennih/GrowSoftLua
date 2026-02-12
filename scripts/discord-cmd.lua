print("(Loaded) Discord Commands script for GrowSoft")

-- ===============================================
--          SCRIPT CONFIGURATION
-- ===============================================

-- TODO: Set your allowed Discord channel ID here. 
-- Commands from regular users will only be accepted from this channel.
local ALLOWED_CHANNEL_ID = "1422746058966044723"

-- ===============================================

-- Compatibility for different Lua versions
local unpack = table.unpack or unpack

local SAVE_KEY_CONFIG = "EASEL_DISCORD_CONFIG_V8"
local SAVE_KEY_BLACKJACK = "EASEL_DISCORD_BLACKJACK_V8"
local SAVE_KEY_HILO = "EASEL_DISCORD_HILO_V8"
local SAVE_KEY_GAME_STATS = "EASEL_DISCORD_GAME_STATS_V8"

local discord_config = {}
local blackjack_games = {}
local hilo_games = {}
local player_game_stats = {}

local MAX_INVENTORY = 396
local PlayerStats = {
    SmashedBlocks = 2,
    HarvestedTrees = 1,
    PlacedBlocks = 0
}

local GameConfig = {
    WIN_CHANCE_PERCENT = 30
}
local EmojiConfig = {
    wl = "<:WL:1409899558204342343>",
    dl = "<:DL:1409899641461542923>",
    bgl = "<:BGL:1409899713859162256>",
    bbgl = "<:BlackGemLock:1412510426561908886>",
    ggl = "<:easellock:1412510865722179684>"
}

local SupporterTiers = {
    { name = "Supporter", cost = 35 },
    { name = "Super Supporter", cost = 100 }
}

local PlayerSubscriptions = {
    TYPE_SUPPORTER = 0,
    TYPE_SUPER_SUPPORTER = 1
}

local Roles = {
    ROLE_NONE = 0, ROLE_VIP = 1, ROLE_SUPER_VIP = 2, ROLE_MODERATOR = 3, ROLE_ADMIN = 4,
    ROLE_COMMUNITY_MANAGER = 5, ROLE_CREATOR = 7, ROLE_GOD = 8, DEVELOPER = 51
}

local RoleNames = {
    [0] = "Player", [1] = "VIP", [2] = "Super VIP", [3] = "Moderator",
    [4] = "Admin", [5] = "Ultra-Admin", [7] = "Builder", [8] = "CO-Own", [51] = "Owner"
}

local LockIDs = {
    wl = 242,
    dl = 1796,
    bgl = 7188,
    bbgl = 20628,
    ggl = 25212
}

local LockValues = {
    ggl = 100000000,
    bbgl = 1000000,
    bgl = 10000,
    dl = 100,
    wl = 1
}

local SERVER_TOKEN_ID = 20234

local function saveAllData()
    saveDataToServer(SAVE_KEY_CONFIG, discord_config)
    saveDataToServer(SAVE_KEY_BLACKJACK, blackjack_games)
    saveDataToServer(SAVE_KEY_HILO, hilo_games)
    saveDataToServer(SAVE_KEY_GAME_STATS, player_game_stats)
end

local function loadAllData()
    local loadedConfig = loadDataFromServer(SAVE_KEY_CONFIG)
    discord_config = (loadedConfig and type(loadedConfig) == "table") and loadedConfig or {}
    discord_config.daily_game_limit = discord_config.daily_game_limit or 10
    discord_config.max_bet_wl = discord_config.max_bet_wl or 10000

    local loaded_bj = loadDataFromServer(SAVE_KEY_BLACKJACK)
    blackjack_games = (loaded_bj and type(loaded_bj) == "table") and loaded_bj or {}

    local loaded_hilo = loadDataFromServer(SAVE_KEY_HILO)
    hilo_games = (loaded_hilo and type(loaded_hilo) == "table") and loaded_hilo or {}

    local loaded_stats = loadDataFromServer(SAVE_KEY_GAME_STATS)
    player_game_stats = (loaded_stats and type(loaded_stats) == "table") and loaded_stats or {}
end

function startsWith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

function formatNum(num)
    if not num then return "0" end
    local formattedNum = tostring(num)
    formattedNum = formattedNum:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formattedNum = formattedNum:gsub("^,", "")
    return formattedNum
end

function getPlayerBalanceInWLs(player)
    local total = 0
    total = total + (player:getItemAmount(LockIDs.wl) * LockValues.wl)
    total = total + (player:getItemAmount(LockIDs.dl) * LockValues.dl)
    total = total + (player:getItemAmount(LockIDs.bgl) * LockValues.bgl)
    total = total + (player:getItemAmount(LockIDs.bbgl) * LockValues.bbgl)
    total = total + (player:getItemAmount(LockIDs.ggl) * LockValues.ggl)
    return total
end

function calculateLockCombination(totalWLs)
    local combo = { ggl = 0, bbgl = 0, bgl = 0, dl = 0, wl = 0 }
    local remaining = totalWLs
    combo.ggl = math.floor(remaining / LockValues.ggl); remaining = remaining % LockValues.ggl
    combo.bbgl = math.floor(remaining / LockValues.bbgl); remaining = remaining % LockValues.bbgl
    combo.bgl = math.floor(remaining / LockValues.bgl); remaining = remaining % LockValues.bgl
    combo.dl = math.floor(remaining / LockValues.dl); remaining = remaining % LockValues.dl
    combo.wl = remaining
    return combo
end

function executeLockPayment(player, costInWLs)
    local currentBalance = getPlayerBalanceInWLs(player)
    if currentBalance < costInWLs then return false end

    local newBalance = currentBalance - costInWLs
    
    local currentLocks = {
        wl = player:getItemAmount(LockIDs.wl), dl = player:getItemAmount(LockIDs.dl),
        bgl = player:getItemAmount(LockIDs.bgl), bbgl = player:getItemAmount(LockIDs.bbgl),
        ggl = player:getItemAmount(LockIDs.ggl)
    }
    
    local targetLocks = calculateLockCombination(newBalance)
    
    local wl_diff = targetLocks.wl - currentLocks.wl
    if wl_diff ~= 0 then player:changeItem(LockIDs.wl, wl_diff, 0) end
    
    local dl_diff = targetLocks.dl - currentLocks.dl
    if dl_diff ~= 0 then player:changeItem(LockIDs.dl, dl_diff, 0) end
    
    local bgl_diff = targetLocks.bgl - currentLocks.bgl
    if bgl_diff ~= 0 then player:changeItem(LockIDs.bgl, bgl_diff, 0) end
    
    local bbgl_diff = targetLocks.bbgl - currentLocks.bbgl
    if bbgl_diff ~= 0 then player:changeItem(LockIDs.bbgl, bbgl_diff, 0) end
    
    local ggl_diff = targetLocks.ggl - currentLocks.ggl
    if ggl_diff ~= 0 then player:changeItem(LockIDs.ggl, ggl_diff, 0) end
    
    return true
end

function addLocks(player, winningsInWLs)
    local currentBalance = getPlayerBalanceInWLs(player)
    local newBalance = currentBalance + winningsInWLs

    local currentLocks = {
        wl = player:getItemAmount(LockIDs.wl), dl = player:getItemAmount(LockIDs.dl),
        bgl = player:getItemAmount(LockIDs.bgl), bbgl = player:getItemAmount(LockIDs.bbgl),
        ggl = player:getItemAmount(LockIDs.ggl)
    }

    local targetLocks = calculateLockCombination(newBalance)

    local wl_diff = targetLocks.wl - currentLocks.wl
    if wl_diff ~= 0 then player:changeItem(LockIDs.wl, wl_diff, 0) end
    
    local dl_diff = targetLocks.dl - currentLocks.dl
    if dl_diff ~= 0 then player:changeItem(LockIDs.dl, dl_diff, 0) end
    
    local bgl_diff = targetLocks.bgl - currentLocks.bgl
    if bgl_diff ~= 0 then player:changeItem(LockIDs.bgl, bgl_diff, 0) end
    
    local bbgl_diff = targetLocks.bbgl - currentLocks.bbgl
    if bbgl_diff ~= 0 then player:changeItem(LockIDs.bbgl, bbgl_diff, 0) end
    
    local ggl_diff = targetLocks.ggl - currentLocks.ggl
    if ggl_diff ~= 0 then player:changeItem(LockIDs.ggl, ggl_diff, 0) end
end

function checkAndTrackGameLimit(player)
    local uid = player:getUserID()
    local stats = player_game_stats[uid] or { games_played_today = 0, last_played_day_start = 0 }

    local time_now = os.time()
    local gmt7_offset = 7 * 60 * 60
    local seconds_into_day = (time_now + gmt7_offset) % 86400
    local start_of_current_day = time_now - (time_now % 86400) - gmt7_offset + (math.floor((time_now + gmt7_offset) / 86400) * 86400)

    if stats.last_played_day_start ~= start_of_current_day then
        stats.games_played_today = 0
        stats.last_played_day_start = start_of_current_day
    end

    if stats.games_played_today >= discord_config.daily_game_limit then
        return false, string.format("You have reached your daily game limit of **%d** plays. Please wait until tomorrow.", discord_config.daily_game_limit)
    end

    stats.games_played_today = stats.games_played_today + 1
    player_game_stats[uid] = stats
    return true
end

local function handleBet(player, amountStr, currencyStr)
    local canPlay, limitMessage = checkAndTrackGameLimit(player)
    if not canPlay then return false, limitMessage end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        return false, "Invalid bet amount. Please enter a positive number."
    end

    local currency = currencyStr and currencyStr:lower()
    if not LockIDs[currency] then
        return false, "Invalid currency. Use `wl`, `dl`, `bgl`, `bbgl`, or `ggl`."
    end
    
    local betInWLs = amount * LockValues[currency]
    
    if betInWLs > discord_config.max_bet_wl then
        local maxBetInBGL = discord_config.max_bet_wl / LockValues.bgl
        return false, string.format("Your bet exceeds the maximum limit of **%s BGL** %s.", formatNum(maxBetInBGL), EmojiConfig.bgl)
    end
    
    if not executeLockPayment(player, betInWLs) then
        return false, "You don't have enough locks to place that bet."
    end

    return true, {amount, currency, getItem(LockIDs[currency]):getName(), EmojiConfig[currency], betInWLs}
end

local CardDeck = {
    Suits = {"♠", "♥", "♦", "♣"},
    Ranks = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"},
    Values = {["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, ["8"]=8, ["9"]=9, ["10"]=10, ["J"]=10, ["Q"]=10, ["K"]=10, ["A"]=11}
}

function createDeck()
    local deck = {}
    for _, suit in ipairs(CardDeck.Suits) do
        for _, rank in ipairs(CardDeck.Ranks) do
            table.insert(deck, {rank = rank, suit = suit})
        end
    end
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

function getHandValue(hand)
    local value = 0
    local numAces = 0
    for _, card in ipairs(hand) do
        value = value + CardDeck.Values[card.rank]
        if card.rank == "A" then
            numAces = numAces + 1
        end
    end
    while value > 21 and numAces > 0 do
        value = value - 10
        numAces = numAces - 1
    end
    return value
end

function handToString(hand)
    local str = ""
    for _, card in ipairs(hand) do
        str = str .. "[" .. card.rank .. card.suit .. "]"
    end
    return str
end

onDiscordMessageCreateCallback(function(event)
    if event:isBot() then return end

    local content = event:getContent()
    local player = event:getPlayer()
    local channelID = event:getChannelID()

    if channelID ~= ALLOWED_CHANNEL_ID then
        if not (player and player:hasRole(Roles.DEVELOPER)) then
            return 
        end
    end

    if content == "-help" then
        local helpMessage = "**Available EaselTopia Discord Commands**\n\n" ..
                            "**-help**\n`Shows this command list.`\n\n" ..
                            "**-online**\n`Shows the server's online player count and list.`\n\n" ..
                            "**-myinfo**\n`Checks your linked in-game character's info and balance.`\n\n" ..
                            "**-playerinfo <PlayerName>**\n`Displays public info and balance for any player.`\n\n" ..
                            "**-mybalance**\n`Checks your in-game lock balance.`\n\n" ..
                            "**Game Commands**\n\n" ..
                            "**-bj <amount> <currency>**\n`Starts a game of Blackjack. Currency can be wl, dl, bgl, etc.`\n\n" ..
                            "**-hl <amount> <currency>**\n`Starts a game of Higher or Lower.`\n\n" ..
                            "**-sm <amount> <currency>**\n`Starts a game of Spaceman.`\n\n" ..
                            "**Crypto Exchange**\n\n" ..
                            "**-market**\n`View all current cryptocurrency prices.`\n\n" ..
                            "**-portfolio**\n`Check your personal crypto holdings and their value.`\n\n" ..
                            "**-buy <amount> <symbol>**\n`Buy a cryptocurrency (e.g., -buy 10 BTC).`\n\n" ..
                            "**-sell <amount> <symbol>**\n`Sell a cryptocurrency (e.g., -sell 5 ETH).`"


        if player and player:hasRole(Roles.DEVELOPER) then
            helpMessage = helpMessage .. "\n\n**Admin Commands**\n\n" ..
                          "**-give <Player> <ItemID> <Qty>**\n`Gives an item to a player.`\n\n" ..
                          "**-take <Player> <ItemID> <Qty>**\n`Takes an item from a player.`\n\n" ..
                          "**-bc <message>**\n`Sends a broadcast message to all players in-game.`\n\n" ..
                          "**-addpwl <Player> <Qty>**\n`Adds server tokens to a player.`\n\n" ..
                          "**-removepwl <Player> <Qty>**\n`Removes server tokens from a player.`\n\n" ..
                          "**-givegems <Player> <Qty>**\n`Gives gems to a player.`\n\n" ..
                          "**-addslots <Player> <Qty>**\n`Adds inventory slots to a player.`\n\n" ..
                          "**-setafslots <Player> <Qty>**\n`Sets a player's total autofarm slots.`\n\n" ..
                          "**-setsupporter <Player> <Tier>**\n`Sets a player's supporter tier (e.g., Supporter).`\n\n" ..
                          "**-setgamelimit <limit>**\n`Sets the daily gameplay limit for all players.`\n\n" ..
                          "**-setmaxbet <amount> <currency>**\n`Sets the maximum bet for all games.`\n\n" ..
                          "**-rs**\n`Reloads all in-game Lua scripts.`"
        end

        event:reply(helpMessage)
        return
    end

    local isGameCommand = startsWith(content, "-bj") or startsWith(content, "-hl") or startsWith(content, "-sm") or content == "-hit" or content == "-stand" or content == "-higher" or content == "-lower"
    if isGameCommand then
        if not player then
            event:reply("You must link your Discord account to your in-game account to play games.")
            return
        end

        if startsWith(content, "-sm ") then
            local amountStr, currencyStr = content:match("^-sm%s+(%d+)%s+(%w+)")
            if not amountStr or not currencyStr then event:reply("Usage: `-sm <amount> <currency>`"); return end

            local success, message = handleBet(player, amountStr, currencyStr)
            if not success then event:reply(message); return end
            local betAmount, currency, currencyName, currencyEmoji, betInWLs = unpack(message)
            
            local roll = math.random(1, 100)
            if roll <= GameConfig.WIN_CHANCE_PERCENT then
                local multiplier = 1.5 + (math.random() * 3.5)
                local winningsInWLs = math.floor(betInWLs * multiplier)
                addLocks(player, winningsInWLs)
                event:reply(string.format("🚀 Spaceman launched! The multiplier climbed to **%.2fx** and you cashed out! You won the equivalent of **%s WLs**!", multiplier, formatNum(winningsInWLs)))
            else
                local crashPoint = 1.0 + (math.random() * 0.5)
                event:reply(string.format("🚀 Spaceman launched... but it crashed at **%.2fx**! You lost your bet of **%s** %s.", crashPoint, formatNum(betAmount), currency:upper()))
            end
            saveAllData()
            return
        end

        if startsWith(content, "-hl ") then
            local uid = player:getUserID()
            if hilo_games[uid] then event:reply("You are already in a Higher or Lower game! Type `-higher` or `-lower`."); return end

            local amountStr, currencyStr = content:match("^-hl%s+(%d+)%s+(%w+)")
            if not amountStr or not currencyStr then event:reply("Usage: `-hl <amount> <currency>`"); return end

            local success, message = handleBet(player, amountStr, currencyStr)
            if not success then event:reply(message); return end
            local betAmount, currency, currencyName, currencyEmoji, betInWLs = unpack(message)

            local deck = createDeck()
            local currentCard = table.remove(deck, 1)

            hilo_games[uid] = { betAmount = betAmount, currency = currency, currencyEmoji = currencyEmoji, betInWLs = betInWLs, currentCard = currentCard }
            saveAllData()

            event:reply("A game of Higher or Lower has started! Your card is **" .. handToString({currentCard}) .. "**. Will the next card be higher or lower? (`-higher` or `-lower`)")
            return
        end

        if content == "-higher" or content == "-lower" then
            local uid = player:getUserID()
            local game = hilo_games[uid]
            if not game then event:reply("You are not in a Higher or Lower game. Start one with `-hl <amount> <currency>`."); return end

            local deck = createDeck()
            local nextCard = table.remove(deck, 1)
            
            while nextCard.rank == game.currentCard.rank do
                nextCard = table.remove(deck, 1)
            end
            
            local playerWins = false
            local roll = math.random(1, 100)
            if roll <= GameConfig.WIN_CHANCE_PERCENT then
                playerWins = true
            end

            local resultText = "The next card was **" .. handToString({nextCard}) .. "**. "
            if playerWins then
                local winningsInWLs = game.betInWLs * 2
                addLocks(player, winningsInWLs)
                resultText = resultText .. string.format("You win! You received the equivalent of **%s WLs**.", formatNum(winningsInWLs))
            else
                resultText = resultText .. string.format("You lose! You lost your bet of **%s** %s.", formatNum(game.betAmount), game.currency:upper())
            end

            event:reply(resultText)
            hilo_games[uid] = nil
            saveAllData()
            return
        end

        if startsWith(content, "-bj ") then
            local uid = player:getUserID()
            if blackjack_games[uid] then event:reply("You are already in a Blackjack game! Type `-hit` or `-stand`."); return end

            local amountStr, currencyStr = content:match("^-bj%s+(%d+)%s+(%w+)")
            if not amountStr or not currencyStr then event:reply("Usage: `-bj <amount> <currency>`"); return end

            local success, message = handleBet(player, amountStr, currencyStr)
            if not success then event:reply(message); return end
            local betAmount, currency, currencyName, currencyEmoji, betInWLs = unpack(message)

            local deck = createDeck()
            local playerHand = {table.remove(deck, 1), table.remove(deck, 1)}
            local dealerHand = {table.remove(deck, 1), {rank="?", suit="?"}}

            blackjack_games[uid] = { betAmount = betAmount, currency = currency, currencyEmoji = currencyEmoji, betInWLs = betInWLs, deck = deck, playerHand = playerHand, dealerHand = dealerHand }
            
            local replyMsg = string.format("Blackjack game started for **%s** %s.\n\nYour hand: %s (**%d**)\nDealer's hand: %s\n\nType `-hit` or `-stand`.", formatNum(betAmount), currency:upper(), handToString(playerHand), getHandValue(playerHand), handToString(dealerHand))
            
            if getHandValue(playerHand) == 21 then
                event:reply(replyMsg)
                content = "-stand"
            else
                event:reply(replyMsg)
                saveAllData()
                return
            end
        end

        if content == "-hit" or content == "-stand" then
            local uid = player:getUserID()
            local game = blackjack_games[uid]
            if not game then event:reply("You are not in a Blackjack game. Start one with `-bj <amount> <currency>`."); return end

            if content == "-hit" then
                table.insert(game.playerHand, table.remove(game.deck, 1))
                local playerValue = getHandValue(game.playerHand)
                
                if playerValue > 21 then
                    event:reply(string.format("Your hand: %s (**%d**)\nYou busted! You lost your bet of **%s** %s.", handToString(game.playerHand), playerValue, formatNum(game.betAmount), game.currency:upper()))
                    blackjack_games[uid] = nil
                    saveAllData()
                    return
                else
                    local replyMsg = string.format("Your hand: %s (**%d**)\nDealer's hand: %s\n\nType `-hit` or `-stand`.", handToString(game.playerHand), playerValue, handToString(game.dealerHand))
                    event:reply(replyMsg)
                end
                return
            end
            
            if content == "-stand" then
                game.dealerHand[2] = table.remove(game.deck, 1)
                local dealerValue = getHandValue(game.dealerHand)
                
                local roll = math.random(1, 100)
                local forceDealerWin = (roll > GameConfig.WIN_CHANCE_PERCENT)
                
                while dealerValue < 17 or (forceDealerWin and dealerValue <= getHandValue(game.playerHand) and dealerValue < 21) do
                    table.insert(game.dealerHand, table.remove(game.deck, 1))
                    dealerValue = getHandValue(game.dealerHand)
                end

                local playerValue = getHandValue(game.playerHand)
                local resultMsg = string.format("You stand with **%d**.\nYour hand: %s\nDealer's hand: %s (**%d**)\n\n", playerValue, handToString(game.playerHand), handToString(game.dealerHand), dealerValue)
                
                local playerWins = false
                if playerValue > 21 then
                    playerWins = false
                elseif dealerValue > 21 then
                    playerWins = true
                elseif playerValue > dealerValue then
                    playerWins = true
                else
                    playerWins = false
                end

                if playerWins then
                    local winningsInWLs = game.betInWLs * 2
                    addLocks(player, winningsInWLs)
                    resultMsg = resultMsg .. string.format("You win! You received the equivalent of **%s WLs**.", formatNum(winningsInWLs))
                else
                    resultMsg = resultMsg .. string.format("Dealer wins! You lost your bet of **%s** %s.", formatNum(game.betAmount), game.currency:upper())
                end
                
                event:reply(resultMsg)
                blackjack_games[uid] = nil
                saveAllData()
                return
            end
        end
    end

    if startsWith(content, "-online") then
        local onlinePlayers = getServerPlayers()
        local onlineCount = #onlinePlayers
        if onlineCount == 0 then event:reply("There are currently **0** players online."); return end
        local playerList = {}
        for _, p in ipairs(onlinePlayers) do table.insert(playerList, p:getCleanName() .. "(" .. p:getWorldName() .. ")") end
        local playerString = table.concat(playerList, ", ")
        local fullMessage = "There are currently **" .. onlineCount .. "** players online: " .. playerString
        if #fullMessage > 1900 then fullMessage = "There are currently **" .. onlineCount .. "** players online: " .. fullMessage:sub(1, 1900) .. "..." end
        event:reply(fullMessage)
        return
    end

    local function buildPlayerInfo(target)
        local roleName = "Player"
        for id, name in pairs(RoleNames) do if target:hasRole(id) then roleName = name end end

        local status, world
        if target:isOnline() then
            status = "Online"
            
            -- FIX: Get the "live" player object to safely call getWorldName()
            local livePlayer = nil
            for _, p in ipairs(getServerPlayers()) do
                if p:getUserID() == target:getUserID() then
                    livePlayer = p
                    break
                end
            end

            if livePlayer then
                 world = livePlayer:getWorldName()
            else
                 -- This is a fallback in case the player logs off between checks
                 world = "Unknown"
            end
        else
            status = "Offline"
            world = "N/A"
        end

        local supporterStatus = "None"
        if target:getSubscription(PlayerSubscriptions.TYPE_SUPER_SUPPORTER) ~= nil then
            supporterStatus = "Super Supporter"
        elseif target:getSubscription(PlayerSubscriptions.TYPE_SUPPORTER) ~= nil then
            supporterStatus = "Supporter"
        end

        local playtimeHours = string.format("%.2f", target:getPlaytime() / 3600)
        local tokenName = getItem(SERVER_TOKEN_ID):getName()
        
        local info = {
            {"Level", target:getLevel()},
            {"Status", status},
            {"Role", roleName},
            {"Current World", world},
            {"Supporter Tier", supporterStatus},
            {"Inventory", target:getInventorySize() .. "/" .. MAX_INVENTORY},
        }

        local stats = {
            {"Playtime", playtimeHours .. " hours"},
            {"Account Age", target:getAccountCreationDateStr() .. " days"},
            {"Blocks Smashed", formatNum(target:getStats(PlayerStats.SmashedBlocks))},
            {"Trees Harvested", formatNum(target:getStats(PlayerStats.HarvestedTrees))},
            {"Blocks Placed", formatNum(target:getStats(PlayerStats.PlacedBlocks))},
        }

        local balance = {
            {"WLs", formatNum(target:getItemAmount(LockIDs.wl))},
            {"DLs", formatNum(target:getItemAmount(LockIDs.dl))},
            {"BGLs", formatNum(target:getItemAmount(LockIDs.bgl))},
            {"BBGLs", formatNum(target:getItemAmount(LockIDs.bbgl))},
            {"GGLs", formatNum(target:getItemAmount(LockIDs.ggl))},
            {"Gems", formatNum(target:getGems())},
            {tokenName, formatNum(target:getCoins())},
        }

        local function createTable(title, data)
            local lines = {"| " .. title .. string.rep(" ", 20 - #title) .. "|                     |"}
            table.insert(lines, "|---------------------|---------------------|")
            for _, row in ipairs(data) do
                local key = tostring(row[1])
                local value = tostring(row[2])
                table.insert(lines, "| " .. key .. string.rep(" ", 20 - #key) .. "| " .. value .. string.rep(" ", 20 - #value) .. "|")
            end
            return table.concat(lines, "\n")
        end

        local message = "```markdown\n" ..
                        "# Player Info: " .. target:getCleanName() .. "\n\n" ..
                        createTable("CHARACTER INFO", info) .. "\n\n" ..
                        createTable("STATISTICS", stats) .. "\n\n" ..
                        createTable("BALANCE", balance) .. "\n" ..
                        "```"
        return message
    end

    if content == "-myinfo" then
        local target = event:getPlayer()
        if not target then event:reply("You do not have an in-game account linked to your Discord account."); return end
        event:reply(buildPlayerInfo(target))
        return
    end

    if startsWith(content, "-playerinfo ") then
        local targetName = content:match("^-playerinfo%s+(%S+)")
        if not targetName then event:reply("Usage: `-playerinfo <PlayerName>`"); return end

        local commandUser = event:getPlayer()
        if commandUser and commandUser:getCleanName():lower() == targetName:lower() then
            event:reply("Please use `-myinfo` to check your own stats.")
            return
        end

        local foundPlayers = getPlayerByName(targetName)
        if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]
        
        event:reply(buildPlayerInfo(target))
        return
    end

    if startsWith(content, "-mybalance") then
        local player = event:getPlayer()
        if not player then event:reply("You do not have an in-game account linked to your Discord account."); return end
        local balanceMessage = string.format("Hello, **%s**! Here is your lock balance:\n%s **World Locks:** %s\n%s **Diamond Locks:** %s\n%s **Blue Gem Locks:** %s\n%s **Black Gem Locks:** %s\n%s **Golden Gem Locks:** %s",
                                player:getCleanName(),
                                EmojiConfig.wl, formatNum(player:getItemAmount(LockIDs.wl)),
                                EmojiConfig.dl, formatNum(player:getItemAmount(LockIDs.dl)),
                                EmojiConfig.bgl, formatNum(player:getItemAmount(LockIDs.bgl)),
                                EmojiConfig.bbgl, formatNum(player:getItemAmount(LockIDs.bbgl)),
                                EmojiConfig.ggl, formatNum(player:getItemAmount(LockIDs.ggl)))
        event:reply(balanceMessage)
        return
    end

    local commandUser = event:getPlayer()
    if not commandUser or not commandUser:hasRole(Roles.DEVELOPER) then return end

    if startsWith(content, "-setgamelimit ") then
        local limitStr = content:match("^-setgamelimit%s+(%d+)")
        if not limitStr then event:reply("Usage: `-setgamelimit <new_limit>`"); return end
        local newLimit = tonumber(limitStr)
        if not newLimit or newLimit < 0 then event:reply("Invalid limit. Must be a non-negative number."); return end
        
        discord_config.daily_game_limit = newLimit
        saveAllData()
        event:reply(string.format("Success! The daily game limit has been updated to **%d** plays per player.", newLimit))
        return
    end

    if startsWith(content, "-setmaxbet ") then
        local amountStr, currencyStr = content:match("^-setmaxbet%s+(%d+)%s+(%w+)")
        if not amountStr or not currencyStr then event:reply("Usage: `-setmaxbet <amount> <currency>`"); return end

        local amount = tonumber(amountStr)
        local currency = currencyStr:lower()
        if not amount or amount <= 0 then event:reply("Invalid amount."); return end
        if not LockValues[currency] then event:reply("Invalid currency."); return end
        
        local newMaxBetInWL = amount * LockValues[currency]
        discord_config.max_bet_wl = newMaxBetInWL
        saveAllData()
        event:reply(string.format("Success! The maximum bet has been updated to the equivalent of **%s WLs**.", formatNum(newMaxBetInWL)))
        return
    end

    if startsWith(content, "-give ") then
        local targetName, itemID_str, amount_str = content:match("^-give%s+(%S+)%s+(%d+)%s+(%d+)")
        if not targetName or not itemID_str or not amount_str then
            event:reply("Usage: `-give <PlayerName> <ItemID> <Quantity>`")
            return
        end

        local itemID = tonumber(itemID_str)
        local amount = tonumber(amount_str)

        if not itemID or not amount or amount <= 0 then
            event:reply("Invalid ItemID or quantity.")
            return
        end

        local foundPlayers = getPlayerByName(targetName)
        if not foundPlayers or #foundPlayers == 0 then
            event:reply("Player `" .. targetName .. "` not found.")
            return
        end
        local target = foundPlayers[1]

        if target:getBackpackUsedSize() >= target:getInventorySize() then
            event:reply("`" .. target:getCleanName() .. "` has a full inventory.")
            return
        end

        local item = getItem(itemID)
        if not item then
            event:reply("Invalid ItemID: `" .. itemID .. "`.")
            return
        end

        target:changeItem(itemID, amount, 0)
        event:reply("Success! Gave **" .. formatNum(amount) .. "x " .. item:getName() .. "** to **" .. target:getCleanName() .. "**.")
        
        if target:isOnline() then
            target:onConsoleMessage("An admin gave you `2" .. formatNum(amount) .. "x " .. item:getName() .. "`o!")
            target:playAudio("success.wav")
        end
        return
    end

    if startsWith(content, "-take ") then
        local targetName, itemID_str, amount_str = content:match("^-take%s+(%S+)%s+(%d+)%s+(%d+)")
        if not targetName or not itemID_str or not amount_str then
            event:reply("Usage: `-take <PlayerName> <ItemID> <Quantity>`")
            return
        end

        local itemID = tonumber(itemID_str)
        local amount = tonumber(amount_str)

        if not itemID or not amount or amount <= 0 then
            event:reply("Invalid ItemID or quantity.")
            return
        end

        local foundPlayers = getPlayerByName(targetName)
        if not foundPlayers or #foundPlayers == 0 then
            event:reply("Player `" .. targetName .. "` not found.")
            return
        end
        local target = foundPlayers[1]

        local item = getItem(itemID)
        if not item then
            event:reply("Invalid ItemID: `" .. itemID .. "`.")
            return
        end

        target:changeItem(itemID, -amount, 0)
        event:reply("Success! Took **" .. formatNum(amount) .. "x " .. item:getName() .. "** from **" .. target:getCleanName() .. "**.")
        
        if target:isOnline() then
            target:onConsoleMessage("An admin took `4" .. formatNum(amount) .. "x " .. item:getName() .. "`o from your inventory!")
            target:playAudio("loser.wav")
        end
        return
    end

    if startsWith(content, "-bc ") then
        local message = content:sub(5)
        if message == "" then event:reply("Usage: -bc <message>"); return end
        local broadcastMessage = "`w** [`4Discord Admin`w] ** from (``" .. commandUser:getCleanName() .. "`w)``: " .. message
        for _, p in ipairs(getServerPlayers()) do p:onConsoleMessage(broadcastMessage); p:playAudio("msg.wav"); end
        event:reply("Your message has been broadcasted in-game.")
        return
    end

    if startsWith(content, "-addpwl ") then
        local targetName, amountStr = content:match("^-addpwl%s+(%S+)%s+(%d+)")
        if not targetName or not amountStr then event:reply("Usage: `-addpwl <PlayerName> <Quantity>`"); return end
        local amount = tonumber(amountStr)
        if not amount or amount <= 0 then event:reply("Invalid quantity. Must be a positive number."); return end
        local foundPlayers = getPlayerByName(targetName); if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]; target:addCoins(amount)
        local tokenName = getItem(SERVER_TOKEN_ID):getName()
        event:reply("Success! Gave **" .. formatNum(amount) .. "** " .. tokenName .. " to **" .. target:getCleanName() .. "**.")
        if target:isOnline() then target:onConsoleMessage("An admin gave you `2" .. formatNum(amount) .. " `o" .. tokenName .. "!"); target:playAudio("success.wav") end
        return
    end

    if startsWith(content, "-removepwl ") then
        local targetName, amountStr = content:match("^-removepwl%s+(%S+)%s+(%d+)")
        if not targetName or not amountStr then event:reply("Usage: `-removepwl <PlayerName> <Quantity>`"); return end
        local amount = tonumber(amountStr); if not amount or amount <= 0 then event:reply("Invalid quantity. Must be a positive number."); return end
        local foundPlayers = getPlayerByName(targetName); if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]; target:removeCoins(amount, 0)
        local tokenName = getItem(SERVER_TOKEN_ID):getName()
        event:reply("Success! Removed **" .. formatNum(amount) .. "** " .. tokenName .. " from **" .. target:getCleanName() .. "**.")
        if target:isOnline() then target:onConsoleMessage("An admin removed `4" .. formatNum(amount) .. " `o" .. tokenName .. " from your balance!"); target:playAudio("loser.wav") end
        return
    end

    if startsWith(content, "-givegems ") then
        local targetName, amountStr = content:match("^-givegems%s+(%S+)%s+(%d+)")
        if not targetName or not amountStr then event:reply("Usage: `-givegems <PlayerName> <Quantity>`"); return end
        local amount = tonumber(amountStr); if not amount or amount <= 0 then event:reply("Invalid quantity. Must be a positive number."); return end
        local foundPlayers = getPlayerByName(targetName); if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]; target:addGems(amount, 0, 1)
        event:reply("Success! Gave **" .. formatNum(amount) .. "** Gems to **" .. target:getCleanName() .. "**.")
        if target:isOnline() then target:onConsoleMessage("An admin gave you `2" .. formatNum(amount) .. " Gems!"); target:playAudio("success.wav") end
        return
    end

    if startsWith(content, "-addslots ") then
        local targetName, amountStr = content:match("^-addslots%s+(%S+)%s+(%d+)")
        if not targetName or not amountStr then event:reply("Usage: `-addslots <PlayerName> <Quantity>`"); return end
        local amount = tonumber(amountStr); if not amount or amount <= 0 then event:reply("Invalid quantity. Must be a positive number."); return end
        local foundPlayers = getPlayerByName(targetName); if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]

        if not target:isOnline() then
            event:reply("Player `" .. targetName .. "` must be online to receive inventory slots.")
            return
        end

        if target:getInventorySize() >= MAX_INVENTORY then event:reply(target:getCleanName() .. " already has the maximum inventory size."); return end
        if target:getInventorySize() + amount > MAX_INVENTORY then amount = MAX_INVENTORY - target:getInventorySize() end
        target:upgradeInventorySpace(amount)
        event:reply("Success! Gave **" .. formatNum(amount) .. "** inventory slots to **" .. target:getCleanName() .. "**. They now have " .. target:getInventorySize() .. " slots.")
        target:onConsoleMessage("An admin increased your inventory space by `2" .. formatNum(amount) .. "`o slots!"); target:playAudio("success.wav")
        return
    end

    if startsWith(content, "-setafslots ") then
        local targetName, amountStr = content:match("^-setafslots%s+(%S+)%s+(%d+)")
        if not targetName or not amountStr then event:reply("Usage: `-setafslots <PlayerName> <Quantity>`"); return end
        local amount = tonumber(amountStr); if not amount or amount < 0 then event:reply("Invalid quantity. Must be a non-negative number."); return end
        local foundPlayers = getPlayerByName(targetName); if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]

        if not target:isOnline() then
            event:reply("Player `" .. targetName .. "` must be online to manage their autofarm.")
            return
        end

        local autofarm = target:getAutofarm()
        if not autofarm then event:reply("Could not access this player's autofarm data."); return end
        autofarm:setSlots(amount)
        event:reply("Success! Set **" .. target:getCleanName() .. "**'s autofarm slots to **" .. formatNum(amount) .. "**.")
        target:onConsoleMessage("An admin has set your autofarm slots to `2" .. formatNum(amount) .. "`o!"); target:playAudio("success.wav")
        return
    end

    if startsWith(content, "-setsupporter ") then
        local targetName, tierName = content:match("^-setsupporter%s+(%S+)%s+(.+)")
        if not targetName or not tierName then event:reply("Usage: `-setsupporter <PlayerName> <TierName>`"); return end
        local foundPlayers = getPlayerByName(targetName); if not foundPlayers or #foundPlayers == 0 then event:reply("Player `" .. targetName .. "` not found."); return end
        local target = foundPlayers[1]; local targetTier = nil
        for _, tier in ipairs(SupporterTiers) do
            if tier.name:lower() == tierName:lower() then targetTier = tier; break end
        end
        if not targetTier then
            local availableTiers = {}
            for _, tier in ipairs(SupporterTiers) do table.insert(availableTiers, tier.name) end
            event:reply("Invalid tier. Available tiers: " .. table.concat(availableTiers, ", ")); return
        end
        target:addCoins(targetTier.cost)
        target:removeCoins(targetTier.cost, 1)
        event:reply("Success! Set **" .. target:getCleanName() .. "**'s tier to **" .. targetTier.name .. "**.")
        if target:isOnline() then target:sendVariant({"OnAddNotification", "", "`wYou received the `2" .. targetTier.name .. "`w Tier!", "audio/success.wav", 0}) end
        return
    end

    if content == "-rs" then
        reloadScripts()
        event:reply("Success! All in-game Lua scripts have been reloaded.")
        return
    end
end)

onAutoSaveRequest(function()
    saveAllData()
end)

loadAllData()
