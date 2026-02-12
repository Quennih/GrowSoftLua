print("(Loaded) Fishtoken Shop Script")

local MAX_INVENTORY   = 200
local FISHTOKEN_ID    = 25020
local SHOP_TRIGGER_ID = 25150

-------------------------------------------------------------------
-- CATALOG (id, price, amount)
-------------------------------------------------------------------
local shopItemsStarter = {
    {id = 2914, price = 1,  amount = 150},
    {id = 3012, price = 1, amount = 100},
    {id = 3014, price = 1,   amount = 75},
    {id = 3016, price = 1,   amount = 50},
    {id = 3018, price = 1,   amount = 20},
    {id = 3020, price = 5,   amount = 10},
    {id = 3432, price = 5,   amount = 10},
    {id = 4246, price = 1,   amount = 10},
    {id = 4248, price = 3,   amount = 10},
    {id = 3098, price = 5,   amount = 10},
    {id = 3218, price = 3,   amount = 10},
    {id = 5526, price = 3,   amount = 10},
    {id = 5528, price = 3,   amount = 10},    
}
local shopItemsCrates = {
    {id = 2912, price = 1,  amount = 1},
    {id = 3008, price = 1,  amount = 1},
    {id = 3010, price = 25,  amount = 1},
    {id = 3100, price = 150, amount = 1},
}
local shopItemsPopular = {
    {id = 3004, price = 1, amount = 100},
    {id = 5532, price = 1, amount = 5},
    {id = 5534, price = 1, amount = 5},
    {id = 5536, price = 1, amount = 5},
    {id = 3044, price = 1, amount = 3},
    {id = 25104, price = 2,  amount = 1},
    {id = 3002, price = 1, amount = 1},
    {id = 3466, price = 1, amount = 1},
    {id = 3470, price = 1, amount = 2},
    {id = 13740, price = 1, amount = 1},
    {id = 25024, price = 1,  amount = 1},
    {id = 10388, price = 5,  amount = 1}, 
    {id = 13268, price = 50,  amount = 1},
    {id = 13278, price = 5,  amount = 1},
    {id = 5604, price = 10,  amount = 1},
    {id = 5530, price = 10, amount = 1},
    {id = 11768, price = 10,  amount = 1},
    {id = 3042, price = 500, amount = 1},
    {id = 7746, price = 100, amount = 1},
    {id = 9074, price = 500, amount = 1},
}

-------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------
local function bal(p)          return p:getItemAmount(FISHTOKEN_ID) end
local function give(p,id,a)    p:changeItem(id,a,0) end
local catalog = {shopItemsStarter, shopItemsCrates, shopItemsPopular}
local function fetch(idx)
    local c = 0
    for _, t in ipairs(catalog) do
        if idx <= c + #t then return t[idx - c] end
        c = c + #t
    end
end

local function padPriceDynamic(price)
    local str = tostring(price)
    local padded

    if #str == 1 then
        padded = "  `9" .. str .. " `wFishtoken  "
    elseif #str == 2 then
        padded = " " .. str .. " `wFishtoken "
    else
        padded = str .. " `wFishtoken"
    end

    local spacer = "`0   `9"
    return spacer .. padded .. spacer
end

-------------------------------------------------------------------
-- SHOP DIALOG
-------------------------------------------------------------------
local BUTTON_WIDTH    = 0.28
local BUTTONS_PER_ROW = 5

