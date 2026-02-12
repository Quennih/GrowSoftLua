local DB_SETTINGS_KEY = "azarathPS_Config"
local DB_BOTS_KEY_PREFIX = "AZbotWorld_"

local GLOBAL_SETTINGS = {
    command_active = true,
    bot_name = "Spammer",
    limit = 2,
    min_delay = 2,
    min_duration = 60,
    clothes = {98, 0, 0, 48, 818},
    payment = {
        active = false,
        price = 0,
        method = "gems",
        another_id = 0
    }
}

local savedSettings = loadDataFromServer(DB_SETTINGS_KEY)
if savedSettings and type(savedSettings) == "table" then
    if savedSettings.command_active ~= nil then GLOBAL_SETTINGS.command_active = savedSettings.command_active end
    if savedSettings.bot_name then GLOBAL_SETTINGS.bot_name = savedSettings.bot_name end
    if savedSettings.limit then GLOBAL_SETTINGS.limit = savedSettings.limit end
    if savedSettings.min_delay then GLOBAL_SETTINGS.min_delay = savedSettings.min_delay end
    if savedSettings.min_duration then GLOBAL_SETTINGS.min_duration = savedSettings.min_duration end
    
    if savedSettings.clothes and type(savedSettings.clothes) == "table" then 
        GLOBAL_SETTINGS.clothes = savedSettings.clothes 
    end
    
    if savedSettings.payment and type(savedSettings.payment) == "table" then
        local p = savedSettings.payment
        if p.active ~= nil then GLOBAL_SETTINGS.payment.active = p.active end
        if p.price then GLOBAL_SETTINGS.payment.price = p.price end
        if p.method then GLOBAL_SETTINGS.payment.method = p.method end
        if p.another_id then GLOBAL_SETTINGS.payment.another_id = p.another_id end
    end
end

local function saveGlobalSettings()
    saveDataToServer(DB_SETTINGS_KEY, GLOBAL_SETTINGS)
end

local bots = {} 
local session_config = {} 
local COLORS = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "b", "c", "e", "p", "o", "q"}
local TOKEN_ID = 1486 

local insert = table.insert
local concat = table.concat
local abs = math.abs
local random = math.random

local function formatNum(n)
    if not n then return "0" end
    return tostring(n):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

local function saveData(world)
    local wName = world:getName()
    if bots[wName] then
        if #bots[wName] > 0 then
            saveDataToServer(DB_BOTS_KEY_PREFIX .. wName, bots[wName])
        else
            bots[wName] = nil
            saveDataToServer(DB_BOTS_KEY_PREFIX .. wName, {})
        end
    end
end

local function findBotByName(world, targetName, x, y)
    local candidates = world:findNPCByName(targetName) or {}
    for _, npc in ipairs(candidates) do
        local nx, ny = npc:getPosX(), npc:getPosY()
        if abs(nx - x) < 48 and abs(ny - y) < 48 then
            return npc
        end
    end
    return nil
end

local function removeBotsWithSpecificName(world, nameToDelete)
    local wName = world:getName()
    if not bots[wName] then return end
    
    for i = #bots[wName], 1, -1 do
        local b = bots[wName][i]
        local npc = findBotByName(world, nameToDelete, b.x, b.y)
        if npc then world:removeNPC(npc) end
    end
    
    bots[wName] = {} 
    saveData(world)
end

local function equipBot(world, npc, clothesList)
    if not npc then return end
    npc:setCountry("") 
    if clothesList then
        for _, id in ipairs(clothesList) do
            if id and id > 0 then world:setClothing(npc, id) end
        end
    end
end

