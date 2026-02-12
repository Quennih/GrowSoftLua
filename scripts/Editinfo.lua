local ROLE_ADMIN = 51
local DB_KEY = "ITEM_INFO"

local insert = table.insert
local concat = table.concat
local format = string.format
local sub = string.sub
local match = string.match
local find = string.find
local tonum = tonumber

local function safeStr(val)
    if val == nil then return "" end
    return tostring(val)
end

local infoCache = {} 
local editingSession = {} 

local function loadInfoDB()
    local data = loadDataFromServer(DB_KEY)
    if data and type(data) == "table" then infoCache = data else infoCache = {} end
end
loadInfoDB()

local function saveInfoDB() saveDataToServer(DB_KEY, infoCache) end

local DEFAULT_PROPS = "This item can't be spliced.\n`1This item never drops any seeds.``\n`1This item cannot be dropped or traded.``"
local DEFAULT_PRICE = "Price is unknown."

local OUR_DIALOGS = {
    ["main_editor_menu"] = true,
    ["list_editor_menu"] = true,
    ["input_handler_menu"] = true
}
local function showMainMenu(player, itemID)
    local uid = player:getUserID()
    if not editingSession[uid] then
        local dbData = infoCache[itemID] or {}
        editingSession[uid] = {
            targetID = itemID,
            bgColor = dbData.bgColor or "",
            borderColor = dbData.borderColor or "",
            descList = dbData.descList or {}, 
            obtainList = dbData.obtainList or {}, 
            properties = dbData.properties or "", 
            price = dbData.price or ""
        }
    end
    local sess = editingSession[uid]
    local item = getItem(itemID)
    local itemName = item and item:getName() or "Unknown"
    
    local buf = {}
    insert(buf, "set_default_color|`o\n")
    insert(buf, format("add_label_with_icon|big|`wMain Editor: %s|left|%d|\n", itemName, itemID))
    insert(buf, "add_spacer|small|\n")
    insert(buf, "add_label|small|`oColors (r,g,b,a):|left|\n")
    insert(buf, format("add_text_input|inp_bg_col|BG:|%s|20|\n", safeStr(sess.bgColor)))
    insert(buf, format("add_text_input|inp_border_col|Border:|%s|20|\n", safeStr(sess.borderColor)))
    insert(buf, "add_spacer|small|\n")
    insert(buf, "add_label|small|`oContent Editors:|left|\n")
    insert(buf, "add_button|open_desc_editor|`w[ Edit Description ]|0|0|\n")
    insert(buf, "add_button|open_obtain_editor|`w[ Edit Obtainability ]|0|0|\n")
    insert(buf, "add_spacer|small|\n")
    insert(buf, "add_label|small|`oPrice Info (Bawah Sendiri):|left|\n")
    insert(buf, format("add_text_input|inp_price|Text:|%s|100|\n", safeStr(sess.price)))
    insert(buf, "add_spacer|small|\n")
    insert(buf, "add_button|btn_save_all|`2[ SAVE & APPLY ]|0|0|\n")
    insert(buf, "add_button|btn_reset_all|`4[ DELETE CONFIG ]|0|0|\n")
    insert(buf, "add_quick_exit|\n")
    insert(buf, "end_dialog|main_editor_menu|||\n")
    player:onDialogRequest(concat(buf))
end

local function showListEditor(player, mode)
    local uid = player:getUserID()
    local sess = editingSession[uid]
    if not sess then return end
    
    local listData = (mode == "desc") and sess.descList or sess.obtainList
    local title = (mode == "desc") and "Description Editor" or "Obtainability Editor"
    
    local buf = {}
    insert(buf, "set_default_color|`o\n")
    insert(buf, format("add_label_with_icon|big|`w%s|left|242|\n", title))
    insert(buf, "add_spacer|small|\n")
    
    if #listData == 0 then
        insert(buf, "add_textbox|`o(List Kosong - Akan menggunakan Default/Hidden)|left|\n")
    else
        for i, entry in ipairs(listData) do
            local label = ""
            if entry.type == "text" then 
                local sizeTag = ""
                if mode == "desc" then
                    sizeTag = entry.big and "`2[NORMAL] " or "`8[SMALL] "
                else
                    local iconUsed = entry.iconID or 482
                    sizeTag = "`6[ICON: "..iconUsed.."] "
                end
                label = sizeTag .. "`o" .. sub(safeStr(entry.val), 1, 20) .. "..."
            elseif entry.type == "spacer" then label = "`5[ SPACER ]"
            elseif entry.type == "break" then label = "`5[ CUSTOM BREAK ]"
            end
            insert(buf, format("add_button|edit_item_%s_%d|`9[%d] %s|0|0|\n", mode, i, i, label))
        end
    end
    
    insert(buf, "add_spacer|small|\n")
    insert(buf, "add_label|small|`oAdd New Element:|left|\n")
    insert(buf, format("add_button|add_text_%s|`2+ Text Line|0|0|\n", mode))
    insert(buf, format("add_button|add_spacer_%s|`w+ Spacer|0|0|\n", mode))
    insert(buf, format("add_button|add_break_%s|`w+ Break|0|0|\n", mode))
    insert(buf, "add_custom_break|\n")
    insert(buf, "add_button|back_to_main|`w< Back to Main Menu|0|0|\n")
    insert(buf, "end_dialog|list_editor_menu|||\n")
    player:onDialogRequest(concat(buf))
