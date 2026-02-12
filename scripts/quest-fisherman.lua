print("Loading custom NPC quest script...")

--[[DON'T TOUCH; SERVER DATA!]]
local KEY_STRING = "FISHERMAN_QUEST_KEY_" .. getServerID()
local FISHERMAN_QUEST = FISHERMAN_QUEST or {}
local DAILY_LIMIT = 5
local SECONDS_IN_DAY = 86400

--[[Modular stuff here, editing these will reflect on the whole system.]]
local gemPenalty = 150
local completeIcon = 6292
local incompleteIcon = 25338
local fishermanId = 25018

--[[DON'T TOUCH; SERVER DATA!]]
local function loadQuestsData()
    local data = loadDataFromServer(KEY_STRING)

    if data and type(data) == "table" then
        FISHERMAN_QUEST = data
        --print("[Custom NPC Quest Script] Quest data loaded.")
    else
        FISHERMAN_QUEST = {}
        --print("[Custom NPC Quest Script] No quest data found.")
    end
end

--[[DON'T TOUCH; SERVER DATA!]]
local function saveQuestData()
    saveDataToServer(KEY_STRING, FISHERMAN_QUEST)
    --print("[Custom NPC Quest Script] Quest data saved.")
end

--[[Function that formalize numbers, for e.g. '1000' will become '1,000' (with commas).]]
local function formatNumberWithCommas(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

--[[Add/Modify/Remove quests here. DM if you need help understanding.]]
local quests = {
    {
        id = "catch_fish",
        description =
        "`oI want you to Catch `w{catch_fish_goal} `ofish. You can keep what you caught.",
        objectives = {
            { type = "catch_fish", goalRange = { 3, 20 } }
        },
        prizes = {
            gems  = { min = 250, max = 750 },
            items = {
                { id = 3014,  amountRange = { 5, 25 } }, -- Salmon
                { id = 25020, amountRange = { 1, 1 } }    -- FishToken for every quest
            }
        }
    },
    {
        id = "catch_lbs",
        description =
        "`oI want you to catch `w{catchlb_goal} `ofish. You can keep what you caught.",
        objectives = {
            { type = "catchlb", goalRange = { 100, 1000 } }
        },
        prizes = {
            gems  = { min = 500, max = 1500 },
            items = {
                { id = 3014,  amountRange = { 10, 50 } }, -- Salmon
                { id = 25020, amountRange = { 1, 1 } }   -- FishToken for every quest
            }
        }
    },
    {
        id = "harvest_tackle",
        description =
        "`oI want you to harvest `w{harvest_tackle_goal}`o Tackle Boxes. You can keep what you harvested.",
        objectives = {
            { type = "harvest_tackle", goalRange = { 20, 200 } },
        },
        prizes = {
            gems = { min = 500, max = 1000 },
            items = {
                { id = 3044,  amountRange = { 1, 3 } }, -- Tackle
                { id = 25020, amountRange = { 1, 1 } }    -- FishToken for every quest
            }
        }
    },
    {
        id = "trainfish",
        description =
        "`oI want you to train `w{trainfish_goal} `ofish. You can keep the fishes you've trained. They don't seem to like me much.",
        objectives = {
            { type = "trainfish", goalRange = { 1, 5 } },

        },
        prizes = {
            gems = { min = 2500, max = 7500 },
            items = {
                { id = 5532,  amountRange = { 1, 10 } }, --Medicine
                { id = 5534,  amountRange = { 1, 10 } }, -- Reviver
                { id = 5536,  amountRange = { 1, 10 } }, -- Flakes
                { id = 5530,  amountRange = { 1, 2 } }, -- Training Port
                { id = 3004,  amountRange = { 10, 30 } }, -- Fish Tank
                { id = 25020, amountRange = { 2, 4 } } -- FishToken for every quest
            }
        }
    },
    {
        id = "breakfishtank",
        description =
        "`oI want you to break `w{break_this_goal} `o Blocks. You can keep the gems and seeds from it.",
        objectives = {
            { type = "break_this", id = 3004, goalRange = { 20, 400 } }

        },
        prizes = {
            gems = { min = 250, max = 750 },
            items = {
                { id = 3004,  amountRange = { 10, 30 } }, -- Fish Tank
                { id = 3002,  amountRange = { 1, 3 } }, -- Fish Tank Port
                { id = 25020, amountRange = { 1, 1 } } -- FishToken for every quest
            }
        }
    },
    {
        id = "placefishtank",
        description =
        "`oI want you to place `w{place_this_goal}`o Blocks. I don't care where, just place 'em.",
        objectives = {
            { type = "place_this", id = 3004, goalRange = { 20, 400 } }

        },
        prizes = {
            gems = { min = 250, max = 750 },
            items = {
                { id = 3004,  amountRange = { 10, 30 } }, -- Fish Tank
                { id = 3002,  amountRange = { 1, 3 } }, -- Fish Tank Port
                { id = 25020, amountRange = { 1, 1 } } -- FishToken for every quest
            }
        }
    }
}

--[[Progress text for each QUEST. IMPORTANT: when you add/remove a quest, make sure to add/remove it here too!
DM me if you need help understanding.]]
local PROGRESS_FORMATS = {
    catch_fish = function(p, g)
        return string.format("`oCatch `w%s `ofish. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    catchlb = function(p, g)
        return string.format("`oCatch `w%s lbs. `oof fish. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    place_this = function(p, g, obj)
        return string.format("`oPlace `w%s `o%s. (%s/%s)", formatNumberWithCommas(g), obj.blockName or "Blocks",
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    harvest_tackle = function(p, g)
        return string.format("`oHarvest `w%s `oTackle Boxes. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    trainfish = function(p, g)
        return string.format("`oTrain `w%s `ofish. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    earnxp = function(p, g)
        return string.format("`oEarn `w%s `oXP. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    place_blocks = function(p, g)
        return string.format("`oPlace `w%s `oRandom Blocks. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    place_rarity = function(p, g)
        return string.format("`oPlace blocks worth `w%s rarity`o. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    break_this = function(p, g, obj)
        return string.format("`oBreak `w%s `o%s. (%s/%s)", formatNumberWithCommas(g),
            obj.blockName or "Blocks", formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    break_blocks = function(p, g)
        return string.format("`oBreak `w%s `oRandom Blocks. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    break_rarity = function(p, g)
        return string.format("`oBreak blocks worth `w%s `orarity. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    harvest_this = function(p, g, obj)
        return string.format("`oHarvest `w%s `o%s Trees. (%s/%s)", formatNumberWithCommas(g),
            obj.blockName or "Trees", formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    harvest_seeds = function(p, g)
        return string.format("`oHarvest `w%s `oRandom Trees. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end,
    harvest_rarity = function(p, g)
        return string.format("`oHarvest trees worth `w%s `orarity. (%s/%s)", formatNumberWithCommas(g),
            formatNumberWithCommas(p), formatNumberWithCommas(g))
    end
}

--[[Progress text for each TASK. IMPORTANT: when you add/remove a quest, make sure to add/remove it here too!
DM me if you need help understanding.]]
local TASK_FORMATS = {
    catch_fish = function(goal) return "Catch " .. formatNumberWithCommas(goal) .. " fish" end,
    catchlb = function(goal) return "Catch " .. formatNumberWithCommas(goal) .. " lbs. of fish" end,
    place_this = function(goal, obj)
        return "Place " .. formatNumberWithCommas(goal) .. " " ..
            (obj.blockName or "blocks")
    end,
    harvest_tackle = function(goal) return "Harvest " .. formatNumberWithCommas(goal) .. " Tackle Boxes" end,
    trainfish = function(goal) return "Train " .. formatNumberWithCommas(goal) .. " fish" end,
    earnxp = function(goal) return "Earn " .. formatNumberWithCommas(goal) .. " XP" end,
    place_blocks = function(goal) return "Place " .. formatNumberWithCommas(goal) .. " Random Blocks" end,
    place_rarity = function(goal) return "Place blocks worth " .. formatNumberWithCommas(goal) .. " rarity" end,
    break_this = function(goal, obj)
        return "Break " ..
            formatNumberWithCommas(goal) .. " " .. (obj.blockName or "blocks")
    end,
    break_blocks = function(goal) return "Break " .. formatNumberWithCommas(goal) .. " Random Blocks" end,
    break_rarity = function(goal) return "Break blocks worth " .. formatNumberWithCommas(goal) .. " rarity" end,
    harvest_this = function(goal, obj)
        return "Harvest " ..
            formatNumberWithCommas(goal) .. " " .. (obj.blockName or "blocks")
    end,
    harvest_seeds = function(goal) return "Harvest " .. formatNumberWithCommas(goal) .. " Random Trees" end,
    harvest_rarity = function(goal) return "Harvest trees worth " .. formatNumberWithCommas(goal) .. " rarity" end
}

-- Tambahkan ini di atas, ganti fungsi getDailyResetRemaining:
local function getDailyResetRemaining(record)
    local now = os.time()
    local resetAt = (record.lastReset or now) + SECONDS_IN_DAY
    local remaining = resetAt - now
    if remaining < 0 then remaining = 0 end

    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--[[This will show up when the player doesn't have an active quest and wrenches the NPC.]]
local function buildFishGetDialog(player)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId] or {}
    local completedCount = record.completedCount or 0
    local now = os.time()

    record.lastReset = record.lastReset or now
    record.dailyCount = record.dailyCount or 0

    if now - record.lastReset >= SECONDS_IN_DAY then
        record.dailyCount = 0
        record.lastReset = now
        FISHERMAN_QUEST[userId] = record
        saveQuestData()
    end

    local DAILY_LIMIT = 5
    local dailyLeft = math.max(DAILY_LIMIT - record.dailyCount, 0)
    local text = "add_smalltext|`oDaily Quests Left: " .. dailyLeft .. "/" .. DAILY_LIMIT .. "``|left|\n"

    if dailyLeft <= 0 then
        local resetTime = getDailyResetRemaining(record)
        text = text .. "add_smalltext|`4Refresh at: " .. resetTime .. " UTC``|left|\n"
    end

    return
        "set_default_color|`o\n" ..
        "add_label_with_icon|big|`wFisherman``|left|" .. fishermanId .. "|\n" ..
        "add_spacer|small|\n" ..
        "add_textbox|`oGreetings, fellow fishermen! I am THE Fisherman! Should you wish to embark on a random fishing quest, simply click continue below.``|left|\n" ..
        "add_spacer|small|\n" ..
        "add_button|fishContinueQuest|`9Give me a Quest!|noflags|0|0|\n" ..
        "add_smalltext|`oQuests Completed: " .. formatNumberWithCommas(completedCount) .. "``|left|\n" ..
        text ..
        "end_dialog|fishGetQuest|No Thanks||"
end

--[[This will show up when the player clicks on 'continue' when they don't have an active quest after wrenching the NPC.]]
local function buildFishDisclaimerDialog()
    return
        "set_default_color|`o\n" ..
        "add_label_with_icon|big|`wFisherman``|left|" .. fishermanId .. "|\n" ..
        "add_spacer|small|\n" ..
        "add_smalltext|`oJust to let you know, you may turn in your quests at any Fisherman you have access to (we're in a union).``|left|\n" ..
        "add_spacer|small|\n" ..
        "add_smalltext|`oWait, there's one last thing you should know before you begin. You can quit your quest at anytime, but it will cost you gems, but be aware if you do, you'll lose all progress on this quest.``|left|\n" ..
        "add_spacer|small|\n" ..
        "add_textbox|`oSo... now that you've received the official disclaimer, are you prepared to embark on my quest?``|left|\n" ..
        "add_spacer|small|\n" ..
        "add_button|fishStartQuest|`9Alright, Give me the Quest!|noflags|0|0|\n" ..
        "end_dialog|fishDisclaimerDialog|No thanks||"
end

--[[Actual quest dialog, it shows the quest's description, player's progress, etc.]]
local function buildFishActiveQuestDialog(questData)
    local dialog =
        "set_default_color|`o\n" ..
        "add_label_with_icon|big|`wFisherman's Quest``|left|" .. fishermanId .. "|\n" ..
        "add_spacer|small|\n" ..
        "add_smalltext|`o" .. questData.description .. "``|left|\n" ..
        "add_spacer|small|\n" ..
        "add_textbox|`9Tasks:``|left|\n"

    local allComplete = true
    for objectiveType, obj in pairs(questData.objectives) do
        --[[Change these two variables to your liking.
        completeIcon shows when the player completes the task,
        while incompleteIcon shows when the task is not yet completed.]]
        local complete = obj.progress >= obj.goal
        local icon = complete and completeIcon or incompleteIcon
        local format = PROGRESS_FORMATS[objectiveType] or "%d/%d"

        local format = PROGRESS_FORMATS[objectiveType]
        if format then
            local text
            if obj.progress >= obj.goal then
                if type(format) == "function" then
                    text = format(obj.goal, obj.goal, obj):gsub("%(%s*.+%s*/%s*.+%)", "`2(OK!)")
                else
                    text = "`2(OK!)"
                end
            else
                text = format(obj.progress, obj.goal, obj)
            end
            dialog = dialog .. string.format("add_label_with_icon|small|`w%s``|left|%d|\n", text, icon)
        else
            local fallbackText = obj.progress >= obj.goal and "`2(OK!)" or string.format("%s/%s", obj.progress, obj.goal)
            dialog = dialog .. string.format("add_label_with_icon|small|`w%s``|left|%d|\n", fallbackText, icon)
        end
        if not complete then allComplete = false end
    end

    dialog = dialog .. "add_spacer|small|\n"
    dialog = dialog .. "add_textbox|`9Rewards:``|left|\n"

    if questData.prizes then
        local prizes = questData.prizes
        if prizes.gems then
            dialog = dialog ..
                string.format("add_label_with_icon|small|`w%s `oGems|left|9438|\n", formatNumberWithCommas(prizes.gems))
        end
        if prizes.items then
            for _, prize in ipairs(prizes.items) do
                local itemName = getItem(prize.id):getName() or ("Item ID: " .. prize.id)
                local icon = prize.id
                dialog = dialog ..
                    string.format("add_label_with_icon|small|`w%s `o%s|left|%d|\n", formatNumberWithCommas(prize.amount),
                        itemName, icon)
            end
        end
    end

    dialog = dialog .. "add_spacer|small|\n"

    --[[Change what the buttons will show if you want.]]
    if allComplete then
        dialog = dialog .. "add_button|fishCompleteQuest|`oComplete Quest``|noflags|0|0|\n"
    else
        dialog = dialog .. "add_button|fishNotComplete|`oI will be back!``|noflags|0|0|\n"
    end

    dialog = dialog .. "add_button|fishCancelQuest|`oGive up``|noflags|0|0|\n"
    dialog = dialog .. "end_dialog|fishActiveQuestDialog|Goodbye!||"
    return dialog
end

--[[This will show up when the player tries to cancel the quest. Pretty much like a confirmation page.]]
local function buildFishEndQuestDialog()
    return
        "set_default_color|`o\n" ..
        "add_label_with_icon|big|`wAre you sure?``|left|6124|\n" ..
        "add_spacer|small|\n" ..
        "add_smalltext|`oGiving up your quest will cost `4" ..
        formatNumberWithCommas(gemPenalty) .. " gems`o, and your progress on it will be lost forever.``|left|\n" ..
        "add_spacer|small|\n" ..
        "add_button|fishEndQuest|`wGive up this Quest|noflags|0|0|\n" ..
        "end_dialog|fishEndQuestDialog|Nevermind||"
end

--[[This handles if a player wrenches on a wrenchable block.]]
onTileWrenchCallback(function(world, player, tile)
    --[[Replace the value of fishermanId to the wrenchable block/NPC you want.
    DM me if you want this to handle multiple different NPCs.]]
    if tile:getTileID() ~= fishermanId then return false end

    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local questData = record and record.currentQuest

    if questData then
        player:onDialogRequest(buildFishActiveQuestDialog(questData))
    else
        player:onDialogRequest(buildFishGetDialog(player))
    end
    return true
end)

--[[This handles if a player punches on the npc]]
onTilePunchCallback(function(world, player, tile)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local questData = record and record.currentQuest

    if tile:getTileID() ~= fishermanId then return false end
    if questData then
        player:onDialogRequest(buildFishActiveQuestDialog(questData))
    else
        player:onDialogRequest(buildFishGetDialog(player))
    end
    return false
end)

--[[This handles all the dialogs]]
onPlayerDialogCallback(function(world, player, data)
    local dialog = data["dialog_name"]
    local button = data["buttonClicked"]
    local userId = player:getUserID()

    if dialog ~= "fishGetQuest"
        and dialog ~= "fishActiveQuestDialog"
        and dialog ~= "fishDisclaimerDialog"
        and dialog ~= "fishEndQuestDialog"
    then
        return false
    end

    local playerData = FISHERMAN_QUEST[userId] or {}
    local completedCount = playerData.completedCount or 0
    local quest = playerData.currentQuest

    --[[If the player clicks on 'Continue']]
    if button == "fishContinueQuest" then
        player:onDialogRequest(buildFishDisclaimerDialog())
        --[[if the player clicks on 'Yes!']]
    elseif button == "fishStartQuest" then
        --[[Changing anything below this line might BREAK most of the code,
        unless if you've made the changes to other lines and functions as well.
        I recommend not changing.]]
        local now = os.time()
        local record = FISHERMAN_QUEST[userId] or {}
        record.completedCount = record.completedCount or 0
        record.dailyCount = record.dailyCount or 0
        record.lastReset = record.lastReset or now
        local base = quests[math.random(1, #quests)]
        local description = base.description
        local objectiveData = {}
        for _, obj in ipairs(base.objectives) do
            local goal = math.random(obj.goalRange[1], obj.goalRange[2])

            if obj.type == "place_this" or obj.type == "break_this" or obj.type == "harvest_this" then
                local blockId = obj.id
                local blockName = getItem(blockId):getName() or ("Item ID: " .. blockId)

                objectiveData[obj.type] = {
                    goal = goal,
                    progress = 0,
                    blockId = blockId,
                    blockName = blockName
                }

                description = description:gsub("{" .. obj.type .. "_goal}", formatNumberWithCommas(goal) ..
                    " " .. blockName)
            elseif obj.type == "place_blocks" or obj.type == "break_blocks" or obj.type == "place_rarity" or obj.type == "break_rarity" or obj.type == "harvest_seeds" or obj.type == "harvest_rarity" then
                objectiveData[obj.type] = {
                    goal = goal,
                    progress = 0
                }

                description = description:gsub("{" .. obj.type .. "_goal}", formatNumberWithCommas(goal))
            else
                objectiveData[obj.type] = {
                    goal = goal,
                    progress = 0
                }

                description = description:gsub("{" .. obj.type .. "_goal}", formatNumberWithCommas(goal))
            end
        end
    if now - record.lastReset >= SECONDS_IN_DAY then
        record.dailyCount = 0
        record.lastReset = now
    end

    if record.dailyCount >= DAILY_LIMIT then
        player:onTextOverlay("`4You've reached the daily quest limit (5/5). Try again tomorrow!``")
        return true
    end
        local computedPrizes = {}
        if base.prizes and base.prizes.gems then
            if type(base.prizes.gems) == "table" and base.prizes.gems.min and base.prizes.gems.max then
                computedPrizes.gems = math.random(base.prizes.gems.min, base.prizes.gems.max)
            else
                computedPrizes.gems = base.prizes.gems
            end
        end

        if base.prizes and base.prizes.items then
            computedPrizes.items = {}
            for _, prize in ipairs(base.prizes.items) do
                local amount = prize.amount
                if prize.amountRange then
                    amount = math.random(prize.amountRange[1], prize.amountRange[2])
                end
                table.insert(computedPrizes.items, {
                    id = prize.id,
                    amount = amount
                })
            end
        end

        record.currentQuest = {
            id = base.id,
            description = description,
            prizes = computedPrizes,
            objectives = objectiveData,
            notified = false
        }
        FISHERMAN_QUEST[userId] = record
        --[[Shows a text overlay to the player when they accept the quest.]]
        player:onTextOverlay("`9Good luck! You can do it!``")
        saveQuestData()
        player:onDialogRequest(buildFishActiveQuestDialog(FISHERMAN_QUEST[userId].currentQuest))
        --[[If the player clicks on 'Give up this quest']]
    elseif button == "fishCancelQuest" then
        player:onDialogRequest(buildFishEndQuestDialog())
        --[[If the player clicks on 'Yes!']]
    elseif button == "fishEndQuest" then
        --[[Checks if player doesn't have enough gems and only throw in an error]]
        if player:getGems() < gemPenalty then
            player:onTextOverlay("`4Oops! You don't have enough gems to cancel this quest.``")
            player:playAudio("bleep_fail.wav")
            return true
        end

        --[[If player has enough gems, reset their quest data and remove gems.]]
        local record = FISHERMAN_QUEST[userId] or {}
        record.currentQuest = nil
        FISHERMAN_QUEST[userId] = record
        saveQuestData()
        player:removeGems(gemPenalty, 0, 1)
        player:playAudio("loser.wav")
        --[[Shows a text overlay to the player when they cancelled the quest.]]
        player:onTextOverlay("`9Okay! You are no longer in this quest! Good luck!``")
        --[[If the player clicks on 'Complete Quest']]
    elseif button == "fishCompleteQuest" then
        local record = FISHERMAN_QUEST[userId]
        if not record then
            record = { completedCount = 0 }
        elseif not record.completedCount then
            record.completedCount = 0
        end
        local quest = record and record.currentQuest
        if not quest then return true end

        local allComplete = true
        for _, obj in pairs(quest.objectives) do
            if obj.progress < obj.goal then
                allComplete = false
                break
            end
        end

        --[[This block of code will reward the player when they click on 'Complete Quest'.
        I recommend not touching as it might BREAK the reward system.
        DM me if you need help on changing what the console will say when the player receives an item.]]
        if allComplete then
            local prizes = quest.prizes
            local rewardMessages = {}
            if prizes then
                if prizes.gems then
                    player:addGems(prizes.gems, 0, 1)
                    table.insert(rewardMessages, string.format("%s Gems", formatNumberWithCommas(prizes.gems)))
                end
                if prizes.items then
                    for _, item in ipairs(prizes.items) do
                        player:changeItem(item.id, item.amount, 0)
                        local itemName = getItem(item.id):getName() or ("Item ID: " .. item.id)
                        table.insert(rewardMessages,
                            string.format("%s %s", formatNumberWithCommas(item.amount), itemName))
                    end
                end
            end

            if #rewardMessages > 0 then
                local message
                if #rewardMessages == 1 then
                    message = rewardMessages[1]
                elseif #rewardMessages == 2 then
                    message = rewardMessages[1] .. "`o and `2" .. rewardMessages[2]
                else
                    message = table.concat(rewardMessages, "`o, `2", 1, #rewardMessages - 1)
                    message = message .. "`o, and `2" .. rewardMessages[#rewardMessages]
                end
                player:onConsoleMessage("`oYou received: `2" .. message .. "`o!``")
            end

            record.completedCount = record.completedCount + 1
            record.dailyCount = (record.dailyCount or 0) + 1
            record.currentQuest = nil
            FISHERMAN_QUEST[userId] = record

            print("[DEBUG]: Saving data for user:", userId, "Count:", record.completedCount)
            --[[DON'T TOUCH; SERVER DATA!]]
            saveQuestData()
            player:onTextOverlay("`9Quest Completed! You earned a prize!``")
            player:onConsoleMessage("`oYou have completed `w" ..
                formatNumberWithCommas(record.completedCount) .. " `oquests so far!``")
            player:playAudio("double_chance.wav")
        end
        --[[If the player clicks on 'I will be back!']]
    elseif button == "fishNotComplete" then
        --[[Shows a text overlay if the player clicks on 'I will be back!']]
        player:onTextOverlay("`9Good luck! You can do it!``")
    end
    return true
end)

--[[This function adds progress to the player's quests,
and auto saves data to server when a player adds progress to their quest.]]
local function addQuestProgress(player, type, amount)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest
    if not quest or not quest.objectives or not quest.objectives[type] then return end

    local obj = quest.objectives[type]
    local oldProgress = obj.progress
    obj.progress = math.min(obj.progress + amount, obj.goal)

    local formatter = TASK_FORMATS[type]
    local taskName = formatter and formatter(obj.goal, obj) or
        (type:gsub("_", " ") .. " " .. formatNumberWithCommas(obj.goal))

    local prevPercent = math.floor((oldProgress / obj.goal) * 100)
    local newPercent = math.floor((obj.progress / obj.goal) * 100)

    local milestones = { 25, 50, 75 }
    for _, milestone in ipairs(milestones) do
        if prevPercent < milestone and newPercent >= milestone then
            player:onConsoleMessage(string.format("`9Fisherman's Task: %s is `2%d%% complete!``", taskName, milestone))
        end
    end

    if oldProgress < obj.goal and obj.progress >= obj.goal then
        player:onConsoleMessage(string.format("`9Fisherman's Task: %s is `2completed!``", taskName))
    end

    saveQuestData()

    local allComplete = true
    for _, objective in pairs(quest.objectives) do
        if objective.progress < objective.goal then
            allComplete = false
            break
        end
    end

    if allComplete and not quest.notified then
        --[[Shows a text overlay to the player once all task in the quest is complete.]]
        player:onConsoleMessage("`9Quest Complete! Go talk to the Fisherman.``")
        player:onTalkBubble(player:getNetID(), "`9Quest Complete! Go talk to the Fisherman.``", 0)
        quest.notified = true
        saveQuestData()
    end
end

--[[Checks if a player catches a fish.]]
onPlayerCatchFishCallback(function(world, player, itemID, itemCount)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest

    if not quest then return false end
    addQuestProgress(player, "catch_fish", 1)
    addQuestProgress(player, "catchlb", itemCount)
    return true
end)

--[[Checks if a player harvests a provider]]
onPlayerProviderCallback(function(world, player, tile, itemID, itemCount)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest

    local tackleboxId = 3044
    if not quest then return false end
    if tile:getTileID() ~= tackleboxId then return false end
    addQuestProgress(player, "harvest_tackle", 1)
    return true
end)

--[[Checks if a player places a block]]
onTilePlaceCallback(function(world, player, tile, placingID)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest

    if quest then
        if quest.objectives["place_this"] then
            local expectedId = quest.objectives["place_this"].blockId
            if placingID == expectedId then
                addQuestProgress(player, "place_this", 1)
            end
        end
        if quest.objectives["place_blocks"] then
            addQuestProgress(player, "place_blocks", 1)
        end
        if quest.objectives["place_rarity"] then
            local rarity = getItem(placingID):getRarity() or 0
            if rarity > 0 then
                addQuestProgress(player, "place_rarity", rarity)
            end
        end
    end
end)

--[[Checks if a player trained a fish]]
onPlayerTrainFishCallback(function(world, player)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest

    if not quest then return false end
    addQuestProgress(player, "trainfish", 1)
    return true
end)

--[[Checks if a player earns xp]]
onPlayerXPCallback(function(world, player, amount)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest

    if not quest then return false end
    addQuestProgress(player, "earnxp", amount)
    return true
end)

--[[Checks if a player breaks a block]]
onTileBreakCallback(function(world, player, tile)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest
    local brokenId = tile:getTileID()

    if quest then
        if quest.objectives["break_this"] then
            local expectedId = quest.objectives["break_this"].blockId
            if brokenId == expectedId then
                addQuestProgress(player, "break_this", 1)
            end
        end
        if quest.objectives["break_blocks"] then
            addQuestProgress(player, "break_blocks", 1)
        end
        if quest.objectives["break_rarity"] then
            local rarity = getItem(brokenId):getRarity() or 0
            if rarity > 0 then
                addQuestProgress(player, "break_rarity", rarity)
            end
        end
    end
end)

--[[Checks if a player harvests a tree]]
onPlayerHarvestCallback(function(world, player, tile)
    local userId = player:getUserID()
    local record = FISHERMAN_QUEST[userId]
    local quest = record and record.currentQuest
    if not quest then return false end

    local harvestedId = tile:getTileID()

    if quest.objectives["harvest_this"] then
        local expectedId = quest.objectives["harvest_this"].blockId
        if harvestedId == expectedId then
            addQuestProgress(player, "harvest_this", 1)
        end
    end
    if quest.objectives["harvest_seeds"] then
        addQuestProgress(player, "harvest_seeds", 1)
    end
    if quest.objectives["harvest_rarity"] then
        local rarity = getItem(harvestedId):getRarity() or 0
        if rarity > 0 then
            addQuestProgress(player, "harvest_rarity", rarity)
        end
    end
end)

registerLuaCommand({
    command = "resetfishermanquestdata",
    roleRequired = 51,
    description = "Resets FISHERMAN_QUEST data."
})

onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)$")
    if command ~= "resetfishermanquestdata" then return false end
    if not player:hasRole(51) then return false end

    if next(FISHERMAN_QUEST) == nil then
        player:onConsoleMessage("`oData: `wFISHERMAN_QUEST `ois already empty! Nothing to reset here.``")
    else
        FISHERMAN_QUEST = {}
        saveQuestData()
        player:onConsoleMessage("`oData: `wFISHERMAN_QUEST `ohas been reset.``")
    end

    return true
end)

--[[Loads data everytime the script is reloaded or when server restarts.]]
loadQuestsData()
for userId, record in pairs(FISHERMAN_QUEST) do
    print("[DEBUG]: User", userId, "Completed:", record.completedCount or "nil")
end