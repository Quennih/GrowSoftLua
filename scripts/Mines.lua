print("(Loaded) Mines DEMO by Paboz")

local Roles = {
    ROLE_DEFAULT = 0,
    ROLE_DEVELOPER = 51
}

local MINES_SAVE_KEY = "PABOZ_MINES_CONFIG_DEMO"

local mines_state = {}

local LockIDs = {
    WL = 242,
    DL = 1796,
    BGL = 7188,
    BBGL = 20628
}

local LockValues = {
    WL = 1,
    DL = 100,
    BGL = 10000,
    BBGL = 1000000
}

local MinesConfig = {
    MAX_LOCK_STACK = 200,
    MAX_WINNINGS_IN_WL = 202020200
}

local sessionState = {}

local function mines_saveState()
    saveDataToServer(MINES_SAVE_KEY, mines_state)
end

local function mines_loadState()
    local loadedData = loadDataFromServer(MINES_SAVE_KEY)
    local defaultState = {
        maxMultiplier = 10,
        taxPercent = 5,
        minMines = 2,
        maxMines = 15,
        gridSize = 5
    }
    if loadedData and type(loadedData) == "table" then
        for key, value in pairs(defaultState) do
            if loadedData[key] == nil then
                loadedData[key] = value
            end
        end
        mines_state = loadedData
    else
        mines_state = defaultState
    end
end

local function mines_getPlayerBalanceInWLs(player)
    local total = 0
    total = total + (player:getItemAmount(LockIDs.WL) * LockValues.WL)
    total = total + (player:getItemAmount(LockIDs.DL) * LockValues.DL)
    total = total + (player:getItemAmount(LockIDs.BGL) * LockValues.BGL)
    total = total + (player:getItemAmount(LockIDs.BBGL) * LockValues.BBGL)
    return total
end

local function mines_calculateLockCombination(totalWLs)
    local combo = { WL = 0, DL = 0, BGL = 0, BBGL = 0 }
    if totalWLs <= 0 then return combo end
    local remaining = math.floor(totalWLs)
    combo.BBGL = math.floor(remaining / LockValues.BBGL); remaining = remaining % LockValues.BBGL
    combo.BGL = math.floor(remaining / LockValues.BGL); remaining = remaining % LockValues.BGL
    combo.DL = math.floor(remaining / LockValues.DL); remaining = remaining % LockValues.DL
    combo.WL = remaining
    return combo
end

local function mines_executePayment(player, costInWLs)
    local currentBalance = mines_getPlayerBalanceInWLs(player)
    if currentBalance < costInWLs then return false end
    local newBalance = currentBalance - costInWLs
    local currentLocks = {
        WL = player:getItemAmount(LockIDs.WL), DL = player:getItemAmount(LockIDs.DL),
        BGL = player:getItemAmount(LockIDs.BGL), BBGL = player:getItemAmount(LockIDs.BBGL)
    }
    local targetLocks = mines_calculateLockCombination(newBalance)
    player:changeItem(LockIDs.WL, targetLocks.WL - currentLocks.WL, 0)
    player:changeItem(LockIDs.DL, targetLocks.DL - currentLocks.DL, 0)
    player:changeItem(LockIDs.BGL, targetLocks.BGL - currentLocks.BGL, 0)
    player:changeItem(LockIDs.BBGL, targetLocks.BBGL - currentLocks.BBGL, 0)
    return true
end

local function mines_addLocks(player, totalWLs)
    if totalWLs <= 0 then return end
    local combo = mines_calculateLockCombination(totalWLs)
    if combo.BBGL > 0 then player:changeItem(LockIDs.BBGL, combo.BBGL, 0) end
    if combo.BGL > 0 then player:changeItem(LockIDs.BGL, combo.BGL, 0) end
    if combo.DL > 0 then player:changeItem(LockIDs.DL, combo.DL, 0) end
    if combo.WL > 0 then player:changeItem(LockIDs.WL, combo.WL, 0) end
end

local function mines_checkInventorySpace(player, locksToAdd)
    local freeSlots = player:getInventorySize() - player:getBackpackUsedSize()
    local neededSlots = 0
    local lockTypes = {
        { id = LockIDs.BBGL, amount = locksToAdd.BBGL }, { id = LockIDs.BGL, amount = locksToAdd.BGL },
        { id = LockIDs.DL, amount = locksToAdd.DL }, { id = LockIDs.WL, amount = locksToAdd.WL }
    }
    for _, lock in ipairs(lockTypes) do
        if lock.amount > 0 then
            local currentAmount = player:getItemAmount(lock.id)
            if currentAmount > 0 then
                local spaceInLastStack = MinesConfig.MAX_LOCK_STACK - (currentAmount % MinesConfig.MAX_LOCK_STACK)
                if spaceInLastStack ~= MinesConfig.MAX_LOCK_STACK then
                    local remainingToAdd = lock.amount - spaceInLastStack
                    if remainingToAdd > 0 then neededSlots = neededSlots + math.ceil(remainingToAdd / MinesConfig.MAX_LOCK_STACK) end
                else neededSlots = neededSlots + math.ceil(lock.amount / MinesConfig.MAX_LOCK_STACK) end
            else neededSlots = neededSlots + math.ceil(lock.amount / MinesConfig.MAX_LOCK_STACK) end
        end
    end
    return freeSlots >= neededSlots
