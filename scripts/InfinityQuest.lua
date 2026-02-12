print("(Loaded) Infinity Quest System - Gold Standard")

local DB_KEY_PLAYERS = "QUEST_PLAYER_DATA"
local DB_KEY_CONFIG  = "QUEST_GLOBAL_CONFIG"
local ROLE_ADMIN     = 51

local CONFIG = {
    deliver_targets = {2, 14, 12, 10, 822, 242, 1796, 4585, 3004, 880, 98},
    skip_cost = 5000,
    bgl_id = 7188,
    sidebar_icon = 1400,
    sidebar_action = "open_infinity_quest",
    season_duration = 604800
}

local QUEST_TEXTS = {
    SMASH    = "`oThe land is cluttered! Clear the area by smashing `w{goal} `oblocks of any kind. Get to work, hero!",
    DELIVER  = "`oEmergency! We need a shipment of `w{goal} {target} `odelivered immediately. Can you find them?",
    HARVEST  = "`oIt's harvest season and we are shorthanded. Go harvest `w{goal} `otrees on your farm.",
    FISH     = "`oThe village is hungry. Go to the ocean and catch `w{goal} `ofresh fish for tonight's feast!",
    PROVIDER = "`oOur stocks are running empty. Collect resources from `w{goal} `oproviders (Cow, Chicken, Science, etc).",
    XP       = "`oYou look a bit inexperienced. Go train yourself and earn `w{goal} `oXP. Come back when you are stronger!"
}

local insert = table.insert
local concat = table.concat
local floor = math.floor
local format = string.format
local tostr = tostring
local os_time = os.time

local playerDB = {} 
local configDB = {} 

local function loadDatabases()
    local pData = loadDataFromServer(DB_KEY_PLAYERS)
    playerDB = {}
    if type(pData) == "table" then 
        for k, v in pairs(pData) do
            playerDB[tostr(k)] = v 
        end
    end
    
    local cData = loadDataFromServer(DB_KEY_CONFIG)
    if type(cData) == "table" then configDB = cData else configDB = {} end
    
    if not configDB.settings then
        configDB.settings = {
            debug_mode = false,
            milestone_items = {7188, 242},
            prizes = {
                rank_1 = { {id=7188, count=2} },
                rank_2_10 = { {id=1796, count=50} },
                rank_11_20 = { {id=1796, count=5} },
                participation = 2
            }
        }
    end
    
    if not configDB.season_info then
        configDB.season_info = {
            id = 1,
            end_time = os_time() + CONFIG.season_duration,
            history = {} 
        }
    end
end

local function savePlayerDB() saveDataToServer(DB_KEY_PLAYERS, playerDB) end
local function saveConfigDB() saveDataToServer(DB_KEY_CONFIG, configDB) end

local function formatNum(n)
    if not n then return "0" end
    return tostr(n):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

local function getItemName(id)
    if not id or id == 0 then return "Any Block" end
    local item = getItem(id)
    return item and item:getName() or "Unknown Item"
end

local function getPlayerData(uid)
    local suid = tostr(uid)
    if not playerDB[suid] then
        playerDB[suid] = {
            name = "", level = 1, progress = 0, req_amount = 0, target_id = 0,
            quest_type = "NONE", hide_warning = false, auto_claim = false,
            season_points = 0, season_id_track = configDB.season_info.id
        }
    end
    return playerDB[suid]
end

local function getTimeRemaining()
    local left = configDB.season_info.end_time - os_time()
    if left < 0 then return "ENDING..." end
    local d = floor(left / 86400)
    local h = floor((left % 86400) / 3600)
    local m = floor((left % 3600) / 60)
    return format("%dd %02dh %02dm", d, h, m)
end

local function getQuestDescription(data)
    local template = QUEST_TEXTS[data.quest_type] or "Objective: Reach {goal}."
    local goalStr = formatNum(data.req_amount or 0)
    local targetStr = getItemName(data.target_id or 0)
    local desc = string.gsub(template, "{goal}", goalStr)
    desc = string.gsub(desc, "{target}", targetStr)
    return desc
end

