--=========================
-- TileDataProperties (FIX)
--=========================
TileDataProperties = TileDataProperties or {}
TileDataProperties.TILE_DATA_TYPE_SEED_FRUITS_COUNT = 0
TileDataProperties.TILE_DATA_TYPE_SEED_PLANTED_TIME = 1
TileDataProperties.TILE_DATA_TYPE_PLANTED = TileDataProperties.TILE_DATA_TYPE_SEED_PLANTED_TIME

--=========================
-- Konstanta & Keys
--=========================
local PIXEL           = 32
local CMD_AUTOPLANT   = "autoplant"
local CMD_RENT        = "rentap"
local CMD_BUY         = "buyap"

local KEY_DB          = "StorageDB_AUTOPLANT"
local KEY_RENT        = "StorageDB_RENT"

local AP_BGL_ID       = 7188
local AP_PRICE_BGL    = 1
local AP_DURATION_S   = 12 * 3600

local storage   = {}
local rstorage  = {}
local tmp_seen  = {}

--=========================
-- Helpers
--=========================
local function normalizeKeys(tbl)
  local out = {}
  for k, v in pairs(tbl or {}) do
    local key = tostring(k)
    out[key] = type(v) == "table" and normalizeKeys(v) or v
  end
  return out
end

local function fmtHMS(sec)
  if not sec or sec <= 0 then return "00:00:00" end
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