end

local function mines_formatPriceInLocks(totalWLs)
    if not totalWLs or totalWLs <= 0 then return "0 WL" end
    local parts = {}; local combo = mines_calculateLockCombination(totalWLs)
    if combo.BBGL > 0 then table.insert(parts, combo.BBGL .. " BBGL") end
    if combo.BGL > 0 then table.insert(parts, combo.BGL .. " BGL") end
    if combo.DL > 0 then table.insert(parts, combo.DL .. " DL") end
    if combo.WL > 0 then table.insert(parts, combo.WL .. " WL") end
    return #parts > 0 and table.concat(parts, ", ") or "0 WL"
end

local function factorial(n)
    if n < 0 then return 0 end; if n == 0 then return 1 end
    local r = 1; for i = 1, n do r = r * i end; return r
end

local function combinations(n, k)
    if k < 0 or k > n then return 0 end; if k == 0 or k == n then return 1 end
    if k > n / 2 then k = n - k end
    return factorial(n) / (factorial(k) * factorial(n - k))
end

local function calculate_multiplier(revealed_count, mine_count)
    if revealed_count == 0 then return 1 end
    local total_tiles = mines_state.gridSize * mines_state.gridSize
    local num = combinations(total_tiles, revealed_count)
    local den = combinations(total_tiles - mine_count, revealed_count)
    if den == 0 then return 0 end
    local tax = mines_state.taxPercent / 100
    return (num / den) * (1 - tax)
end

local function reset_player_state(player)
    local netID = player:getNetID()
    sessionState[netID] = { isActive = false, betAmountInWL = 100, mineGrid = {}, revealedGrid = {}, safeTilesClicked = 0, currentMultiplier = 1 }
end