local function updateSidebar(player)
    if not player then return end
    local uid = player:getUserID()
    local data = getPlayerData(uid)
    
    local sb = {
        active = true,
        buttonAction = CONFIG.sidebar_action,
        buttonTemplate = "BaseEventButton",
        counter = 0, counterMax = 0, itemIdIcon = CONFIG.sidebar_icon,
        name = "QuestButton", order = 40, rcssClass = "daily_challenge",
        text = "Quest: Lvl " .. data.level
    }
    
    if json and json.encode then
        player:sendVariant({"OnEventButtonDataSet", sb.name, 1, json.encode(sb)})
    end
end

local function resetSeason()
    local sInfo = configDB.season_info
    local oldID = sInfo.id
    local sorted = {}
    
    for uid, pData in pairs(playerDB) do
        if type(pData) == "table" and pData.season_points then
            if pData.season_points > 0 then
                insert(sorted, {uid = uid, pts = pData.season_points})
            end
        end
    end
    table.sort(sorted, function(a,b) return a.pts > b.pts end)
    
    local winners = {}
    for i = 1, 20 do if sorted[i] then winners[i] = sorted[i].uid end end
    
    sInfo.history[tostr(oldID)] = winners
    sInfo.id = oldID + 1
    sInfo.end_time = os_time() + CONFIG.season_duration
    
    saveConfigDB()
    
    local players = getServerPlayers()
    for _, p in pairs(players) do
        p:onTextOverlay("`2SEASON RESET!")
        updateSidebar(p)
    end
end

local function checkSeasonTimer()
    if os_time() >= configDB.season_info.end_time then resetSeason() end
end

