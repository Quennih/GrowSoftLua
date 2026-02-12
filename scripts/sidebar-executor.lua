-- Sidebar script
print("(Loaded) Sidebar script for GrowSoft")
print("(Loaded) Sidebar Manager v4.1 Silent")

local ROLE_ADMIN = 51

local globalData = {
    detected_buttons = {
        "DailyChallenge",
        "ActiveAuctionButton", 
        "AuctionButton", 
        "MailboxButton", 
        "PiggyBankButton", 
        "PowerOrb", 
        "Coins", 
        "ClashEventButton"
    },
    detected_actions = {
        [""] = "ActiveAuctionButton",
        ["coinsmenu"] = "Coins",
        ["eventmenu"] = "ClashEventButton",
        ["openPiggyBank"] = "PiggyBankButton",
        ["powerorbmenu"] = "PowerOrb",
        ["show_auction_ui"] = "AuctionButton",
        ["show_mailbox_ui"] = "MailboxButton",
        ["dailychallengemenu"] = "DailyChallenge"
    },
    hidden = {
        ["ActiveAuctionButton"] = true,
        ["AuctionButton"] = true,
        ["ClashEventButton"] = true,
        ["Coins"] = true,
        ["DailyChallenge"] = true,
        ["PiggyBankButton"] = true,
        ["PowerOrb"] = true
    }
}

local deepSearchSession = {} 

local function extractActionFromJSON(jsonStr)
    if not jsonStr then return nil end
    local act = string.match(jsonStr, '"action"%s*:%s*"(.-)"')
    if act then return act end
    act = string.match(jsonStr, '"buttonAction"%s*:%s*"(.-)"')
    if act then return act end
    act = string.match(jsonStr, '"name"%s*:%s*"(.-)"')
    if act then return act end
    return nil
end

local function registerButtonPacket(btnName, btnJson)
    if not btnName then return end
    local isNew = true
    for _, v in pairs(globalData.detected_buttons) do
        if v == btnName then isNew = false; break end
    end
    if isNew then 
        table.insert(globalData.detected_buttons, 1, btnName)
        local actionName = extractActionFromJSON(btnJson)
        if actionName then globalData.detected_actions[actionName] = btnName end
    end
end

local function silentNuke(player)
    if not player then return end
    for btnName, isHidden in pairs(globalData.hidden) do
        if isHidden then
            player:sendVariant({
                "OnEventButtonDataSet",
                btnName,
                0,
                ""
            })
        end
    end
end

local function showAdminMenu(player)
    local uid = player:getUserID()
    local d = "set_default_color|`o\nadd_label_with_icon|big|`4Sidebar Manager v4.1``|left|1400|\nadd_spacer|small|\n"
    
    if deepSearchSession[uid] then
        d = d .. "add_label|big|`2[DEEP SEARCH ACTIVE]``|left|\nadd_textbox|`wClick a Sidebar Button...``|left|\nadd_button|cancel_search|`4CANCEL|0|0|\n"
    else
        d = d .. "add_textbox|`oChecked = `4HIDDEN (Global)``.|left|\nadd_spacer|small|\n"
        for i = 1, math.min(#globalData.detected_buttons, 50) do
            local name = globalData.detected_buttons[i]
            local isHidden = globalData.hidden[name] and 1 or 0
            local label = name
            if name == "MailboxButton" then label = "`2"..name.." (Safe)" end
            d = d .. "add_checkbox|chk_"..name.."|"..label.."|"..isHidden.."|\n"
        end
        d = d .. "add_spacer|small|\nadd_button|btn_save|`2[ SAVE & APPLY ]|0|0|\nadd_custom_break|\nadd_button|btn_deep_search|`b[ START DEEP SEARCH ]|0|0|\n"
    end
    d = d .. "add_quick_exit|\nend_dialog|sidebar_admin_menu|||\n"
    player:onDialogRequest(d)
end

registerLuaCommand({command = "sidebar", roleRequired = ROLE_ADMIN, description = "Global Sidebar Manager"})

onPlayerCommandCallback(function(world, player, cmd)
    if cmd == "sidebar" and player:hasRole(ROLE_ADMIN) then showAdminMenu(player); return true end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    if data.dialog_name == "sidebar_admin_menu" then
        if not player:hasRole(ROLE_ADMIN) then return true end
        local uid = player:getUserID()
        
        if data.buttonClicked == "btn_deep_search" then
            deepSearchSession[uid] = true
            showAdminMenu(player)
            return true
        elseif data.buttonClicked == "cancel_search" then
            deepSearchSession[uid] = nil
            showAdminMenu(player)
            return true
        elseif data.buttonClicked == "btn_save" then
            globalData.hidden = {} 
            for _, name in ipairs(globalData.detected_buttons) do
                if data["chk_"..name] == "1" then
                    globalData.hidden[name] = true
                end
            end
            player:onConsoleMessage("`2Settings Saved!")
            silentNuke(player)
            showAdminMenu(player)
            return true
        end
        return true
    end
    return false
end)

onPlayerVariantCallback(function(player, variant, delay, netID)
    if variant[1] == "OnEventButtonDataSet" then
        local btnName = variant[2]
        local btnStatus = variant[3]
        local btnJsonStr = variant[4] 
        
        registerButtonPacket(btnName, btnJsonStr)
        
        if globalData.hidden[btnName] and btnStatus == 1 then
            player:sendVariant({"OnEventButtonDataSet", btnName, 0, ""}, delay, netID)
            return true
        end
        
        local actionName = extractActionFromJSON(btnJsonStr)
        if actionName then
            globalData.detected_actions[actionName] = btnName
            local parentBtn = globalData.detected_actions[actionName]
            if parentBtn and globalData.hidden[parentBtn] and btnStatus == 1 then
                player:sendVariant({"OnEventButtonDataSet", btnName, 0, ""}, delay, netID)
                return true
            end
        end
    end
    return false
end)

onPlayerActionCallback(function(world, player, data)
    local actionName = data.action
    if actionName == "refresh_inventory" or actionName == "dialog_return" then return false end
    
    if deepSearchSession[player:getUserID()] and player:hasRole(ROLE_ADMIN) then
        local foundParent = globalData.detected_actions[actionName]
        if foundParent then
            player:onConsoleMessage("`2[MATCH] `oAction matches: `b" .. foundParent)
        else
            player:onConsoleMessage("`4[UNKNOWN] `oAction: "..actionName)
        end
        deepSearchSession[player:getUserID()] = nil
        showAdminMenu(player)
        return false
    end
    
    local parentBtn = globalData.detected_actions[actionName]
    if parentBtn and globalData.hidden[parentBtn] then
        return true
    end
    return false
end)

if onPlayerEnterWorldCallback then
    onPlayerEnterWorldCallback(function(world, player)
        silentNuke(player)
    end)
end

if onPlayerLoginCallback then
    onPlayerLoginCallback(function(player)
        silentNuke(player)
    end)
end