local function build_admin_panel(player)
    local dialog = {}; table.insert(dialog, "set_bg_color|0,0,139,127|\nset_border_color|0,0,255,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n"); table.insert(dialog, "add_label_with_icon|big|`wMines Admin Panel|left|32|\n")
    table.insert(dialog, "add_smalltext|`oConfigure the global settings for the Mines game.`o|\n"); table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_text_input|grid_size|Grid Size (3-8):|"..mines_state.gridSize.."|2|numeric|\n")
    table.insert(dialog, "add_text_input|min_mines|Min Mines:|" .. mines_state.minMines .. "|2|numeric|\n")
    table.insert(dialog, "add_text_input|max_mines|Max Mines:|" .. mines_state.maxMines .. "|2|numeric|\n")
    table.insert(dialog, "add_text_input|max_multiplier|Max Multiplier:|" .. mines_state.maxMultiplier .. "|9|numeric|\n")
    table.insert(dialog, "add_text_input|tax_percent|Tax (%):|" .. mines_state.taxPercent .. "|3|numeric|\n")
    table.insert(dialog, "add_spacer|small|\n"); table.insert(dialog, "add_button|save_settings|`2Save Settings|noflags|\n")
    table.insert(dialog, "add_quick_exit|\n"); table.insert(dialog, "end_dialog|mines_admin_panel|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function build_mines_dialog(player)
    local netID = player:getNetID()
    if not sessionState[netID] then reset_player_state(player) end
    local state = sessionState[netID]
    local dialog = {}; table.insert(dialog, "set_bg_color|0,0,139,127|\nset_border_color|0,0,255,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")

    if not state.isActive then
        table.insert(dialog, "add_label_with_icon|big|`wMines|left|6994|\n")
        table.insert(dialog, "add_smalltext|`oThe value of your bet determines the number of mines.`o|\n")
        table.insert(dialog, "add_spacer|small|\n")
        table.insert(dialog, "add_text_input|bet_amount|Bet Amount (in WL):|" .. (state.betAmountInWL or 100) .. "|9|numeric|\n")
        table.insert(dialog, "add_spacer|small|\n")
        table.insert(dialog, "add_button|start_game|`2Place Bet|noflags|\n")
    else
        local displayMultiplier = math.min(state.currentMultiplier, mines_state.maxMultiplier)
        local profit = state.betAmountInWL * displayMultiplier
        local cappedProfit = math.min(profit, MinesConfig.MAX_WINNINGS_IN_WL)
        local profitString = mines_formatPriceInLocks(cappedProfit)
        table.insert(dialog, "add_label|medium|`wMultiplier: `^" .. string.format("%.2f", displayMultiplier) .. "x`w|\n")
        table.insert(dialog, "add_label|medium|`wProfit: `^" .. profitString .. "`w|\n")
        
        local total_tiles = mines_state.gridSize * mines_state.gridSize
        local gem_count = total_tiles - state.mineCount
        table.insert(dialog, string.format("add_label_with_icon|small|`w%d|left|6994|\n", state.mineCount))
        table.insert(dialog, string.format("add_label_with_icon|small|`w%d|left|20534|\n", gem_count))
        table.insert(dialog, "add_custom_break|\n"); table.insert(dialog, "add_spacer|small|\n")
        
        for r = 1, mines_state.gridSize do
            for c = 1, mines_state.gridSize do
                local tileValue = state.revealedGrid[r][c]
                if tileValue == 'hidden' then
                    table.insert(dialog, string.format("add_button_with_icon|mine_%d_%d||staticBlueFrame|0||\n", r, c))
                else
                    local iconID = 0
                    if tileValue == 'gem' then iconID = 20534 elseif tileValue == 'mine' then iconID = 1430 end
                    table.insert(dialog, string.format("add_button_with_icon|mine_%d_%d||noflags|%d||\n", r, c, iconID))
                end
            end
            table.insert(dialog, "add_custom_break|\n")
        end
        
        table.insert(dialog, "add_spacer|small|\n")
        table.insert(dialog, "add_button|cash_out|`2Cash Out " .. profitString .. "|noflags|\n")
    end
    
    table.insert(dialog, "add_quick_exit|\n"); table.insert(dialog, "end_dialog|mines_game|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function start_game(player, betInWL)
    if betInWL <= 0 then player:onConsoleMessage("`4Bet amount must be greater than zero."); player:playAudio("bleep_fail.wav", 0); return end
    if mines_getPlayerBalanceInWLs(player) < betInWL then player:onConsoleMessage("`4You do not have enough locks to place that bet."); player:playAudio("bleep_fail.wav", 0); return end
    
    local min = mines_state.minMines; local max = mines_state.maxMines; local final_mines
    if betInWL >= LockValues.BBGL then final_mines = max
    elseif betInWL >= LockValues.BGL then final_mines = min + math.floor((max - min) * 0.66)
    elseif betInWL >= LockValues.DL then final_mines = min + math.floor((max - min) * 0.33)
    else final_mines = min end
    final_mines = math.max(min, math.min(final_mines, max))

    if not mines_executePayment(player, betInWL) then player:onConsoleMessage("`4Payment failed. Please try again."); player:playAudio("bleep_fail.wav", 0); return end
    
    local netID = player:getNetID()
    sessionState[netID] = { isActive = true, betAmountInWL = betInWL, mineCount = final_mines, mineGrid = {}, revealedGrid = {}, safeTilesClicked = 0, currentMultiplier = 1 }
    
    local total_tiles = mines_state.gridSize * mines_state.gridSize
    local positions = {}; for i=1, total_tiles do table.insert(positions, i) end
    for i = #positions, 2, -1 do local j = math.random(i); positions[i], positions[j] = positions[j], positions[i] end

    for r = 1, mines_state.gridSize do
        sessionState[netID].mineGrid[r] = {}; sessionState[netID].revealedGrid[r] = {}
        for c = 1, mines_state.gridSize do 
            sessionState[netID].revealedGrid[r][c] = 'hidden'
            sessionState[netID].mineGrid[r][c] = 'gem'
        end
    end

    for i = 1, final_mines do
        local pos_1d = positions[i]
        local r = math.floor((pos_1d - 1) / mines_state.gridSize) + 1
        local c = ((pos_1d - 1) % mines_state.gridSize) + 1
        sessionState[netID].mineGrid[r][c] = 'mine'
    end
    
    player:onConsoleMessage("`oYour bet of `w" .. mines_formatPriceInLocks(betInWL) .. "`o will be played with `w" .. final_mines .. "`o mine(s).")
    build_mines_dialog(player)
end

local function handle_tile_click(player, r, c)
    local netID = player:getNetID(); local state = sessionState[netID]
    if not state or not state.isActive or state.revealedGrid[r][c] ~= 'hidden' then return end

    if state.mineGrid[r][c] == 'mine' then
        player:onConsoleMessage("`4Boom! You hit a mine. Game over."); player:playAudio("explode.wav", 0)
        state.isActive = false
        for i = 1, mines_state.gridSize do for j = 1, mines_state.gridSize do if state.mineGrid[i][j] == 'mine' then state.revealedGrid[i][j] = 'mine' end end end
    else
        player:playAudio("click.wav", 0); state.revealedGrid[r][c] = 'gem'; state.safeTilesClicked = state.safeTilesClicked + 1
        state.currentMultiplier = calculate_multiplier(state.safeTilesClicked, state.mineCount)
    end
    
    build_mines_dialog(player)
end

local function cash_out(player)
    local netID = player:getNetID(); local state = sessionState[netID]
    if not state or not state.isActive or state.safeTilesClicked == 0 then return end
    
    local finalMultiplier = math.min(state.currentMultiplier, mines_state.maxMultiplier)
    local totalReturn = math.floor(state.betAmountInWL * finalMultiplier)
    
    if totalReturn > MinesConfig.MAX_WINNINGS_IN_WL then
        totalReturn = MinesConfig.MAX_WINNINGS_IN_WL
        player:onConsoleMessage("`oYour winnings have been capped at the maximum limit.`o")
    end

    local locksToPayout = mines_calculateLockCombination(totalReturn)

    if not mines_checkInventorySpace(player, locksToPayout) then
        player:onConsoleMessage("`4You do not have enough inventory space to cash out. Please clear some space and try again.")
        player:playAudio("bleep_fail.wav", 0)
        return
    end

    mines_addLocks(player, totalReturn)
    player:onConsoleMessage("`2You cashed out and won `w" .. mines_formatPriceInLocks(totalReturn) .. "`2!")
    player:playAudio("cash_register.wav", 0)
    local lastBet = state.betAmountInWL
    reset_player_state(player)
    sessionState[netID].betAmountInWL = lastBet
    build_mines_dialog(player)
end

registerLuaCommand({ command = "mines", roleRequired = Roles.ROLE_DEFAULT, description = "Opens the Mines gambling game." })
registerLuaCommand({ command = "minesadmin", roleRequired = Roles.ROLE_DEVELOPER, description = "Opens the Mines admin panel." })

onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)")
    if command == "mines" then reset_player_state(player); build_mines_dialog(player); return true
    elseif command == "minesadmin" and player:hasRole(Roles.ROLE_DEVELOPER) then build_admin_panel(player); return true end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    if not data then return false end
    local dialogName = data.dialog_name or ""; local button = data.buttonClicked or ""
    
    if dialogName == "mines_game" then
        local netID = player:getNetID()
        if not sessionState[netID] then reset_player_state(player) end
        if button == "start_game" then
            local betInWL = tonumber(data.bet_amount) or 0
            sessionState[netID].betAmountInWL = betInWL; start_game(player, betInWL); return true
        elseif button == "cash_out" then cash_out(player); return true end
        local row, col = button:match("^mine_(%d+)_(%d+)$")
        if row and col then handle_tile_click(player, tonumber(row), tonumber(col)); return true end
    end
    
    if dialogName == "mines_admin_panel" and player:hasRole(Roles.ROLE_DEVELOPER) then
        if button == "save_settings" then
            local newGridSize = tonumber(data.grid_size)
            local newMinMines = tonumber(data.min_mines)
            local newMaxMines = tonumber(data.max_mines)
            local newMaxMult = tonumber(data.max_multiplier)
            local newTax = tonumber(data.tax_percent)
            if not (newGridSize and newMinMines and newMaxMines and newMaxMult and newTax) then player:onConsoleMessage("`4Invalid input. All fields must be numbers."); return true end

            if newGridSize < 3 or newGridSize > 8 then player:onConsoleMessage("`4Grid Size must be between 3 and 8."); player:playAudio("bleep_fail.wav", 0); return true end
            local maxMinesAllowed = (newGridSize * newGridSize) - 1
            if newMinMines < 1 or newMaxMines > maxMinesAllowed or newMinMines >= newMaxMines then
                player:onConsoleMessage("`4Invalid mine range. Min must be >= 1, Max must be <= " .. maxMinesAllowed .. ", and Min must be less than Max."); player:playAudio("bleep_fail.wav", 0); return true
            end
            if newMaxMult <= 1 then player:onConsoleMessage("`4Multiplier must be greater than 1."); player:playAudio("bleep_fail.wav", 0); return true end
            if newTax < 0 or newTax > 100 then player:onConsoleMessage("`4Tax must be between 0 and 100."); player:playAudio("bleep_fail.wav", 0); return true end

            mines_state.gridSize = newGridSize; mines_state.minMines = newMinMines; mines_state.maxMines = newMaxMines
            mines_state.maxMultiplier = newMaxMult; mines_state.taxPercent = newTax
            mines_saveState()
            player:onConsoleMessage("`2Mines settings have been updated."); player:playAudio("success.wav", 0)
            build_admin_panel(player)
            return true
        end
    end
    
    return false
end)

onPlayerDisconnectCallback(function(player)
    if sessionState[player:getNetID()] then sessionState[player:getNetID()] = nil end
end)

onAutoSaveRequest(function()
    mines_saveState()
end)

mines_loadState()