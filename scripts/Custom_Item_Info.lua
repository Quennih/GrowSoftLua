print("(Loaded) Custom Info Editor")

local ROLE_ADMIN = 51
local DB_KEY = "ITEM_INFO"

local insert = table.insert
local concat = table.concat
local format = string.format
local sub = string.sub
local match = string.match
local find = string.find
local tonum = tonumber

local infoCache = {} 
local editingSession = {} 

local function loadInfoDB()
    local data = loadDataFromServer(DB_KEY)
    if data and type(data) == "table" then
        infoCache = data
    else
        infoCache = {}
    end
end
loadInfoDB()

local function saveInfoDB()
    saveDataToServer(DB_KEY, infoCache)
end

local DEFAULT_PROPS = "This item can't be spliced.\n`1This item never drops any seeds.``\n`1This item cannot be dropped or traded.``"
local DEFAULT_PRICE = "Price is unknown."

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
    insert(buf, format("add_text_input|inp_bg_col|BG:|%s|20|\n", sess.bgColor))
    insert(buf, format("add_text_input|inp_border_col|Border:|%s|20|\n", sess.borderColor))
    insert(buf, "add_spacer|small|\n")
    
    insert(buf, "add_label|small|`oContent Editors:|left|\n")
    insert(buf, "add_button|open_desc_editor|`w[ Edit Description ]|0|0|\n")
    insert(buf, "add_button|open_obtain_editor|`w[ Edit Obtainability ]|0|0|\n")
    insert(buf, "add_spacer|small|\n")
    
    insert(buf, "add_label|small|`oPrice Info (Bawah Sendiri):|left|\n")
    insert(buf, format("add_text_input|inp_price|Text:|%s|100|\n", sess.price))
    
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
                local sizeTag = entry.big and "`2[NORMAL] " or "`8[SMALL] "
                if mode == "obtain" then sizeTag = "`6[ICON] " end 
                label = sizeTag .. "`o" .. sub(entry.val, 1, 20) .. "..."
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

local function showInputMenu(player, label, defaultVal, isBig, callbackKey, mode)
    local checked = isBig and 1 or 0
    
    local buf = {}
    insert(buf, "set_default_color|`o\n")
    insert(buf, "add_label_with_icon|big|`wText Editor|left|242|\n")
    insert(buf, "add_spacer|small|\n")
    
    insert(buf, format("add_text_input|input_val|%s|%s|200|\n", label, defaultVal))
    insert(buf, "add_spacer|small|\n")
    
    if mode == "desc" then
        insert(buf, format("add_checkbox|chk_big_text|`wNormal Text (Uncheck = Small)|%d|\n", checked))
    else
        insert(buf, "add_smalltext|`oMode Obtainability: Otomatis menggunakan format Icon 482.|\n")
    end
    
    insert(buf, "add_spacer|small|\n")
    insert(buf, format("add_button|%s|`2Confirm|0|0|\n", callbackKey))
    insert(buf, "add_button|cancel_input|`4Cancel|0|0|\n")
    
    if find(callbackKey, "save_edit_") then
        local delKey = callbackKey:gsub("save_edit", "delete_item")
        insert(buf, format("add_button|%s|`4Delete Line|0|0|\n", delKey))
    end
    
    insert(buf, "end_dialog|input_handler_menu|||\n")
    player:onDialogRequest(concat(buf))
end