local function applyRainbow(text)
    local col = COLORS[random(1, #COLORS)]
    return "`" .. col .. text
end

local function processPayment(player)
    if not GLOBAL_SETTINGS.payment.active then return true end
    local price = GLOBAL_SETTINGS.payment.price or 0
    local method = GLOBAL_SETTINGS.payment.method or "gems"
    
    if price <= 0 then return true end
    
    if method == "gems" then
        if player:getGems() >= price then
            player:removeGems(price, 1) 
            player:onConsoleMessage("`2Paid "..formatNum(price).." Gems.")
            player:playAudio("cash_register.wav")
            return true
        else
            player:onConsoleMessage("`4Not enough Gems! Need: "..formatNum(price))
            return false
        end
    elseif method == "token" then
        if player:getItemAmount(TOKEN_ID) >= price then
            player:changeItem(TOKEN_ID, -price, 0)
            player:onConsoleMessage("`2Paid "..formatNum(price).." Growtokens.")
            player:playAudio("cash_register.wav")
            return true
        else
            player:onConsoleMessage("`4Not enough Tokens! Need: "..formatNum(price))
            return false
        end
    elseif method == "pwl" then
        if player:getCoins() >= price then
            player:removeCoins(price, 1)
            player:onConsoleMessage("`2Paid "..formatNum(price).." Premium WL (Coins).")
            player:playAudio("cash_register.wav")
            return true
        else
            player:onConsoleMessage("`4Not enough Premium WL! Need: "..formatNum(price))
            return false
        end
    elseif method == "another" then
        local itemID = GLOBAL_SETTINGS.payment.another_id or 0
        if itemID == 0 then return false end
        
        if player:getItemAmount(itemID) >= price then
            player:changeItem(itemID, -price, 0)
            local itm = getItem(itemID)
            local name = itm and itm:getName() or "Item"
            player:onConsoleMessage("`2Paid "..formatNum(price).." "..name..".")
            player:playAudio("cash_register.wav")
            return true
        else
            local itm = getItem(itemID)
            local name = itm and itm:getName() or "Item"
            player:onConsoleMessage("`4Not enough "..name.."! Need: "..formatNum(price))
            return false
        end
    end
    return true
end

local function showAdminPanel(player)
    local activeChk = GLOBAL_SETTINGS.command_active and 1 or 0
    local d = {}
    
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|`wSpammer Settings``|left|6214|\n")
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_label|small|`wGeneral Configuration:|left|\n")
    insert(d, "add_checkbox|chk_active|Enable /spammer command|"..activeChk.."|\n")
    insert(d, "add_text_input|inp_name|Bot Name:|"..GLOBAL_SETTINGS.bot_name.."|30|\n")
    insert(d, "add_text_input|inp_limit|Max Bot Limit (Per Player):|"..(GLOBAL_SETTINGS.limit or 2).."|3|numeric|\n")
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_label|small|`wTiming Configuration:|left|\n")
    insert(d, "add_text_input|inp_delay|Min Text Delay (Sec):|"..(GLOBAL_SETTINGS.min_delay or 2).."|3|numeric|\n")
    insert(d, "add_text_input|inp_duration|Min Duration/Expiry (Sec):|"..(GLOBAL_SETTINGS.min_duration or 60).."|5|numeric|\n")
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_label|small|`wCustomization & Payment:|left|\n")
    insert(d, "add_button|btn_clothes|`wSet Bot Clothing|0|0|\n")
    insert(d, "add_button|btn_payment|`wPayment Settings|0|0|\n")
    
    insert(d, "add_custom_break|\n")
    insert(d, "add_spacer|small|\n")
    insert(d, "add_button|btn_save_main|`2Accept & Update Config|0|0|\n")
    
    insert(d, "add_quick_exit|\nend_dialog|setspammer_main|||\n")
    player:onDialogRequest(concat(d))
end

local function showUserConfig(player, defaultText, defaultInt, defaultDur, rainbowState, isNew)
    local title = isNew and "`2Create Spammer Bot" or "`2Edit Spammer Bot"
    local btnLabel = isNew and "`2CONFIRM & SPAWN" or "`2UPDATE BOT"
    local delBtn = isNew and "" or "add_button|btn_delete|`4DELETE BOT|0|0|\n"
    
    local d = {}
    insert(d, "set_default_color|`o\n")
    insert(d, "add_label_with_icon|big|"..title.."``|left|6214|\n")
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_text_input|t|Spam Text:|"..defaultText.."|100|\n")
    insert(d, "add_checkbox|chk_rb|Rainbow Text|"..rainbowState.."|\n")
    insert(d, "add_spacer|small|\n")
    
    insert(d, "add_text_input|i|Interval (Sec):|"..defaultInt.."|3|numeric|\n")
    insert(d, "add_text_input|d|Duration (Sec):|"..defaultDur.."|5|numeric|\n")
    
    if isNew and GLOBAL_SETTINGS.payment.active then
        insert(d, "add_spacer|small|\n")
        insert(d, "add_smalltext|`4Note: You will be charged upon confirmation.|left|\n")
    end
    
    insert(d, "add_spacer|small|\n")
    if not isNew then insert(d, delBtn) end
    insert(d, "add_button|btn_confirm|"..btnLabel.."|0|0|\n")
    insert(d, "end_dialog|azarath_menu|||\n")
    
    player:onDialogRequest(concat(d))
end

registerLuaCommand({command = "spammer", roleRequired = 0, description = "Spawn Spammer Bot"})
registerLuaCommand({command = "setspammer", roleRequired = 51, description = "Admin Panel Spammer"})

onPlayerCommandCallback(function(world, player, cmd)
    if cmd == "setspammer" then
        if player:hasRole(51) then
            showAdminPanel(player)
            return true
        end
    end

    if cmd == "spammer" then
        if not GLOBAL_SETTINGS.command_active then
            player:onConsoleMessage("`4Spammer command is currently disabled by Admin.")
            player:playAudio("bleep_fail.wav")
            return true
        end
        
        local wName = world:getName()
        local uid = player:getUserID()
        
        if not bots[wName] then
            bots[wName] = loadDataFromServer(DB_BOTS_KEY_PREFIX .. wName) or {}
        end
        
        local count = 0
        for _, b in ipairs(bots[wName]) do
            if b.owner == uid then count = count + 1 end
        end
        
        if count >= (GLOBAL_SETTINGS.limit or 2) then
            player:onConsoleMessage("`4Limit reached ("..(GLOBAL_SETTINGS.limit or 2).." Bots).")
            player:playAudio("already_used.wav")
            return true
        end
        
        session_config[uid] = { 
            is_new = true, 
            x = player:getPosX(), 
            y = player:getPosY() 
        }
        
        showUserConfig(player, "Welcome!", (GLOBAL_SETTINGS.min_delay or 2) + 2, (GLOBAL_SETTINGS.min_duration or 60), 0, true)
        
        return true
    end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    if data.dialog_name == "setspammer_main" then
        if not player:hasRole(51) then return true end
        
        if data.buttonClicked == "btn_clothes" then
            local c = GLOBAL_SETTINGS.clothes or {}
            local d = {}
            insert(d, "set_default_color|`o\nadd_label_with_icon|big|`wBot Clothing``|left|6214|\n")
            insert(d, "add_textbox|`oEnter Item IDs for the bot. Set 0 to remove.|\n")
            
            insert(d, "add_text_input|c1|Hat/Hair ID:|"..(c[1] or 0).."|5|numeric|\n")
            insert(d, "add_text_input|c2|Shirt ID:|"..(c[2] or 0).."|5|numeric|\n")
            insert(d, "add_text_input|c3|Pants ID:|"..(c[3] or 0).."|5|numeric|\n")
            insert(d, "add_text_input|c4|Feet ID:|"..(c[4] or 0).."|5|numeric|\n")
            insert(d, "add_text_input|c5|Hand/Back:|"..(c[5] or 0).."|5|numeric|\n")
            insert(d, "add_text_input|c6|Other:|"..(c[6] or 0).."|5|numeric|\n")
            insert(d, "add_spacer|small|\n")
            insert(d, "add_button|btn_update_clothes|`2Update|0|0|\n")
            insert(d, "add_button|btn_back_main|`wBack|0|0|\n")
            insert(d, "end_dialog|setspammer_clothes|||\n")
            player:onDialogRequest(concat(d))
            return true
            
        elseif data.buttonClicked == "btn_payment" then
            local pay = GLOBAL_SETTINGS.payment
            local act = pay.active and 1 or 0
            local isGems = (pay.method == "gems") and 1 or 0
            local isToken = (pay.method == "token") and 1 or 0
            local isPwl = (pay.method == "pwl") and 1 or 0
            local isAnother = (pay.method == "another") and 1 or 0
            
            local d = {}
            insert(d, "set_default_color|`o\nadd_label_with_icon|big|`wPayment Config``|left|6214|\n")
            insert(d, "add_checkbox|pay_chk_active|Require Payment|"..act.."|\n")
            insert(d, "add_text_input|pay_price|Price Amount:|"..(pay.price or 0).."|9|numeric|\n")
            insert(d, "add_spacer|small|\n")
            insert(d, "add_label|small|`wPayment Method (Select One):|left|\n")
            insert(d, "add_checkbox|pay_chk_gems|Gems|"..isGems.."|\n")
            insert(d, "add_checkbox|pay_chk_token|Growtoken ("..TOKEN_ID..")|"..isToken.."|\n")
            insert(d, "add_checkbox|pay_chk_pwl|Premium WL (Coins)|"..isPwl.."|\n")
            
            insert(d, "add_spacer|small|\n")
            insert(d, "add_checkbox|pay_chk_another|Another Item|"..isAnother.."|\n")
            insert(d, "add_text_input|pay_another_id|Item ID:|"..(pay.another_id or 0).."|5|numeric|\n")
            
            insert(d, "add_spacer|small|\n")
            insert(d, "add_button|btn_update_payment|`2Update Config|0|0|\n")
            insert(d, "add_button|btn_back_main|`wBack|0|0|\n")
            insert(d, "end_dialog|setspammer_payment|||\n")
            player:onDialogRequest(concat(d))
            return true
            
        elseif data.buttonClicked == "btn_save_main" then
            local oldName = GLOBAL_SETTINGS.bot_name or "Spammer"
            removeBotsWithSpecificName(world, oldName)
            
            GLOBAL_SETTINGS.command_active = (data.chk_active == "1")
            
            local newName = data.inp_name
            if not newName or newName == "" then newName = "Spammer" end
            GLOBAL_SETTINGS.bot_name = newName
            
            GLOBAL_SETTINGS.limit = tonumber(data.inp_limit) or 2
            GLOBAL_SETTINGS.min_delay = tonumber(data.inp_delay) or 2
            GLOBAL_SETTINGS.min_duration = tonumber(data.inp_duration) or 60
            
            saveGlobalSettings()
            
            player:onConsoleMessage("`2Settings Saved! `oExisting bots cleared to apply changes.")
            player:playAudio("bell.wav")
            return true
        end
    end
    
    if data.dialog_name == "setspammer_clothes" then
        if data.buttonClicked == "btn_back_main" then
            showAdminPanel(player)
            return true
        elseif data.buttonClicked == "btn_update_clothes" then
            local newClothes = {}
            for i=1, 6 do
                local val = tonumber(data["c"..i]) or 0
                if val > 0 then insert(newClothes, val) end
            end
            GLOBAL_SETTINGS.clothes = newClothes
            saveGlobalSettings()
            player:onConsoleMessage("`2Clothing Updated!")
            player:playAudio("bell.wav")
            showAdminPanel(player)
            return true
        end
    end
    
    if data.dialog_name == "setspammer_payment" then
        if data.buttonClicked == "btn_back_main" then
            showAdminPanel(player)
            return true
        elseif data.buttonClicked == "btn_update_payment" then
            GLOBAL_SETTINGS.payment.active = (data.pay_chk_active == "1")
            GLOBAL_SETTINGS.payment.price = tonumber(data.pay_price) or 0
            GLOBAL_SETTINGS.payment.another_id = tonumber(data.pay_another_id) or 0
            
            if data.pay_chk_pwl == "1" then 
                GLOBAL_SETTINGS.payment.method = "pwl"
            elseif data.pay_chk_token == "1" then 
                GLOBAL_SETTINGS.payment.method = "token"
            elseif data.pay_chk_another == "1" then
                GLOBAL_SETTINGS.payment.method = "another"
            else 
                GLOBAL_SETTINGS.payment.method = "gems" 
            end
            
            saveGlobalSettings()
            player:onConsoleMessage("`2Payment Settings Updated!")
            player:playAudio("bell.wav")
            showAdminPanel(player)
            return true
        end
    end

    local uid = player:getUserID()
    local wName = world:getName()
    local sess = session_config[uid]
    
    if data.dialog_name == "azarath_menu" then
        if not sess then 
            player:onConsoleMessage("`4Session Expired. Please try again.")
            return true 
        end
        
        if sess.is_new then
            if data.buttonClicked == "btn_confirm" then
                local i = tonumber(data.i) or 10
                local d = tonumber(data.d) or 60
                
                local minD = GLOBAL_SETTINGS.min_delay or 2
                local minDur = GLOBAL_SETTINGS.min_duration or 60
                
                if i < minD then 
                    player:onConsoleMessage("`4Delay too fast! Min: "..minD.."s") 
                    player:playAudio("bleep_fail.wav")
                    return true 
                end
                
                if d < minDur then
                    player:onConsoleMessage("`4Duration too short! Min: "..minDur.."s")
                    player:playAudio("bleep_fail.wav")
                    return true
                end
                
                if not processPayment(player) then
                    player:playAudio("bleep_fail.wav")
                    session_config[uid] = nil
                    return true
                end
                
                if not bots[wName] then bots[wName] = {} end
                local botName = GLOBAL_SETTINGS.bot_name or "Spammer"
                local npc = world:createNPC(botName, sess.x, sess.y)
                
                if npc then
                    equipBot(world, npc, GLOBAL_SETTINGS.clothes)
                    
                    insert(bots[wName], {
                        owner = uid,
                        x = sess.x,
                        y = sess.y,
                        text = data.t,
                        int = i,
                        dur = d,
                        active = true,
                        expire = os.time() + d,
                        next = os.time(),
                        rainbow = (data.chk_rb == "1")
                    })
                    saveData(world)
                    player:onConsoleMessage("`2Bot Spawned & Started! `o(Duration: "..d.."s)")
                    player:playAudio("cash_register.wav")
                else
                    player:onConsoleMessage("`4Failed to spawn bot here.")
                end
                session_config[uid] = nil
                return true
            end
        else
            if bots[wName] and bots[wName][sess.index] then
                if data.buttonClicked == "btn_delete" then
                    local b = bots[wName][sess.index]
                    local currentBotName = GLOBAL_SETTINGS.bot_name or "Spammer"
                    local npc = findBotByName(world, currentBotName, b.x, b.y)
                    if npc then world:removeNPC(npc) end
                    table.remove(bots[wName], sess.index)
                    saveData(world)
                    player:onConsoleMessage("`2Bot Deleted.")
                    session_config[uid] = nil
                    return true
                elseif data.buttonClicked == "btn_confirm" then
                    local i = tonumber(data.i) or 10
                    local d = tonumber(data.d) or 60
                    local minD = GLOBAL_SETTINGS.min_delay or 2
                    local minDur = GLOBAL_SETTINGS.min_duration or 60
                    
                    if i < minD then 
                        player:onConsoleMessage("`4Delay too fast! Min: "..minD.."s") 
                        player:playAudio("bleep_fail.wav")
                        return true 
                    end
                    if d < minDur then
                        player:onConsoleMessage("`4Duration too short! Min: "..minDur.."s")
                        player:playAudio("bleep_fail.wav")
                        return true
                    end
                    
                    local b = bots[wName][sess.index]
                    b.text = data.t
                    b.int = i
                    b.dur = d
                    b.rainbow = (data.chk_rb == "1")
                    b.active = true
                    b.expire = os.time() + d
                    b.next = os.time()
                    
                    saveData(world)
                    player:onConsoleMessage("`2Bot Updated! `o(Duration reset to: "..d.."s)")
                    local currentBotName = GLOBAL_SETTINGS.bot_name or "Spammer"
                    local currentNPC = findBotByName(world, currentBotName, b.x, b.y)
                    if currentNPC then
                        player:sendVariant({"OnTalkBubble", currentNPC:getNetID(), "Updating...", 0})
                    end
                    player:playAudio("bell.wav")
                    session_config[uid] = nil
                    return true
                end
            end
        end
    end
    
    return false
end)

onPlayerWrenchCallback(function(world, player, entity)
    local targetName = GLOBAL_SETTINGS.bot_name or "Spammer"
    
    if entity:getType() == 25 and entity:getName() == targetName then
        local wName = world:getName()
        local uid = player:getUserID()
        
        if not bots[wName] then bots[wName] = loadDataFromServer(DB_BOTS_KEY_PREFIX .. wName) or {} end
        
        local ex, ey = entity:getPosX(), entity:getPosY()
        local foundIndex = nil
        
        for i, b in ipairs(bots[wName]) do
            if b.owner == uid and abs(b.x - ex) < 48 and abs(b.y - ey) < 48 then
                foundIndex = i
                break
            end
        end
        
        if foundIndex then
            session_config[uid] = { 
                is_new = false, 
                index = foundIndex 
            }
            local data = bots[wName][foundIndex]
            local rbState = data.rainbow and 1 or 0
            showUserConfig(player, data.text, data.int, data.dur, rbState, false)
        else
            player:onConsoleMessage("`4This is not your bot.")
        end
        return true
    end
    return false
end)

onPlayerLeaveWorldCallback(function(world, player)
    local wName = world:getName()
    local uid = player:getUserID()
    local list = bots[wName]
    local targetName = GLOBAL_SETTINGS.bot_name or "Spammer"
    
    if list then
        local changed = false
        for i = #list, 1, -1 do
            local b = list[i]
            if b.owner == uid and not b.active then
                local npc = findBotByName(world, targetName, b.x, b.y)
                if npc then world:removeNPC(npc) end
                table.remove(list, i)
                changed = true
            end
        end
        if changed then saveData(world) end
    end
end)

onWorldTick(function(world)
    local wName = world:getName()
    local list = bots[wName]
    if not list then return end
    
    local now = os.time()
    local update = false
    local targetName = GLOBAL_SETTINGS.bot_name or "Spammer"
    
    for i = #list, 1, -1 do
        local b = list[i]
        if b.active then
            if now >= b.expire then
                local npc = findBotByName(world, targetName, b.x, b.y)
                if npc then world:removeNPC(npc) end
                table.remove(list, i)
                update = true
            elseif now >= b.next then
                local npc = findBotByName(world, targetName, b.x, b.y)
                if npc then
                    local finalText = b.text
                    if b.rainbow then finalText = applyRainbow(finalText) end
                    for _, p in ipairs(world:getPlayers()) do
                        p:sendVariant({"OnTalkBubble", npc:getNetID(), finalText, 0})
                    end
                    b.next = now + b.int
                else
                    local newNpc = world:createNPC(targetName, b.x, b.y)
                    if newNpc then equipBot(world, newNpc, GLOBAL_SETTINGS.clothes) end
                end
            end
        end
    end
    if update then saveData(world) end
end)

onPlayerEnterWorldCallback(function(world, player)
    local wName = world:getName()
    if not bots[wName] then
        bots[wName] = loadDataFromServer(DB_BOTS_KEY_PREFIX .. wName) or {}
    end
    
    local targetName = GLOBAL_SETTINGS.bot_name or "Spammer"
    for _, b in ipairs(bots[wName]) do
        if not findBotByName(world, targetName, b.x, b.y) then
            local npc = world:createNPC(targetName, b.x, b.y)
            if npc then equipBot(world, npc, GLOBAL_SETTINGS.clothes) end
        end
    end
end)

onPlayerDisconnectCallback(function(player)
    local uid = player:getUserID()
    if session_config[uid] then session_config[uid] = nil end
end)

onWorldOffloaded(function(world)
    local wName = world:getName()
    if bots[wName] then bots[wName] = nil end
end)
