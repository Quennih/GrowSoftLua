print("(Loaded) FarmToken Shop Script")

local MAX_INVENTORY   = 200
local FARMTOKEN_ID    = 25142  -- FarmToken ID
local SHOP_TRIGGER_ID = 25154  -- Rancher NPC Trigger ID

-------------------------------------------------------------------
-- CATALOG (id, price, amount)
-------------------------------------------------------------------
local shopItemsStarter = {
    {id = 98, price = 1, amount = 1},
    {id = 5022, price = 150, amount = 1},
    {id = 1966, price = 150, amount = 1},
    {id = 7408, price = 50, amount = 1},
    {id = 7410, price = 50, amount = 1},
    {id = 9420, price = 100, amount = 1},
    --{id = 6840, price = 100, amount = 1},
}

local shopItemsCrates = {
    {id = 954, price = 5, amount = 50},
    {id = 3004, price = 5, amount = 50},
    {id = 526, price = 5, amount = 50},
    {id = 4584, price = 5, amount = 50},
    {id = 5666, price = 5, amount = 50},
    {id = 324, price = 5, amount = 50},
    {id = 340, price = 5, amount = 50},
    {id = 682, price = 5, amount = 50},
    {id = 5990, price = 5, amount = 50},
    {id = 454, price = 5, amount = 50},
    --{id = 25128, price = 10, amount = 10},
    --{id = 25054, price = 15, amount = 5},
}

local shopItemsPopular = {
    --{id = 1836, price = 100, amount = 1},
    --{id = 4956, price = 200, amount = 1},
    {id = 5638, price = 2500, amount = 1},
    {id = 5480, price = 3000, amount = 1},
}
-------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------
local function bal(p)          return p:getItemAmount(FARMTOKEN_ID) end
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
        padded = "  `9" .. str .. " `wFarmtoken  "
    elseif #str == 2 then
        padded = " " .. str .. " `wFarmtoken "
    else
        padded = str .. " `wFarmtoken"
    end

    local spacer = "`0   `9"
    return spacer .. padded .. spacer
end

-------------------------------------------------------------------
-- SHOP DIALOG
-------------------------------------------------------------------
local BUTTON_WIDTH    = 0.28
local BUTTONS_PER_ROW = 5

local function createFarmTokenShopDialog(p)
    local dlg = ("set_default_color|`o\n"
      .."set_custom_spacing|x:10;y:8|\n"
      .."add_label_with_icon|big|`wGardeners Market|left|%d|\n"
      .."add_spacer|small|\nadd_textbox|Welcome, pick your goodies to purchase!|left|\nadd_spacer|small|\n"
      .."add_label_with_icon|small|`oYou have `w%d `oFarmtokens|left|%d|\n"
      .."add_spacer|small|\n"
      .."add_spacer|small|\n")
      :format(SHOP_TRIGGER_ID, bal(p), FARMTOKEN_ID)

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

    section("Farmer Tools", shopItemsStarter, 2914, "staticBlueFrame")
    section("Farmables", shopItemsCrates,  2912, "staticBlueFrame")
    section("Special Items", shopItemsPopular, 25142, "staticBlueFrame")

    dlg = dlg .. "add_label|big||left|0|\nadd_quick_exit|\n"
       .. "add_button|back_to_main|`oBack|left|25019|\n"
       .. "end_dialog|farm_token_shop|||\n"
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
      ..("add_smalltext|`wPrice: `o%d Farmtoken|\n"):format(row.price)
      ..("add_smalltext|`wCurrent balance: `o%d Farmtoken|\n"):format(bal(p))
      .."add_spacer|small|\nadd_label_with_icon|big||left|"..row.id.."|\n"
      .."add_smalltext|`wItem Description:|\nadd_smalltext|`o"..it:getDescription().."|\n"
      ..("add_custom_button|farm_confirm_buy_%d|textLabel:`2Purchase for %d Farmtoken|\n"):format(idx, row.price)
      .."add_custom_break|\nadd_spacer|small|\nadd_button|back_to_main|`4Back|\nadd_custom_break|\n"
      .."add_label_with_icon|big||left|0|\nadd_quick_exit|\nend_dialog|farm_confirm_dialog|||\n"
    p:onDialogRequest(dlg)
end

-------------------------------------------------------------------
-- CALLBACKS
-------------------------------------------------------------------
onPlayerDialogCallback(function(_, p, d)
    local dlg, btn = d.dialog_name or "", d.buttonClicked or ""

    if dlg == "farm_token_shop" then
        local idx = tonumber(btn:match("^var_(%d+)$"))
        if idx then showConfirm(p, idx); return true end

    elseif dlg == "farm_confirm_dialog" then
        if btn == "back_to_main" then createFarmTokenShopDialog(p); return true end

        local idx = tonumber(btn:match("^farm_confirm_buy_(%d+)$")); if not idx then return true end
        local row = fetch(idx); if not row then return true end
        local it  = getItem(row.id)

        if bal(p) < row.price then
            p:onTalkBubble(p:getNetID(), "`4Not enough Farmtoken.", 1)
            return true
        end
        if p:getItemAmount(row.id) + row.amount > MAX_INVENTORY then
            p:onTalkBubble(p:getNetID(), "`4Not enough inventory space!", 0)
            return true
        end

        give(p, FARMTOKEN_ID, -row.price)
        give(p, row.id, row.amount)

        p:onTalkBubble(
            p:getNetID(),
            ("`2You purchased %d %s!"):format(row.amount, it:getName()),
            1
        )

        if p.playAudio then p:playAudio(18) elseif p.playSFX then p:playSFX(18) end
        p:onConsoleMessage(
            ("Bought %s x%d for %d Farmtoken"):format(it:getName(), row.amount, row.price)
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
        createFarmTokenShopDialog(p)
        return true
    end
    return false
end)