end

local function showInputMenu(player, label, defaultVal, extraData, callbackKey, mode)
    local buf = {}
    insert(buf, "set_default_color|`o\n")
    insert(buf, "add_label_with_icon|big|`wText Editor|left|242|\n")
    insert(buf, "add_spacer|small|\n")
    insert(buf, format("add_text_input|input_val|%s|%s|200|\n", label, safeStr(defaultVal)))
    insert(buf, "add_spacer|small|\n")
    
    if mode == "desc" then
        local isBig = extraData and 1 or 0
        insert(buf, format("add_checkbox|chk_big_text|`wNormal Text (Uncheck = Small)|%d|\n", isBig))
    else
        local iconID = extraData or 482
        insert(buf, "add_label|small|`wIcon ID (Item ID):|left|\n")
        insert(buf, format("add_text_input|input_icon|ID:|%d|5|\n", iconID))
    end
    
    insert(buf, "add_spacer|small|\n")
    insert(buf, format("add_button|%s|`2Confirm|0|0|\n", callbackKey))
    insert(buf, "add_button|cancel_input|`4Cancel|0|0|\n")
    
    if find(safeStr(callbackKey), "save_edit_") then
        local delKey = callbackKey:gsub("save_edit", "delete_item")
        insert(buf, format("add_button|%s|`4Delete Line|0|0|\n", delKey))
    end
    insert(buf, "end_dialog|input_handler_menu|||\n")
    player:onDialogRequest(concat(buf))
end

registerLuaCommand({command = "editinfo", roleRequired = ROLE_ADMIN, description = "Edit Info"})

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd, arg = safeStr(fullCommand):match("^(%S+)%s*(.*)")
    if cmd == "editinfo" then
        local itemID = tonum(arg)
        if not itemID then player:onConsoleMessage("Usage: /editinfo <itemID>") return true end
        editingSession[player:getUserID()] = nil
        showMainMenu(player, itemID)
        return true
    end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local dName = safeStr(data.dialog_name)
    if OUR_DIALOGS[dName] then
        local uid = player:getUserID()
        local sess = editingSession[uid]
        local btn = safeStr(data.buttonClicked)
        if not sess then 
            player:onConsoleMessage("`4Session expired (Please /editinfo again).") 
            return true 
        end

        if dName == "main_editor_menu" then
            sess.price = data.inp_price
            sess.bgColor = data.inp_bg_col
            sess.borderColor = data.inp_border_col
            
            if btn == "open_desc_editor" then showListEditor(player, "desc"); return true
            elseif btn == "open_obtain_editor" then showListEditor(player, "obtain"); return true
            elseif btn == "btn_save_all" then
                infoCache[sess.targetID] = {
                    descList = sess.descList,
                    obtainList = sess.obtainList,
                    price = sess.price,
                    bgColor = sess.bgColor,
                    borderColor = sess.borderColor
                }
                saveInfoDB()
                player:onConsoleMessage("`2[SAVED] `oInfo Updated!")
                player:playAudio("kaching.wav")
                return true
            elseif btn == "btn_reset_all" then
                infoCache[sess.targetID] = nil
                saveInfoDB()
                editingSession[uid] = nil
                player:onConsoleMessage("`4[RESET] `oInfo restored.")
                return true
            end
        end

        if dName == "list_editor_menu" then
            if btn == "back_to_main" then showMainMenu(player, sess.targetID); return true end
            
            local mode = find(btn, "_desc") and "desc" or "obtain"
            local listData = (mode == "desc") and sess.descList or sess.obtainList
            
            if find(btn, "add_text_") then
                local defaultExtra = (mode == "desc") and false or 482
                showInputMenu(player, "New Text:", "", defaultExtra, "confirm_add_"..mode, mode)
                return true
            elseif find(btn, "add_spacer_") then
                insert(listData, {type="spacer"})
                showListEditor(player, mode)
                return true
            elseif find(btn, "add_break_") then
                insert(listData, {type="break"})
                showListEditor(player, mode)
                return true
            end
            
            local editMode, editIdx = match(btn, "edit_item_(%a+)_(%d+)")
            if editIdx then
                local idx = tonum(editIdx)
                local item = listData[idx]
                if item.type == "text" then
                    local extra = (editMode == "desc") and item.big or (item.iconID or 482)
                    showInputMenu(player, "Edit Text:", item.val, extra, "save_edit_"..editMode.."_"..idx, editMode)
                else
                    table.remove(listData, idx)
                    showListEditor(player, editMode)
                end
                return true
            end
        end
        
        if dName == "input_handler_menu" then
            if btn == "cancel_input" then showMainMenu(player, sess.targetID); return true end
            
            local newVal = safeStr(data.input_val)
            local isBig = (data.chk_big_text == "1")
            local newIcon = tonum(data.input_icon) or 482
            
            local addMode = match(btn, "confirm_add_(%a+)")
            if addMode then
                local list = (addMode == "desc") and sess.descList or sess.obtainList
                if addMode == "desc" then insert(list, {type="text", val=newVal, big=isBig})
                else insert(list, {type="text", val=newVal, iconID=newIcon}) end
                showListEditor(player, addMode)
                return true
            end
            
            local editMode, editIdx = match(btn, "save_edit_(%a+)_(%d+)")
            if editMode then
                local list = (editMode == "desc") and sess.descList or sess.obtainList
                if editMode == "desc" then list[tonum(editIdx)] = {type="text", val=newVal, big=isBig}
                else list[tonum(editIdx)] = {type="text", val=newVal, iconID=newIcon} end
                showListEditor(player, editMode)
                return true
            end
            
            local delMode, delIdx = match(btn, "delete_item_(%a+)_(%d+)")
            if delMode then
                local list = (delMode == "desc") and sess.descList or sess.obtainList
                table.remove(list, tonum(delIdx))
                showListEditor(player, delMode)
                return true
            end
        end
        
        return true 
    end

    
    
    return false