registerLuaCommand({command = "editinfo", roleRequired = ROLE_ADMIN, description = "Edit Info"})

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd, arg = fullCommand:match("^(%S+)%s*(.*)")
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
    local uid = player:getUserID()
    local sess = editingSession[uid]
    
    if not sess and (data.dialog_name:find("_menu")) then 
        player:onConsoleMessage("`4Session expired.") return true 
    end

    if data.dialog_name == "main_editor_menu" then
        sess.price = data.inp_price
        sess.bgColor = data.inp_bg_col
        sess.borderColor = data.inp_border_col
        
        if data.buttonClicked == "open_desc_editor" then
            showListEditor(player, "desc")
            return true
        elseif data.buttonClicked == "open_obtain_editor" then
            showListEditor(player, "obtain")
            return true
        elseif data.buttonClicked == "btn_save_all" then
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
        elseif data.buttonClicked == "btn_reset_all" then
            infoCache[sess.targetID] = nil
            saveInfoDB()
            editingSession[uid] = nil
            player:onConsoleMessage("`4[RESET] `oInfo restored to original.")
            return true
        end
    end

    if data.dialog_name == "list_editor_menu" then
        if data.buttonClicked == "back_to_main" then
            showMainMenu(player, sess.targetID)
            return true
        end
        
        local mode = nil
        if find(data.buttonClicked, "_desc") then mode = "desc" 
        elseif find(data.buttonClicked, "_obtain") then mode = "obtain" end
        
        local listData = (mode == "desc") and sess.descList or sess.obtainList
        
        if find(data.buttonClicked, "add_text_") then
            showInputMenu(player, "New Text:", "", false, "confirm_add_"..mode, mode)
            return true
        end
        
        if find(data.buttonClicked, "add_spacer_") then
            insert(listData, {type="spacer"})
            showListEditor(player, mode)
            return true
        elseif find(data.buttonClicked, "add_break_") then
            insert(listData, {type="break"})
            showListEditor(player, mode)
            return true
        end
        
        local editMode, editIdx = match(data.buttonClicked, "edit_item_(%a+)_(%d+)")
        if editIdx then
            local idx = tonum(editIdx)
            local item = listData[idx]
            if item.type == "text" then
                showInputMenu(player, "Edit Text:", item.val, item.big, "save_edit_"..editMode.."_"..idx, editMode)
            else
                table.remove(listData, idx)
                showListEditor(player, editMode)
            end
            return true
        end
    end
    
    if data.dialog_name == "input_handler_menu" then
        local callback = ""
        for k,v in pairs(data) do 
            if k:find("confirm_add_") or k:find("save_edit_") or k:find("delete_item_") then 
                callback = k 
                break
            end 
        end
        
        if data.buttonClicked == "cancel_input" then
            showMainMenu(player, sess.targetID)
            return true
        end
        
        local newVal = data.input_val
        local isBig = (data.chk_big_text == "1")
        
        local addMode = match(data.buttonClicked, "confirm_add_(%a+)")
        if addMode then
            local list = (addMode == "desc") and sess.descList or sess.obtainList
            insert(list, {type="text", val=newVal, big=isBig})
            showListEditor(player, addMode)
            return true
        end
        
        local editMode, editIdx = match(data.buttonClicked, "save_edit_(%a+)_(%d+)")
        if editMode then
            local list = (editMode == "desc") and sess.descList or sess.obtainList
            list[tonum(editIdx)] = {type="text", val=newVal, big=isBig}
            showListEditor(player, editMode)
            return true
        end
        
        local delMode, delIdx = match(data.buttonClicked, "delete_item_(%a+)_(%d+)")
        if delMode then
            local list = (delMode == "desc") and sess.descList or sess.obtainList
            table.remove(list, tonum(delIdx))
            showListEditor(player, delMode)
            return true
        end
    end

    return false
end)

onPlayerVariantCallback(function(player, variant, delay, netID)
    if variant[1] == "OnDialogRequest" then
        local content = variant[2]
        
        if find(content, "info_box") and not find(content, "info_custom") then
            
            local stolenID = match(content, "This item ID is (%d+)")
            
            if stolenID then
                local itemID = tonum(stolenID)
                local customData = infoCache[itemID]
                
                if not customData then return false end
                
                local itemObj = getItem(itemID)
                local itemName = itemObj and itemObj:getName() or "Unknown"
                
                local gui = {}
                
                if customData.borderColor and customData.borderColor ~= "" then insert(gui, "set_border_color|"..customData.borderColor.."|\n")
                else insert(gui, "set_default_color|`o\n") end
                if customData.bgColor and customData.bgColor ~= "" then insert(gui, "set_bg_color|"..customData.bgColor.."|\n") end
                
                insert(gui, "embed_data|info_custom|1|\n")
                
                insert(gui, format("add_label_with_ele_icon|big|`wAbout %s``|left|%d|3|\n", itemName, itemID))
                insert(gui, "add_spacer|small|\n")
                
                local propsText = (customData.properties ~= "") and customData.properties or DEFAULT_PROPS
                insert(gui, format("add_textbox|%s\n`!This item ID is %d.``\n`!This item Slot is 0.``|left|\n", propsText, itemID))
                
                insert(gui, "add_spacer|small|\n")
                
                local function renderList(list, mode)
                    if list and #list > 0 then
                        for _, entry in ipairs(list) do
                            if entry.type == "text" then
                                local txt = entry.val:gsub("\\n", "\n")
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
                
                local priceText = (customData.price and customData.price ~= "") and customData.price or DEFAULT_PRICE
                insert(gui, "add_spacer|small|\n")
                insert(gui, "add_label_with_icon|small|`wPrice info:````|left|242|\n")
                insert(gui, "add_textbox|"..priceText.."|left|\n")
                
                insert(gui, "end_dialog|info_box||OK|")
                
                player:onDialogRequest(concat(gui))
                return true
            end
        end
    end
    return false
end)