local function fmtFancy(sec)
  if not sec or sec <= 0 then return "0m" end
  local d = math.floor(sec / 86400)
  local h = math.floor((sec % 86400) / 3600)
  local m = math.floor((sec % 3600) / 60)
  local parts = {}
  if d > 0 then parts[#parts+1] = d .. "d" end
  if h > 0 then parts[#parts+1] = h .. "h" end
  if m > 0 then parts[#parts+1] = m .. "m" end
  return #parts > 0 and table.concat(parts, " ") or "0m"
end

local function getRentRemain(uid)
  local now = os.time()
  local exp = tonumber(rstorage[uid] or 0) or 0
  return exp > now, math.max(exp - now, 0), exp
end

local function rentStatusLine(uid)
  local active, remain = getRentRemain(uid)
  return active and string.format("`2Active`o (`#%s`` / %s left`o)", fmtFancy(remain), fmtHMS(remain)) or "`4Expired`o"
end

--=========================
-- Load DB (tanpa pcall)
--=========================
do
  local function try_json_decode_str(s)
    if type(s) ~= "string" or s == "" then return nil end
    local first = s:sub(1,1)
    if first ~= "{" and first ~= "[" then return nil end
    if json and json.decode then
      local t = json.decode(s)
      return type(t) == "table" and normalizeKeys(t) or nil
    end
    return nil
  end

  local function loadJSONorTable(key)
    local s = loadStringFromServer and loadStringFromServer(key) or ""
    local t = try_json_decode_str(s)
    if t then return t end
    local old = loadDataFromServer and loadDataFromServer(key) or nil
    return type(old) == "table" and normalizeKeys(old) or {}
  end

  storage  = loadJSONorTable(KEY_DB)
  rstorage = loadJSONorTable(KEY_RENT)
end

--=========================
-- Safe ops
--=========================
local function safeAdd(tbl, id, amount) tbl[tostring(id)] = (tbl[tostring(id)] or 0) + amount end
local function safeGet(tbl, id) return tbl[tostring(id)] or 0 end
local function safeSet(tbl, id, amount) tbl[tostring(id)] = amount end

local function getPlayerData(player)
  local uid = tostring(player:getUserID())
  storage = type(storage) == "table" and storage or {}
  storage[uid] = type(storage[uid]) == "table" and storage[uid] or {}
  return storage[uid]
end

local function saveRentDB()
  if saveStringToServer then
    saveStringToServer(KEY_RENT, json.encode(normalizeKeys(rstorage)))
  elseif saveDataToServer then
    saveDataToServer(KEY_RENT, normalizeKeys(rstorage))
  end
end

local function saveStorageDB()
  if saveStringToServer then
    saveStringToServer(KEY_DB, json.encode(normalizeKeys(storage)))
  elseif saveDataToServer then
    saveDataToServer(KEY_DB, normalizeKeys(storage))
  end
end

--=========================
-- GrowTime provider
--=========================
local TILE_DATA_TYPE_PLANTED = TileDataProperties.TILE_DATA_TYPE_PLANTED
local AP_PLANTED_MODE = "timestamp" -- "timestamp" | "remaining"
local USE_PROVIDER    = true

local function resolveSeedGrowTime(seed_id)
  local base = 0
  local item = getItem(seed_id)
  if item and item.getGrowTime then base = item:getGrowTime() or 0 end
  if USE_PROVIDER and _G.gsoft and gsoft.seed and type(gsoft.seed.getGrowTime) == "function" then
    local v = gsoft.seed.getGrowTime(seed_id)
    if type(v) == "number" and v > 0 then return v end
  end
  if USE_PROVIDER and _G.ProviderGrowTime and type(ProviderGrowTime[seed_id]) == "number" and ProviderGrowTime[seed_id] > 0 then
    return ProviderGrowTime[seed_id]
  end
  return base
end

local function encodePlantedValue(grow_s)
  return AP_PLANTED_MODE == "timestamp" and (os.time() + (tonumber(grow_s) or 0)) or (tonumber(grow_s) or 0)
end

--=========================
-- Access helper
--=========================
local function isWorldOwner(world, player)
  if world and world.getOwner then
    local owner = world:getOwner()
    if type(owner) == "userdata" and owner.getUserID then return owner:getUserID() == player:getUserID() end
    if type(owner) == "string" then return owner:lower() == player:getCleanName():lower() end
    if type(owner) == "number" then return owner == player:getUserID() end
  end
  return world and world.hasAccess and world:hasAccess(player) or false
end

--=========================
-- Register Commands
--=========================
registerLuaCommand({ command = CMD_AUTOPLANT, roleRequired = Roles and Roles.ROLE_NONE or 0,       description = "autoplant in current world (owner only)" })
registerLuaCommand({ command = CMD_RENT,      roleRequired = Roles and Roles.ROLE_DEVELOPER or 51, description = "admin rent panel for autoplant" })
registerLuaCommand({ command = CMD_BUY,       roleRequired = Roles and Roles.ROLE_NONE or 0,       description = "Buy 12h AutoPlant access (1 BGL)" })

--=========================
-- UI builders
--=========================
local function openAutoPlantUI(player)
  local uid = tostring(player:getUserID())
  local dlg = table.concat({
    "set_default_color|`o",
    "add_label_with_icon|big|Auto Plant|left|2|",
    "add_textbox|Automatically Plant Seed in current world|left|",
    "add_spacer|small|",
    "add_textbox|Access: "..rentStatusLine(uid).."|left|",
    "add_spacer|small|",
    "add_item_picker|inventory_seed|Inventory|Select Seed|",
    "add_button|storage_seed|Storage|noflags|0|0|",
    "add_spacer|medium|",
    "add_textbox|Restock Storage:|left|",
    "add_spacer|small|",
    "add_button|storage_stock|Restock|noflags|0|0|",
    "add_spacer|small|",
    "add_button|buyap_open|`2Buy Access (1 BGL/12h)|noflags|0|0|",
    "add_quick_exit|",
    "end_dialog|app_dialog||"
  }, "\n")
  player:onDialogRequest(dlg)
end

local function StorageUI(player, world)
  local uid = tostring(player:getUserID())
  local pdata = getPlayerData(player)
  local dlg = { "set_default_color|`o", "add_label_with_icon|big|Storage Plant|left|7188|", "add_textbox|Access: "..rentStatusLine(uid).."|left|", "add_spacer|small|" }
  local empty = true
  for id_str, count in pairs(pdata) do
    local id = tonumber(id_str)
    if id and count > 0 then
      local item = getItem(id)
      if item then
        empty = false
        dlg[#dlg+1] = string.format("add_label_with_icon|normal|%s %dx|left|%d|", item:getName(), count, id)
        dlg[#dlg+1] = string.format("add_button|plant_%d|Select|noflags|0|0|", id)
      end
    end
  end
  if empty then dlg[#dlg+1] = "add_textbox|`wStorage is empty.``|left|" end
  dlg[#dlg+1] = "add_spacer|medium|"
  dlg[#dlg+1] = "add_button|storage_stock|Restock|noflags|0|0|"
  dlg[#dlg+1] = "add_button|storage_back|Back|noflags|0|0|"
  dlg[#dlg+1] = "add_button|buyap_open|`2Buy Access (1 BGL/12h)|noflags|0|0|"
  dlg[#dlg+1] = "add_quick_exit|"
  dlg[#dlg+1] = "end_dialog|stp_dialog||"
  player:onDialogRequest(table.concat(dlg, "\n"))
end

local function getSelectedItemIDs(data)
  local ids = {}
  for k, v in pairs(data) do
    if k:sub(1,5) == "item_" and v == "1" then
      local id = tonumber(k:sub(6))
      if id then ids[#ids+1] = id end
    end
  end
  return ids
end

local function restockUI(player, world, page, parent_dialog)
  local uid = tostring(player:getUserID())
  local drops = world:getDroppedItems()
  if not drops or #drops == 0 then player:onTalkBubble(player:getNetID(), "`cNo dropped items found.", 0) return true end

  local merged = {}
  for _, d in ipairs(drops) do
    local id = d:getItemID()
    local it = getItem(id)
    if it and it.getName and it:getName():lower():match("seed$") then
      local cnt = d:getItemCount() or 1
      if not merged[id] then merged[id] = { id = id, count = cnt, uids = { d:getUID() } }
      else merged[id].count = merged[id].count + cnt; table.insert(merged[id].uids, d:getUID()) end
    end
  end
  if not next(merged) then player:onTalkBubble(player:getNetID(), "`cNo seed found.", 0) return true end

  local list = {}
  for _, v in pairs(merged) do list[#list+1] = v end
  table.sort(list, function(a, b)
    local ia, ib = getItem(a.id), getItem(b.id)
    return ia and ib and ia:getName() < ib:getName() or a.id < b.id
  end)

  local PER = 40
  page = math.max(1, tonumber(page) or 1)
  local maxPage = math.max(1, math.ceil(#list / PER))
  local sIdx, eIdx = (page - 1) * PER + 1, math.min(page * PER, #list)

  local buf = {}
  buf[#buf+1] = string.format("set_default_color|`o\nadd_label_with_icon|small|`#Restock Storage - `6Page %d/%d``|left|7188|", page, maxPage)
  buf[#buf+1] = "add_textbox|Access: "..rentStatusLine(uid).."|left|"
  buf[#buf+1] = "reset_placement_x|\nadd_spacer|small|\nadd_container|buttons_container|horizontal|spacing=5|"
  if page > 1 then buf[#buf+1] = "add_button|prev|`#<< Back``|noflags|0|0|" end
  if page < maxPage then buf[#buf+1] = "add_button|next|`#Next >>``|noflags|0|0|" end
  buf[#buf+1] = "end_container|\nadd_spacer|medium|"

  for i = sIdx, eIdx do
    local row = list[i]
    local it = getItem(row.id)
    if it then
      buf[#buf+1] = string.format("add_checkicon|item_%d|%s(`2%d`o)|noflags|%d||0|", row.id, it:getName(), row.count, row.id)
    end
  end

  buf[#buf+1] = "add_custom_break|\nreset_placement_x|\nadd_spacer|medium|"
  buf[#buf+1] = "add_button|add|`2Add to storage|noflags|0|0|"
  buf[#buf+1] = string.format("add_button|back_storage_%s|Back|noflags|0|0|", parent_dialog)
  buf[#buf+1] = "add_button|buyap_open|`2Buy Access (1 BGL/12h)|noflags|0|0|"
  buf[#buf+1] = string.format("end_dialog|restock_dialog_%d||", page)

  player:onDialogRequest(table.concat(buf, "\n"))
end

local function buildRentList()
  local buf = { "set_default_color|`o", "add_label_with_icon|big|Rent Form|left|20243|", "add_textbox|Manage Rent for Auto Plant.|left|", "add_spacer|small|" }
  for _, pl in pairs(getAllPlayers()) do
    local uid = tostring(pl:getUserID())
    buf[#buf+1] = "add_textbox|`w"..pl:getCleanName().."``: "..rentStatusLine(uid).."|left|"
    buf[#buf+1] = "add_button|rent_"..uid.."|Manage "..pl:getCleanName().."|noflags|0|0|"
    buf[#buf+1] = "add_spacer|small|"
  end
  buf[#buf+1] = "add_quick_exit|"
  buf[#buf+1] = "end_dialog|rent_dialog||"
  return table.concat(buf, "\n")
end

local function buildManageRentDialog(target)
  local uid = tostring(target:getUserID())
  local active, remain = getRentRemain(uid)
  local status = active and string.format("`2Active (`#%s`` / %s left`o)", fmtFancy(remain), fmtHMS(remain)) or "`4Expired`o"
  return table.concat({
    "set_default_color|`o",
    "add_label_with_icon|big|Manage "..target:getCleanName().."|left|242|",
    "add_textbox|Rent Status: "..status.."|left|",
    "add_spacer|small|",
    "add_button|rent_add|Add/Extend +1h|noflags|0|0|",
    "add_button|rent_remove|Remove Rent|noflags|0|0|",
    "add_spacer|medium|",
    "add_button|rent_back|Back|noflags|0|0|",
    "add_quick_exit|",
    "end_dialog|manage_rent_"..uid.."||"
  }, "\n")
end

--=========================
-- Core AutoPlant
--=========================
local function doAutoPlant(world, player, seed_id, amount_seed, useDB)
  local uid = tostring(player:getUserID())
  local now = os.time()
  local exp = tonumber(rstorage[uid] or 0) or 0
  if not player:hasRole(Roles and Roles.ROLE_DEVELOPER or 51) and exp <= now then
    player:onTalkBubble(player:getNetID(), "`4Access expired. Use /buyap first.", 0)
    return true
  end

  local item = getItem(seed_id)
  if not item or not item.getGrowTime or item:getGrowTime() <= 0 then
    player:onTalkBubble(player:getNetID(), "`cItem is not a valid seed!", 0)
    return true
  end
  if amount_seed <= 0 then
    player:onTalkBubble(player:getNetID(), "`cYou don't have any of that seed.", 0)
    return true
  end

  local growtime = math.max(resolveSeedGrowTime(seed_id), 0)

  -- kumpulkan tile kosong (FG=0) dan ada ground di bawah
  local tiles = world:getTiles()
  local map = {}
  for _, t in ipairs(tiles) do map[t:getPosX() .. "," .. t:getPosY()] = t end
  local targets = {}
  for _, t in ipairs(tiles) do
    local tid = t:getTileID()
    if not tid or tid == 0 then
      local x, y = t:getPosX(), t:getPosY()
      local below = map[x .. "," .. (y + PIXEL)]
      if below and below:getTileID() and below:getTileID() ~= 0 then targets[#targets+1] = t end
    end
  end

  if #targets == 0 then
    player:onTalkBubble(player:getNetID(), "`cNo suitable tiles found (need ground below).", 0)
    return true
  end

  local planted = 0
  for _, t in ipairs(targets) do
    if planted >= amount_seed then break end
    world:setTileForeground(t, seed_id)
    if t.setTileDataInt then t:setTileDataInt(0, math.random(1, 5))
    elseif t.setTileData then t:setTileData(0, math.random(1, 4)) end
    local plantedValue = encodePlantedValue(growtime)
    if t.setTileDataInt then t:setTileDataInt(TILE_DATA_TYPE_PLANTED, plantedValue)
    elseif t.setTileData then t:setTileData(TILE_DATA_TYPE_PLANTED, plantedValue) end
    world:updateTile(t)

    if useDB then
      local pdata = getPlayerData(player)
      safeSet(pdata, seed_id, math.max(safeGet(pdata, seed_id) - 1, 0))
    else
      player:changeItem(seed_id, -1, 0)
    end
    planted = planted + 1
  end

  player:onTalkBubble(player:getNetID(), string.format("`2AutoPlant success! Planted %d seed(s). `o(growtime: %ds)`2", planted, growtime), 0)
  return true
end

--=========================
-- BUY UI
--=========================
local function openBuyAPDialog(p)
  local uid = tostring(p:getUserID())
  local haveBGL = p:getItemAmount(AP_BGL_ID) or 0
  local canBuy = haveBGL >= AP_PRICE_BGL
  local dlg = {
    "set_default_color|`o",
    "add_label_with_icon|big|AutoPlant Access|left|"..AP_BGL_ID.."|",
    "add_textbox|Buy 12 hours of AutoPlant access. No refunds, chief.|left|",
    "add_spacer|small|",
    "add_textbox|Status: "..rentStatusLine(uid).."|left|",
    "add_textbox|You have BGL: `w"..haveBGL.."``, price: `w"..AP_PRICE_BGL.."``|left|",
    "add_spacer|small|",
    canBuy and "add_button|buyap_confirm|`2Buy 12h (1 BGL)|noflags|0|0|" or "add_button|buyap_insufficient|`4Not enough BGL|off|0|0|",
    "add_spacer|small|",
    "add_button|buyap_back|Back|noflags|0|0|",
    "add_quick_exit|",
    "end_dialog|buyap_dialog||"
  }
  p:onDialogRequest(table.concat(dlg, "\n"))
end

--=========================
-- Command Callback
--=========================
onPlayerCommandCallback(function(w, p, full)
  local cmd = full:lower()

  if cmd == CMD_AUTOPLANT then
    if not isWorldOwner(w, p) then p:onTalkBubble(p:getNetID(), "`cOnly world owner (or access holder) can use this.", 0) return true end
    local uid = tostring(p:getUserID())
    if not p:hasRole(Roles and Roles.ROLE_DEVELOPER or 51) then
      if not rstorage[uid] or rstorage[uid] == 0 then p:onTalkBubble(p:getNetID(), "`bYou need to buy access with /buyap!", 0) return true end
      if os.time() > (tonumber(rstorage[uid]) or 0) then p:onTalkBubble(p:getNetID(), "`bYour access has expired. Use /buyap.", 0) return true end
    end
    openAutoPlantUI(p)
    return true
  end

  if cmd == CMD_RENT then
    if not p:hasRole(Roles and Roles.ROLE_DEVELOPER or 51) then return false end
    p:onDialogRequest(buildRentList())
    return true
  end

  if cmd == CMD_BUY then
    openBuyAPDialog(p)
    return true
  end

  return false
end)

--=========================
-- Dialog Callback
--=========================
onPlayerDialogCallback(function(world, player, data)
  local name, clicked = data["dialog_name"], data["buttonClicked"]

  -- BUY
  if name == "buyap_dialog" then
    if clicked == "buyap_back" then openAutoPlantUI(player) return true end
    if clicked == "buyap_confirm" then
      local uid = tostring(player:getUserID())
      local now = os.time()
      local exp = tonumber(rstorage[uid] or 0) or 0
      local have = player:getItemAmount(AP_BGL_ID) or 0
      if have < AP_PRICE_BGL then player:onTalkBubble(player:getNetID(), "`4You don't have enough BGL.", 0) openBuyAPDialog(player) return true end
      if not player:changeItem(AP_BGL_ID, -AP_PRICE_BGL, 0) then player:onTalkBubble(player:getNetID(), "`4Payment failed. Try again.", 0) openBuyAPDialog(player) return true end
      local newExp = (exp > now) and (exp + AP_DURATION_S) or (now + AP_DURATION_S)
      rstorage[uid] = newExp
      saveRentDB()
      local remain = newExp - now
      player:onConsoleMessage("`2AutoPlant access purchased. Expires in `o"..fmtHMS(remain).." (`#"..fmtFancy(remain).."``).")
      player:onTalkBubble(player:getNetID(), "`2Purchase successful!", 0)
      player:onTextOverlay("`2AutoPlant +12h activated!`o")
      openBuyAPDialog(player)
      return true
    end
    return true
  end

  -- MAIN
  if name == "app_dialog" then
    if clicked == "buyap_open"   then openBuyAPDialog(player) return true end
    if clicked == "storage_seed" then StorageUI(player, world) return true end
    if clicked == "storage_stock" then restockUI(player, world, 1, "app_dialog") return true end
    local seed_id = data["inventory_seed"]
    if seed_id then doAutoPlant(world, player, seed_id, player:getItemAmount(seed_id), false) return true end
    return true
  end

  -- RESTOCK
  if name and name:match("^restock_dialog_") then
    local page = tonumber(name:match("restock_dialog_(%d+)")) or 1
    if clicked == "prev"         then restockUI(player, world, page - 1, "app_dialog") return true end
    if clicked == "next"         then restockUI(player, world, page + 1, "app_dialog") return true end
    if clicked == "buyap_open"   then openBuyAPDialog(player) return true end
    if clicked and clicked:match("^back_storage_") then
      local parent = clicked:sub(14)
      if parent == "stp_dialog" then StorageUI(player, world) else openAutoPlantUI(player) end
      return true
    end
    if clicked == "add" then
      local ids = getSelectedItemIDs(data)
      if #ids == 0 then player:onTalkBubble(player:getNetID(), "`cNo items selected!", 0) return true end
      local drops = world:getDroppedItems()
      local merged = {}
      for _, d in ipairs(drops) do
        local id = d:getItemID()
        local it = getItem(id)
        if it and it.getName and it:getName():lower():match("seed$") then
          local cnt = d:getItemCount() or 1
          if not merged[id] then merged[id] = { count = cnt, uids = { d:getUID() } }
          else merged[id].count = merged[id].count + cnt; table.insert(merged[id].uids, d:getUID()) end
        end
      end
      local pdata = getPlayerData(player)
      for _, id in ipairs(ids) do
        local dat = merged[id]
        if dat then
          safeAdd(pdata, id, dat.count)
          for _, uid in ipairs(dat.uids) do world:removeDroppedItem(uid) end
        end
      end
      saveStorageDB()
      player:onTalkBubble(player:getNetID(), "`2Added selected seeds to storage!", 0)
      StorageUI(player, world)
      return true
    end
    return true
  end

  -- STORAGE
  if name == "stp_dialog" then
    if clicked == "storage_back"  then openAutoPlantUI(player) return true end
    if clicked == "storage_stock" then restockUI(player, world, 1, "stp_dialog") return true end
    if clicked == "buyap_open"    then openBuyAPDialog(player) return true end
    local pid = clicked and clicked:match("^plant_(%d+)$")
    if pid then
      local id = tonumber(pid)
      local have = safeGet(getPlayerData(player), id)
      if have > 0 then doAutoPlant(world, player, id, have, true)
      else player:onTalkBubble(player:getNetID(), "`cYou don't have that seed in storage.", 0) end
      return true
    end
    return true
  end

  -- RENT LIST
  if name == "rent_dialog" then
    local pid = clicked and clicked:match("^rent_(%d+)$")
    if pid then
      local uid = tonumber(pid)
      local target
      for _, pl in pairs(getAllPlayers()) do if pl:getUserID() == uid then target = pl break end end
      if not target then player:onTalkBubble(player:getNetID(), "`cPlayer not found.", 0) return true end
      player:onDialogRequest(buildManageRentDialog(target))
      return true
    end
    return true
  end

  -- MANAGE RENT
  if name and name:match("^manage_rent_%d+$") then
    local uidn = tonumber(name:match("^manage_rent_(%d+)$"))
    local target
    for _, pl in pairs(getAllPlayers()) do if pl:getUserID() == uidn then target = pl break end end
    if not target then player:onTalkBubble(player:getNetID(), "`cPlayer not found.", 0) return true end

    local uid = tostring(uidn)
    local now = os.time()
    local cur = tonumber(rstorage[uid]) or 0

    if clicked == "rent_add" then
      local add = 3600
      local newExp = (cur > now) and (cur + add) or (now + add)
      rstorage[uid] = newExp
      saveRentDB()
      local remain = newExp - now
      player:onTalkBubble(player:getNetID(), "`2Rent extended, expires in `#"..fmtFancy(remain).."`` ("..fmtHMS(remain)..")", 0)
      return true
    end

    if clicked == "rent_remove" then
      rstorage[uid] = 0
      saveRentDB()
      player:onTalkBubble(player:getNetID(), "`4Removed rent for `6"..target:getName(), 0)
      return true
    end

    if clicked == "rent_back" then
      player:onDialogRequest(buildRentList())
      return true
    end
    return true
  end

  return false
end)

--=========================
-- Tick & Disconnect
--=========================
onPlayerTick(function(player)
  local uid = tostring(player:getUserID())
  local exp = tonumber(rstorage[uid] or 0) or 0
  local now = os.time()

  if exp > now and not tmp_seen[uid] then
    tmp_seen[uid] = true
    local remaining = exp - now
    player:onConsoleMessage(string.format("`2Your AutoPlant access: `o%s (%s)", fmtHMS(remaining), fmtFancy(remaining)))
  end
  if exp > 0 and exp <= now then tmp_seen[uid] = nil end
end)

onPlayerDisconnectCallback(function(player)
  tmp_seen[tostring(player:getUserID())] = nil
end)

--=========================
-- AutoSave
--=========================
onAutoSaveRequest(function()
  saveStringToServer(KEY_DB,   json.encode(normalizeKeys(storage)))
  saveStringToServer(KEY_RENT, json.encode(normalizeKeys(rstorage)))
end)