local function generateQuest(player, data)
    local lvl = data.level
    local types = {"SMASH", "DELIVER", "HARVEST", "FISH", "PROVIDER", "XP"}
    local qType = types[math.random(1, #types)]
    local targetID = 0
    local baseAmount = 0
    
    if qType == "SMASH" then baseAmount = 30
    elseif qType == "DELIVER" then
        targetID = CONFIG.deliver_targets[math.random(1, #CONFIG.deliver_targets)]
        baseAmount = 20
    elseif qType == "HARVEST" then baseAmount = 20
    elseif qType == "FISH" then baseAmount = 5
    elseif qType == "PROVIDER" then baseAmount = 10
    elseif qType == "XP" then baseAmount = 2000
    end
    
    local amount = floor(baseAmount + (lvl * (baseAmount * 0.15)))
    
    data.quest_type = qType
    data.target_id = targetID
    data.req_amount = amount
    data.progress = 0 
    data.name = player:getName()
    
    savePlayerDB()
    updateSidebar(player)
    
    if data.auto_claim then player:onTextOverlay("New Quest: " .. qType) end
end

local showMainPanel, showAuditor, showPunishmentMenu
local showQuestMenu, showWarningMenu, showLeaderboard, showSettings, showAdminPanel, showMilestoneManager
local showAdminPrizeEditor, showAdminPrizeConfig, showPrizeInfo

showWarningMenu = function(player)
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wQuest Information``|left|1432|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_textbox|Every level has a milestone! You get special rewards at level 10, 20, 30, etc. Please check your inventory before claiming.|left|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_checkbox|chk_hide_warn|Don't show this again|0|\n")
    insert(d, "add_button|btn_confirm_warn|`wCONFIRM & ENTER|0|0|\n")
    insert(d, "add_quick_exit|\n")
    insert(d, "end_dialog|quest_warning|||\n")
    player:onDialogRequest(concat(d))
end

showSettings = function(player)
    local uid = player:getUserID()
    local data = getPlayerData(uid)
    local acState = data.auto_claim and 1 or 0
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wQuest Settings``|left|1432|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_checkbox|chk_autoclaim|Auto Claim Quest (Fast Mode)|"..acState.."|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_save_settings|`2Save & Apply|0|0|\n")
    insert(d, "add_button|btn_back_quest|Back|0|0|\n")
    insert(d, "end_dialog|quest_settings|||\n")
    player:onDialogRequest(concat(d))
end

showQuestMenu = function(player)
    local uid = player:getUserID()
    local data = getPlayerData(uid)
    if data.quest_type == "NONE" then generateQuest(player, data) end
    
    local visualProg = data.progress
    if data.quest_type == "DELIVER" then
        visualProg = player:getItemAmount(data.target_id)
        if visualProg > data.req_amount then visualProg = data.req_amount end
    end
    
    local req = data.req_amount
    local percent = floor((visualProg / req) * 100)
    
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wInfinity Quest (Lvl "..data.level..")``|left|3394|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_smalltext|"..getQuestDescription(data).."|left|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_label|small|`oProgress: "..formatNum(visualProg).." / "..formatNum(req).." ("..percent.."%)|left|\n")
    insert(d, "add_textured_progress_bar|interface/large/gui_event_bar.rttex|0|4||"..visualProg.."|"..req.."|relative|0.8|0.02|0.007|1000|64|0.007|bar_quest|\n")
    
    local canClaim = (data.quest_type=="DELIVER" and player:getItemAmount(data.target_id) >= req) or (data.quest_type~="DELIVER" and visualProg >= req)
    
    insert(d, "add_spacer|small|\n")
    if canClaim then
        insert(d, "add_button|btn_finish|`2[ CLAIM REWARD ]|0|0|\n")
    else
        insert(d, "add_button|no_btn|`8[ IN PROGRESS ]|0|0|\n")
    end
    
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_settings|`w[ SETTINGS ]|0|0|\n")
    insert(d, "add_button|btn_skip|`4Skip Quest ("..formatNum(CONFIG.skip_cost).." Gems)|0|0|\n")
    insert(d, "add_button|btn_open_lb|`9[ VIEW LEADERBOARD ]|0|0|\n")
    
    if player:hasRole(ROLE_ADMIN) then 
        insert(d, "add_custom_break|\n")
        insert(d, "add_button|btn_open_admin|`4[ ADMIN QUEST PANEL ]|0|0|\n") 
    end
    
    insert(d, "add_quick_exit|\n")
    insert(d, "end_dialog|inf_quest_menu|||\n")
    player:onDialogRequest(concat(d))
end

showPrizeInfo = function(player)
    local prizes = configDB.settings.prizes
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wSeason Prizes``|left|1432|\n")
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_label|small|`5Rank 1 (Champion):|left|\n")
    for _, p in ipairs(prizes.rank_1) do
        insert(d, format("add_label_with_icon|small|`w%d %s|left|%d|\n", p.count, getItemName(p.id), p.id))
    end
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_label|small|`2Rank 2 - 10:|left|\n")
    for _, p in ipairs(prizes.rank_2_10) do
        insert(d, format("add_label_with_icon|small|`w%d %s|left|%d|\n", p.count, getItemName(p.id), p.id))
    end
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_label|small|`9Rank 11 - 20:|left|\n")
    for _, p in ipairs(prizes.rank_11_20) do
        insert(d, format("add_label_with_icon|small|`w%d %s|left|%d|\n", p.count, getItemName(p.id), p.id))
    end
    insert(d, "add_spacer|small|\n")
    insert(d, format("add_label|small|`oParticipation: `2%d Coins `o(If score > 0)|left|\n", prizes.participation))
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_back_lb|Back|0|0|\n")
    insert(d, "end_dialog|quest_prize_info|||\n")
    player:onDialogRequest(concat(d))
end

showLeaderboard = function(player)
    local sorted = {}
    for uid, pData in pairs(playerDB) do
        if type(pData) == "table" and pData.season_points then
            insert(sorted, {name = pData.name or "Unknown", pts = pData.season_points, lvl = pData.level})
        end
    end
    table.sort(sorted, function(a,b) return a.pts > b.pts end)
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wSeason Leaderboard``|left|1366|\n")
    insert(d, format("add_label|small|`4Season Ends In: `2%s|left|\n", getTimeRemaining(configDB.season_info.end_time)))
    insert(d, "add_spacer|small|\n")
    for i = 1, 20 do
        if sorted[i] then 
            insert(d, format("add_label|small|`o%d. `2%s `o(Level: `b%d`o)|left|\n", i, sorted[i].name, sorted[i].lvl))
        else 
            insert(d, format("add_label|small|`o%d. -|left|\n", i))
        end
    end
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_view_prizes|`5[ SEASON PRIZES ]|0|0|\n")
    insert(d, "add_button|btn_back_quest|Back to Quest|0|0|\n")
    insert(d, "add_quick_exit|\n")
    insert(d, "end_dialog|quest_leaderboard|||\n")
    player:onDialogRequest(concat(d))
end

local adminSessions = {}

showAdminPrizeEditor = function(player, rankKey)
    local prizes = configDB.settings.prizes
    local targetList = prizes[rankKey]
    
    adminSessions[player:getUserID()] = adminSessions[player:getUserID()] or {}
    adminSessions[player:getUserID()].editingRank = rankKey
    
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wEditing "..rankKey.."``|left|32|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_label|small|`wCurrent Rewards (Tap to Delete):|left|\n")
    if #targetList == 0 then
        insert(d, "add_textbox|`oNo rewards set.|left|\n")
    else
        for i, reward in ipairs(targetList) do
            insert(d, format("add_button_with_icon|del_rwd_%s_%d|`w%s `o(x%d)|staticYellowFrame|%d|%d|\n", rankKey, i, getItemName(reward.id), reward.count, reward.id, reward.id))
        end
    end
    insert(d, "add_custom_break|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_label|small|`wAdd New Reward:|left|\n")
    insert(d, "add_custom_break|\n")
    insert(d, "add_item_picker|add_prize_picker|`2[+] Select Item to Add|Select item|\n")
    insert(d, "add_text_input|new_ct|Count:|1|5|numeric|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_admin_prizes|Back to Categories|0|0|\n")
    insert(d, "end_dialog|quest_edit_prizes|||\n")
    player:onDialogRequest(concat(d))
end

showAdminPrizeConfig = function(player)
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wPrize Configuration``|left|32|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_label|small|`oSelect rank category to edit:|left|\n")
    insert(d, "add_button|edit_rank_1|`5Edit Rank 1 (Champion)|0|0|\n")
    insert(d, "add_button|edit_rank_2_10|`2Edit Rank 2 - 10|0|0|\n")
    insert(d, "add_button|edit_rank_11_20|`9Edit Rank 11 - 20|0|0|\n")
    insert(d, "add_spacer|small|\n")
    local coins = configDB.settings.prizes.participation
    insert(d, "add_text_input|in_part_coins|Participation Coins:|"..coins.."|5|numeric|\n")
    insert(d, "add_button|save_part_coins|`2Save Coins|0|0|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_back_admin|Back to Panel|0|0|\n")
    insert(d, "end_dialog|quest_admin_prizes_main|||\n")
    player:onDialogRequest(concat(d))
end

showMilestoneManager = function(player)
    local gConf = configDB.settings
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wMilestone Manager``|left|1432|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_label|small|`wCurrent Milestone Items (Tap to Delete):|left|\n")
    for i, id in ipairs(gConf.milestone_items) do
        insert(d, format("add_button_with_icon|del_ms_%d|%s|staticYellowFrame|%d|%d|\n", i, getItemName(id), id, id))
    end
    insert(d, "add_spacer|small|\n")
    insert(d, "add_custom_break|\n")
    insert(d, "add_item_picker|ms_add_item|`2[+] Add New Item|Select item|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_back_admin|Back to Panel|0|0|\n")
    insert(d, "end_dialog|quest_milestone_mgr|||\n")
    player:onDialogRequest(concat(d))
end

showAdminPanel = function(player)
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`4Admin Quest Panel``|left|32|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, format("add_label|small|`wSeason Control (Ends: %s):|left|\n", getTimeRemaining(configDB.season_info.end_time)))
    insert(d, "add_button|btn_force_reset|`4[ FORCE RESET SEASON ]|0|0|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_edit_prizes|`5[ CONFIGURE SEASON PRIZES ]|0|0|\n")
    insert(d, "add_button|btn_open_milestone|`9[ MANAGE MILESTONE ITEMS ]|0|0|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_save_admin|`2[ SAVE SETTINGS ]|0|0|\n")
    insert(d, "add_button|btn_back_quest|Back to Quest|0|0|\n")
    insert(d, "end_dialog|quest_admin_panel|||\n")
    player:onDialogRequest(concat(d))
end

local function completeQuest(player, data)
    if data.quest_type == "DELIVER" then
        if player:getItemAmount(data.target_id) < data.req_amount then 
            if not data.auto_claim then player:onConsoleMessage("`4Insufficient Items.") end
            return false 
        end
        player:changeItem(data.target_id, -data.req_amount, 0)
    elseif data.quest_type ~= "DELIVER" then
        if data.progress < data.req_amount then return false end
    end

    if player:getInventorySize() - player:getBackpackUsedSize() < 2 then
        player:onConsoleMessage("`4Inventory Full! Auto-claim paused.")
        return false 
    end
    
    local rewardGems = floor(data.req_amount * 15)
    if data.quest_type == "XP" then rewardGems = floor(data.req_amount / 5) end
    player:addGems(rewardGems, 1, 1)
    
    local ptsEarned = floor(data.level * 10) 
    data.season_points = (data.season_points or 0) + ptsEarned
    
    local nextLvl = data.level + 1
    local isMilestone = (nextLvl % 10 == 0)
    
    if isMilestone then
        local gConf = configDB.settings
        local rewardID = 242 
        if #gConf.milestone_items > 0 then rewardID = gConf.milestone_items[math.random(1, #gConf.milestone_items)] end
        player:changeItem(rewardID, 1, 0)
        player:onConsoleMessage("`5[MILESTONE] `oReceived: 1x " .. getItemName(rewardID))
        player:playAudio("transform.wav")
    else
        local randomBlockID = math.random(5, 500) * 2
        player:changeItem(randomBlockID, 5, 0)
        player:onConsoleMessage("`2[Quest] `oFinished! Reward: 5 "..getItemName(randomBlockID))
        player:onTextOverlay("Item Received!")
    end
    
    if not data.auto_claim then player:playAudio("kaching.wav") end
    
    data.level = nextLvl
    generateQuest(player, data)
    return true
end

local function checkAutoClaim(player, data)
    if data.progress % 5 == 0 then savePlayerDB() end
    if data.progress >= data.req_amount then
        savePlayerDB()
        if data.auto_claim then completeQuest(player, data)
        else player:onConsoleMessage("`2[Quest] `wTarget Reached!"); player:playAudio("secret.wav") end
    end
end

local function checkSeasonClaim(player)
    local uid = player:getUserID()
    local pData = getPlayerData(uid)
    local currentSeasonID = configDB.season_info.id
    
    if pData.season_id_track < currentSeasonID then
        local oldID = pData.season_id_track
        local prizes = configDB.settings.prizes
        
        pData.level = 1
        pData.progress = 0
        pData.season_points = 0
        pData.season_id_track = currentSeasonID
        generateQuest(player, pData)
        savePlayerDB()
        updateSidebar(player)
        
        local history = configDB.season_info.history[tostring(oldID)]
        if not history then return false end
        
        local rank = 0
        for r, winnerUID in pairs(history) do if winnerUID == tostring(uid) then rank = r; break end end
        
        local d = {}
        insert(d, "set_default_color|`o\n")
        insert(d, "add_label_with_icon|big|`wSeason Results``|left|1432|\n")
        insert(d, "add_spacer|small|\n")
        
        local hasReward = false
        if rank == 1 then
            insert(d, "add_textbox|`5CHAMPION! `oRank 1!|left|\n")
            for _, p in ipairs(prizes.rank_1) do insert(d, format("add_label_with_icon|small|`wReward: %d %s|left|%d|\n", p.count, getItemName(p.id), p.id)) end
            insert(d, "add_button|claim_s_1|`2CLAIM PRIZE|0|0|\n")
            hasReward = true
        elseif rank >= 2 and rank <= 10 then
            insert(d, "add_textbox|`2Top 10! `oRank "..rank.."|left|\n")
            for _, p in ipairs(prizes.rank_2_10) do insert(d, format("add_label_with_icon|small|`wReward: %d %s|left|%d|\n", p.count, getItemName(p.id), p.id)) end
            insert(d, "add_button|claim_s_2|`2CLAIM PRIZE|0|0|\n")
            hasReward = true
        elseif rank >= 11 and rank <= 20 then
            insert(d, "add_textbox|`2Top 20! `oRank "..rank.."|left|\n")
            for _, p in ipairs(prizes.rank_11_20) do insert(d, format("add_label_with_icon|small|`wReward: %d %s|left|%d|\n", p.count, getItemName(p.id), p.id)) end
            insert(d, "add_button|claim_s_3|`2CLAIM PRIZE|0|0|\n")
            hasReward = true
        elseif pData.season_points > 0 then
            insert(d, "add_textbox|`oParticipation Reward.|left|\n")
            insert(d, format("add_label|small|`wReward: %d Coins|left|\n", prizes.participation))
            insert(d, "add_button|claim_s_part|`2CLAIM COINS|0|0|\n")
            hasReward = true
        end
        
        if hasReward then
            insert(d, "add_quick_exit|\n")
            insert(d, "end_dialog|season_claim|||\n")
            player:onDialogRequest(concat(d))
            return true
        end
    end
    return false
end

onPlayerActionCallback(function(world, player, data)
    local action = data.action or ""
    if action:find(CONFIG.sidebar_action) then
        checkSeasonTimer()
        if checkSeasonClaim(player) then return true end
        
        local pData = getPlayerData(player:getUserID())
        if pData.hide_warning then showQuestMenu(player) else showWarningMenu(player) end
        return true
    end
    return false
end)

registerLuaCommand({command = "quest", roleRequired = 0, description = "Open Quest"})
onPlayerCommandCallback(function(world, player, cmd) if cmd == "quest" then showQuestMenu(player); return true end return false end)

onPlayerDialogCallback(function(world, player, data)
    local dName = data.dialog_name
    local uid = player:getUserID()
    local pData = getPlayerData(uid)
    
    if dName == "quest_settings" then
        if data.buttonClicked == "btn_save_settings" then
            pData.auto_claim = (data.chk_autoclaim == "1")
            savePlayerDB()
            showQuestMenu(player)
        elseif data.buttonClicked == "btn_back_quest" then showQuestMenu(player) end
        return true
    end

    if dName == "season_claim" then
        local prizes = configDB.settings.prizes
        local function giveRewards(list) for _, r in ipairs(list) do player:changeItem(r.id, r.count, 0) end end
        if data.buttonClicked == "claim_s_1" then giveRewards(prizes.rank_1)
        elseif data.buttonClicked == "claim_s_2" then giveRewards(prizes.rank_2_10)
        elseif data.buttonClicked == "claim_s_3" then giveRewards(prizes.rank_11_20)
        elseif data.buttonClicked == "claim_s_part" then if player.setCoins then player:setCoins(player:getCoins() + prizes.participation) end end
        player:onConsoleMessage("`2Prize Claimed!")
        player:playAudio("kaching.wav")
        return true
    end
    
    if dName == "quest_warning" then
        if data.buttonClicked == "btn_confirm_warn" then if data.chk_hide_warn == "1" then pData.hide_warning = true; savePlayerDB() end; showQuestMenu(player) end
        return true
    end
    
    if dName == "inf_quest_menu" then
        if data.buttonClicked == "btn_settings" then showSettings(player)
        elseif data.buttonClicked == "btn_finish" then if completeQuest(player, pData) then showQuestMenu(player) end
        elseif data.buttonClicked == "btn_skip" then
            if player:getGems() >= CONFIG.skip_cost then player:removeGems(CONFIG.skip_cost, 1, 1); generateQuest(player, pData); showQuestMenu(player)
            else player:onConsoleMessage("`4Not enough gems!") end
        elseif data.buttonClicked == "btn_open_lb" then showLeaderboard(player)
        elseif data.buttonClicked == "btn_open_admin" then if player:hasRole(ROLE_ADMIN) then showAdminPanel(player) else player:onConsoleMessage("`4Access Denied.") end end
        return true
    end
    
    if dName == "quest_leaderboard" then 
        if data.buttonClicked == "btn_back_quest" then showQuestMenu(player) end 
        if data.buttonClicked == "btn_view_prizes" then showPrizeInfo(player) end
        return true 
    end
    
    if dName == "quest_prize_info" then if data.buttonClicked == "btn_back_lb" then showLeaderboard(player) end; return true end
    
    if dName == "quest_admin_panel" then
        if not player:hasRole(ROLE_ADMIN) then return true end
        if data.buttonClicked == "btn_edit_prizes" then showAdminPrizeConfig(player); return true end
        if data.buttonClicked == "btn_force_reset" then resetSeason(); player:onConsoleMessage("`2Reset Done!"); showAdminPanel(player); return true end
        if data.buttonClicked == "btn_open_milestone" then showMilestoneManager(player); return true end
        if data.buttonClicked == "btn_back_quest" then showQuestMenu(player); return true end
        if data.buttonClicked == "btn_save_admin" then
            configDB.settings.debug_mode = (data.chk_debug_mode == "1")
            saveConfigDB(); player:onConsoleMessage("`2Settings Saved."); showAdminPanel(player); return true
        end
        return true
    end
    
    if dName == "quest_milestone_mgr" then
        local gConf = configDB.settings
        if data.buttonClicked == "btn_back_admin" then showAdminPanel(player); return true end
        if data.ms_add_item then
            local id = tonumber(data.ms_add_item); if id then table.insert(gConf.milestone_items, id); saveConfigDB(); showMilestoneManager(player) end; return true
        end
        if data.buttonClicked:find("del_ms_") then
            local idx = tonumber(data.buttonClicked:match("del_ms_(%d+)"))
            table.remove(gConf.milestone_items, idx); saveConfigDB(); showMilestoneManager(player); return true
        end
        return true
    end
    
    if dName == "quest_admin_prizes_main" then
        if data.buttonClicked == "btn_back_admin" then showAdminPanel(player); return true end
        if data.buttonClicked == "save_part_coins" then
            local c = tonumber(data.in_part_coins); if c then configDB.settings.prizes.participation = c; saveConfigDB(); player:onConsoleMessage("`2Saved.") end; showAdminPrizeConfig(player); return true
        end
        if data.buttonClicked:find("edit_rank_") then
            local key = data.buttonClicked:gsub("edit_", "")
            showAdminPrizeEditor(player, key)
            return true
        end
    end
    
    if dName == "quest_edit_prizes" then
        local gConf = configDB.settings
        local rankKey = adminSessions[player:getUserID()] and adminSessions[player:getUserID()].editingRank
        if not rankKey then showAdminPrizeConfig(player); return true end
        
        if data.buttonClicked == "btn_admin_prizes" then showAdminPrizeConfig(player); return true end
        
        if data.add_prize_picker then
            local id = tonumber(data.add_prize_picker)
            local count = tonumber(data.new_ct) or 1
            if id then
                table.insert(gConf.prizes[rankKey], {id=id, count=count})
                saveConfigDB()
                showAdminPrizeEditor(player, rankKey)
            end
            return true
        end
        
        if data.buttonClicked:find("del_rwd_") then
            local idx = tonumber(data.buttonClicked:match("del_rwd_.+_(%d+)"))
            table.remove(gConf.prizes[rankKey], idx)
            saveConfigDB()
            showAdminPrizeEditor(player, rankKey)
            return true
        end
    end
    return false
end)

onTileBreakCallback(function(world, player, tile)
    local uid = player:getUserID(); local data = playerDB[tostring(uid)]
    if data and data.quest_type == "SMASH" and data.progress < data.req_amount then
        data.progress = data.progress + 1; checkAutoClaim(player, data)
    end
    return false
end)

if onPlayerHarvestCallback then
    onPlayerHarvestCallback(function(world, player, tile)
        local uid = player:getUserID(); local data = playerDB[tostring(uid)]
        if data and data.quest_type == "HARVEST" and data.progress < data.req_amount then
            data.progress = data.progress + 1; checkAutoClaim(player, data)
        end
        return false
    end)
end

if onPlayerCatchFishCallback then
    onPlayerCatchFishCallback(function(world, player, itemID, count)
        local uid = player:getUserID(); local data = playerDB[tostring(uid)]
        if data and data.quest_type == "FISH" and data.progress < data.req_amount then
            data.progress = data.progress + 1; checkAutoClaim(player, data)
        end
        return true
    end)
end

if onPlayerProviderCallback then
    onPlayerProviderCallback(function(world, player, tile, itemID, count)
        local uid = player:getUserID(); local data = playerDB[tostring(uid)]
        if data and data.quest_type == "PROVIDER" and data.progress < data.req_amount then
            data.progress = data.progress + 1; checkAutoClaim(player, data)
        end
        return true
    end)
end

if onPlayerXPCallback then
    onPlayerXPCallback(function(world, player, amount)
        local uid = player:getUserID(); local data = playerDB[tostring(uid)]
        if data and data.quest_type == "XP" and data.progress < data.req_amount then
            data.progress = data.progress + amount; checkAutoClaim(player, data)
        end
        return true
    end)
end

if onPlayerLoginCallback then onPlayerLoginCallback(updateSidebar) end
if onPlayerEnterWorldCallback then onPlayerEnterWorldCallback(function(w,p) updateSidebar(p) end) end

loadDatabases()