end)

onPlayerVariantCallback(function(player, variant, delay, netID)
    if variant[1] == "OnDialogRequest" then
        local content = safeStr(variant[2])
        if find(content, "info_box") and not find(content, "info_custom") then
            local stolenID = match(content, "This item ID is (%d+)")
            if stolenID then
                local itemID = tonum(stolenID)
                local customData = infoCache[itemID]
                if not customData then return false end
                
                local itemObj = getItem(itemID)
                local itemName = itemObj and itemObj:getName() or "Unknown"
                local gui = {}
                
                if customData.borderColor and safeStr(customData.borderColor) ~= "" then insert(gui, "set_border_color|"..safeStr(customData.borderColor).."|\n")
                else insert(gui, "set_default_color|`o\n") end
                if customData.bgColor and safeStr(customData.bgColor) ~= "" then insert(gui, "set_bg_color|"..safeStr(customData.bgColor).."|\n") end
                
                insert(gui, "embed_data|info_custom|1|\n")
                insert(gui, format("add_label_with_icon|big|`wAbout %s``|left|%d|\n", itemName, itemID))
                insert(gui, "add_spacer|small|\n")
                
                local propsText = (safeStr(customData.properties) ~= "") and customData.properties or DEFAULT_PROPS
                insert(gui, format("add_textbox|%s\n`!This item ID is %d.``\n`!This item Slot is 0.``|left|\n", propsText, itemID))
                insert(gui, "add_spacer|small|\n")
                
                local function renderList(list, mode)
                    if list and #list > 0 then
                        for _, entry in ipairs(list) do
                            if entry.type == "text" then
                                local txt = safeStr(entry.val):gsub("\\n", "\n")
                                if mode == "obtain" then
                                    local icon = entry.iconID or 482
                                    insert(gui, format("add_label_with_icon|small|%s|left|%d|\n", txt, icon))
                                else
                                    if entry.big then insert(gui, "add_textbox|"..txt.."|left|\n")
                                    else insert(gui, "add_smalltext|"..txt.."|\n") end
                                end
                            elseif entry.type == "spacer" then insert(gui, "add_spacer|small|\n")
                            elseif entry.type == "break" then insert(gui, "add_custom_break|\n")
                            end
                        end
                    end
                end
                
                renderList(customData.descList, "desc")
                
                if customData.obtainList and #customData.obtainList > 0 then
                    insert(gui, "add_spacer|small|\n")
                    insert(gui, "add_textbox|`wObtainability info``|left|\n")
                    renderList(customData.obtainList, "obtain")
                end
                
                local priceText = (customData.price and safeStr(customData.price) ~= "") and customData.price or DEFAULT_PRICE
                insert(gui, "add_spacer|small|\n")
                insert(gui, "add_label_with_icon|small|`wPrice info:````|left|242|\n")
                insert(gui, "add_textbox|"..safeStr(priceText).."|left|\n")
                insert(gui, "end_dialog|info_box||OK|")
                
                player:onDialogRequest(concat(gui))
                return true
            end
        end
    end
    return false
end)