local function createShopDialog(p)
    local dlg = ("set_default_color|`o\n"
      .."set_custom_spacing|x:10;y:8|\n"
      .."add_label_with_icon|big|`wFisherman's Booth|left|%d|\n"
      .."add_spacer|small|\nadd_textbox|Welcome, pick your goodies to purchase!|left|\nadd_spacer|small|\n"
      .."add_label_with_icon|small|`oYou have `w%d `oFishtokens|left|%d|\n"
      .."add_spacer|small|\n"
      .."add_spacer|small|\n")
      :format(SHOP_TRIGGER_ID, bal(p), FISHTOKEN_ID)

    local btn = 1
    local function section(title, rows, icon, frame)
        if #rows == 0 then return end
        dlg = dlg .. ("add_label_with_icon|small|`w%s|left|%d|\nadd_spacer|small|\n"):format(title, icon)
        for i, v in ipairs(rows) do
            local label = padPriceDynamic(v.price)
            dlg = dlg .. ("add_button_with_icon|var_%d|`9%s|%s|%d|%d|left|width:%.2f;text_scale:0.65;|\n")
                :format(btn, label, frame, v.id, v.amount, BUTTON_WIDTH)
            if i % BUTTONS_PER_ROW == 0 then dlg = dlg .. "add_custom_break|\n" end
            btn = btn + 1
        end
        dlg = dlg .. "add_custom_break|\nadd_spacer|small|\n"
    end

    section("Baits",         shopItemsStarter, 2914, "staticBlueFrame")
    section("Rods",          shopItemsCrates,  2912, "staticBlueFrame")
    section("Special Items", shopItemsPopular, 3042, "staticBlueFrame")

    dlg = dlg .. "add_label|big||left|0|\nadd_quick_exit|\n"
       .. "add_button|back_to_main|`oBack|left|25019|\n"
       .. "end_dialog|fishshop_dialog|||\n"
    p:onDialogRequest(dlg)
end

-------------------------------------------------------------------
-- CONFIRM DIALOG
-------------------------------------------------------------------
local function showConfirm(p, idx)
    local row = fetch(idx); if not row then return end
    local it  = getItem(row.id)

    local dlg = "set_default_color|`o\nadd_spacer|small|\n"
      .."add_label_with_icon|big|`wConfirm Purchase|left|6292|\nadd_spacer|small|\n"
      ..("add_smalltext|`wItem: `o%s x%d|\n"):format(it:getName(), row.amount)
      ..("add_smalltext|`wPrice: `o%d Fishtoken|\n"):format(row.price)
      ..("add_smalltext|`wCurrent balance: `o%d Fishtoken|\n"):format(bal(p))
      .."add_spacer|small|\nadd_label_with_icon|big||left|"..row.id.."|\n"
      .."add_smalltext|`wItem Description:|\nadd_smalltext|`o"..it:getDescription().."|\n"
      ..("add_custom_button|fish_confirm_buy_%d|textLabel:`2Purchase for %d Fishtoken|\n"):format(idx, row.price)
      .."add_custom_break|\nadd_spacer|small|\nadd_button|back_to_main|`4Back|\nadd_custom_break|\n"
      .."add_label_with_icon|big||left|0|\nadd_quick_exit|\nend_dialog|fish_confirm_dialog|||\n"
    p:onDialogRequest(dlg)
end

-------------------------------------------------------------------
-- CALLBACKS
-------------------------------------------------------------------
onPlayerDialogCallback(function(_, p, d)
    local dlg, btn = d.dialog_name or "", d.buttonClicked or ""

    if dlg == "fishshop_dialog" then
        local idx = tonumber(btn:match("^var_(%d+)$"))
        if idx then showConfirm(p, idx); return true end

    elseif dlg == "fish_confirm_dialog" then
        if btn == "back_to_main" then createShopDialog(p); return true end

        local idx = tonumber(btn:match("^fish_confirm_buy_(%d+)$")); if not idx then return true end
        local row = fetch(idx); if not row then return true end
        local it  = getItem(row.id)

        if bal(p) < row.price then
            p:onTalkBubble(p:getNetID(), "`4Not enough Fishtoken.", 1)
            return true
        end
        if p:getItemAmount(row.id) + row.amount > MAX_INVENTORY then
            p:onTalkBubble(p:getNetID(), "`4Not enough inventory space!", 0)
            return true
        end

        give(p, FISHTOKEN_ID, -row.price)
        give(p, row.id, row.amount)

        p:onTalkBubble(
            p:getNetID(),
            ("`2You purchased %d %s!"):format(row.amount, it:getName()),
            1
        )

        if p.playAudio then p:playAudio(18) elseif p.playSFX then p:playSFX(18) end
        p:onConsoleMessage(
            ("Bought %s x%d for %d Fishtoken"):format(it:getName(), row.amount, row.price)
        )
        return true
    end
    return false
end)

-------------------------------------------------------------------
-- WRENCH HANDLER
-------------------------------------------------------------------
onTileWrenchCallback(function(_, p, t)
    if t:getTileID() == SHOP_TRIGGER_ID then
        createShopDialog(p)
        return true
    end
    return false
end)
