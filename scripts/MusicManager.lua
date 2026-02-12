print("(Loaded) Music Manager by Paboz")

local serverID = getServerID()

local mm_Config = {
    ADMIN_COMMAND = "musicadmin",
    PLAYER_COMMAND = "music",
    REMOVE_COMMAND = "removemusic",
    SAVE_KEY_GLOBAL = "PABOZ_MUSIC_GLOBAL_V1",
    SAVE_KEY_WHITELIST = "PABOZ_MUSIC_WHITELIST",
    SAVE_KEY_SPECIFIC = "PABOZ_MUSIC_SPECIFIC",
    SAVE_KEY_PLAYER_SONGS = "PABOZ_MUSIC_PLAYER_SONGS",
    BASE_PATH = "audio/server_",
    globalMusic = {},
    whitelistedWorlds = {},
    specificWorldMusic = {},
    playerSongs = {}
}

local Roles = {
    ROLE_DEVELOPER = 51,
    ROLE_DEFAULT = 0
}

local mm_sessionState = {}

local function mm_saveConfig()
    saveDataToServer(mm_Config.SAVE_KEY_GLOBAL, mm_Config.globalMusic)
    saveDataToServer(mm_Config.SAVE_KEY_WHITELIST, mm_Config.whitelistedWorlds)
    saveDataToServer(mm_Config.SAVE_KEY_SPECIFIC, mm_Config.specificWorldMusic)
    saveDataToServer(mm_Config.SAVE_KEY_PLAYER_SONGS, mm_Config.playerSongs)
end

local function mm_loadConfig()
    local loadedGlobal = loadDataFromServer(mm_Config.SAVE_KEY_GLOBAL)
    mm_Config.globalMusic = (loadedGlobal and type(loadedGlobal) == "table") and loadedGlobal or {}

    local loadedWhitelist = loadDataFromServer(mm_Config.SAVE_KEY_WHITELIST)
    mm_Config.whitelistedWorlds = (loadedWhitelist and type(loadedWhitelist) == "table") and loadedWhitelist or {}

    local loadedSpecific = loadDataFromServer(mm_Config.SAVE_KEY_SPECIFIC)
    mm_Config.specificWorldMusic = (loadedSpecific and type(loadedSpecific) == "table") and loadedSpecific or {}

    local loadedPlayerSongs = loadDataFromServer(mm_Config.SAVE_KEY_PLAYER_SONGS)
    mm_Config.playerSongs = (loadedPlayerSongs and type(loadedPlayerSongs) == "table") and loadedPlayerSongs or {}
    
    print("[MusicManager] All configurations loaded and validated.")
end

local function mm_buildAdminMenu(player)
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wMusic Admin Panel|left|32|\n")
    table.insert(dialog, "add_smalltext|`oManage global, specific, and whitelisted world music.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|admin_global|`wSet Global Music|noflags|\n")
    table.insert(dialog, "add_button|admin_specific|`wManage Specific World Music|noflags|\n")
    table.insert(dialog, "add_button|admin_whitelist|`wManage Whitelist|noflags|\n")
    table.insert(dialog, "add_button|admin_player_music|`wManage Player Music|noflags|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|admin_help|`wHelp / Info|noflags|\n")
    table.insert(dialog, "add_quick_exit|\n")
    table.insert(dialog, "end_dialog|mm_admin_main|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildHelpDialog(player)
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wHow Music Works|left|32|\n")
    table.insert(dialog, "add_smalltext|`oThe system uses a priority list to decide which music to play.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_label|medium|`wMusic Priority Order`w|\n")
    table.insert(dialog, "add_textbox|`o1. `wSpecific World Music`o: This always plays if set for a world. It is the highest priority.`o|\n")
    table.insert(dialog, "add_textbox|`o2. `wWhitelist`o: If a world is on the whitelist, NO automatic music will play. This overrides the Global Music setting.`o|\n")
    table.insert(dialog, "add_textbox|`o3. `wGlobal Music`o: If a song is set here, it will play in every world that is NOT whitelisted and does NOT have specific music.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|admin_back|Back to Admin Panel|noflags|\n")
    table.insert(dialog, "end_dialog|mm_help_dialog|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildGlobalEditor(player)
    local currentFile = mm_Config.globalMusic.file or ""
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wSet Global Music|left|9474|\n")
    table.insert(dialog, "add_smalltext|`oThis song will play in every world unless overridden or whitelisted. Leave blank to disable.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_text_input|global_music_file|Music File (e.g., theme.mp3):|" .. currentFile .. "|60|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|global_save|`2Save|noflags|\n")
    table.insert(dialog, "add_button|admin_back|Back|noflags|\n")
    table.insert(dialog, "end_dialog|mm_global_editor|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildSpecificManager(player, editWorld, editMusic)
    editWorld = editWorld or ""
    editMusic = editMusic or ""
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wSpecific World Music|left|1442|\n")
    table.insert(dialog, "add_smalltext|`oAssign a unique song to a world. This has the highest priority.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_text_input|specific_world|World Name:|" .. editWorld .. "|24|\n")
    table.insert(dialog, "add_text_input|specific_music|Music File (e.g., start.mp3):|" .. editMusic .. "|60|\n")
    table.insert(dialog, "add_button|specific_save|`2Add/Update Mapping|noflags|\n")
    table.insert(dialog, "add_spacer|small|\n")
    if next(mm_Config.specificWorldMusic) ~= nil then
        table.insert(dialog, "add_label|medium|`wCurrent Mappings`w|\n")
        for worldName, musicFile in pairs(mm_Config.specificWorldMusic) do
            table.insert(dialog, "add_textbox|`w" .. worldName .. " `o-> " .. musicFile .. "`o|\n")
            table.insert(dialog, "add_button|specific_edit_" .. worldName .. "|Edit|noflags|\n")
            table.insert(dialog, "add_button|specific_remove_" .. worldName .. "|`4Remove|noflags|\n")
        end
    end
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|admin_back|Back|noflags|\n")
    table.insert(dialog, "end_dialog|mm_specific_manager|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildWhitelistManager(player)
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wMusic Whitelist|left|1430|\n")
    table.insert(dialog, "add_smalltext|`oWorlds on this list will not play the global music track.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_text_input|whitelist_world|World Name to Add:||24|\n")
    table.insert(dialog, "add_button|whitelist_add|`2Add to Whitelist|noflags|\n")
    table.insert(dialog, "add_spacer|small|\n")
    if next(mm_Config.whitelistedWorlds) ~= nil then
        table.insert(dialog, "add_label|medium|`wWhitelisted Worlds`w|\n")
        for worldName, _ in pairs(mm_Config.whitelistedWorlds) do
            table.insert(dialog, "add_textbox|`w" .. worldName .. "`o|\n")
            table.insert(dialog, "add_button|whitelist_remove_" .. worldName .. "|`4Remove|noflags|\n")
        end
    end
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|admin_back|Back|noflags|\n")
    table.insert(dialog, "end_dialog|mm_whitelist_manager|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildPlayerMusicManager(player)
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wManage Player Music|left|9474|\n")
    table.insert(dialog, "add_smalltext|`oAdd, edit, or remove songs from the /music player.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|pmusic_add_new|`2Add New Song|noflags|\n")
    table.insert(dialog, "add_spacer|small|\n")
    if #mm_Config.playerSongs == 0 then
        table.insert(dialog, "add_textbox|`oNo player songs have been configured.`o|\n")
    else
        table.insert(dialog, "add_label|medium|`wCurrent Songs`w|\n")
        for i, song in ipairs(mm_Config.playerSongs) do
            table.insert(dialog, "add_textbox|`w" .. song.title .. " `o-> " .. song.file .. "`o|\n")
            table.insert(dialog, "add_button|pmusic_edit_" .. i .. "|Edit|noflags|\n")
            table.insert(dialog, "add_button|pmusic_remove_" .. i .. "|`4Remove|noflags|\n")
        end
    end
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|admin_back|Back|noflags|\n")
    table.insert(dialog, "end_dialog|mm_player_music_manager|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildPlayerMusicEditor(player, songIndex)
    local state = mm_sessionState[player:getNetID()]
    local isEditing = songIndex ~= nil
    local songData = isEditing and mm_Config.playerSongs[songIndex] or {}
    state.editingSongIndex = songIndex

    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`w" .. (isEditing and "Edit Song" or "Add New Song") .. "|left|32|\n")
    table.insert(dialog, "add_smalltext|`oConfigure the song title and its source file.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_text_input|pmusic_title|Song Title:|" .. (songData.title or "") .. "|60|\n")
    table.insert(dialog, "add_text_input|pmusic_file|Music File (e.g., song.mp3):|" .. (songData.file or "") .. "|60|\n")
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|pmusic_save|`2Save Song|noflags|\n")
    table.insert(dialog, "add_button|pmusic_cancel|Cancel|noflags|\n")
    table.insert(dialog, "end_dialog|mm_player_music_editor|||\n")
    player:onDialogRequest(table.concat(dialog))
end

local function mm_buildPlayerDialog(player)
    local dialog = {}
    table.insert(dialog, "set_bg_color|15,23,42,200|\nset_border_color|34,211,238,255|\n")
    table.insert(dialog, "text_scaling_string|aaaaaaaaaaaaaaaaaa|\n")
    table.insert(dialog, "add_label_with_icon|big|`wMusic for Rakyat|left|9474|\n")
    table.insert(dialog, "add_smalltext|`oSelect a track to play or stop the current music.`o|\n")
    table.insert(dialog, "add_spacer|small|\n")
    if #mm_Config.playerSongs > 0 then
        for i, song in ipairs(mm_Config.playerSongs) do
            table.insert(dialog, string.format("add_button|pmusic_play_%d|%s|noflags|\n", i, song.title))
        end
    else
        table.insert(dialog, "add_textbox|`oThere are no songs available right now.`o|\n")
    end
    table.insert(dialog, "add_spacer|small|\n")
    table.insert(dialog, "add_button|stop_music|`4Stop Music|noflags|\n")
    table.insert(dialog, "add_quick_exit|\n")
    table.insert(dialog, "end_dialog|mm_player_main|||\n")
    player:onDialogRequest(table.concat(dialog))
end

registerLuaCommand({ command = mm_Config.ADMIN_COMMAND, roleRequired = Roles.ROLE_DEVELOPER, description = "Configure world and player music." })
registerLuaCommand({ command = mm_Config.PLAYER_COMMAND, roleRequired = Roles.ROLE_DEFAULT, description = "Open the music player." })
registerLuaCommand({ command = mm_Config.REMOVE_COMMAND, roleRequired = Roles.ROLE_DEFAULT, description = "Stop automatic music from playing in your world."})

onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)")
    if command == mm_Config.ADMIN_COMMAND and player:hasRole(Roles.ROLE_DEVELOPER) then
        mm_sessionState[player:getNetID()] = {}
        mm_buildAdminMenu(player)
        return true
    elseif command == mm_Config.PLAYER_COMMAND then
        mm_buildPlayerDialog(player)
        return true
    elseif command == mm_Config.REMOVE_COMMAND then
        local currentWorld = player:getWorld()
        if currentWorld and currentWorld:hasAccess(player) then
            local worldName = currentWorld:getName():upper()
            mm_Config.whitelistedWorlds[worldName] = true
            mm_saveConfig()
            player:onConsoleMessage("`2Automatic music has been disabled for this world.`o")
            player:sendAction("action|play_music\nfile|\n0|0")
        else
            player:onConsoleMessage("`4You must have access to this world to use this command.`o")
            player:playAudio("bleep_fail.wav")
        end
        return true
    end
    return false
end)

onPlayerDialogCallback(function(world, player, data)
    local dialogName = data.dialog_name
    local button = data.buttonClicked
    local netID = player:getNetID()
    local state = mm_sessionState[netID] or {}

    if dialogName == "mm_admin_main" then
        if button == "admin_global" then mm_buildGlobalEditor(player)
        elseif button == "admin_specific" then mm_buildSpecificManager(player)
        elseif button == "admin_whitelist" then mm_buildWhitelistManager(player)
        elseif button == "admin_player_music" then mm_buildPlayerMusicManager(player)
        elseif button == "admin_help" then mm_buildHelpDialog(player)
        end
        return true
    elseif button == "admin_back" or dialogName == "mm_help_dialog" then
        mm_buildAdminMenu(player)
        return true
    end

    if dialogName == "mm_global_editor" and button == "global_save" then
        mm_Config.globalMusic.file = data.global_music_file
        mm_saveConfig()
        player:onConsoleMessage("`2Global music setting saved.`o")
        player:playAudio("success.wav")
        mm_buildAdminMenu(player)
        return true
    end

    if dialogName == "mm_specific_manager" then
        if button == "specific_save" then
            local worldName = data.specific_world:upper()
            local musicFile = data.specific_music
            if worldName ~= "" and musicFile ~= "" then
                mm_Config.specificWorldMusic[worldName] = musicFile
                mm_saveConfig()
                player:onConsoleMessage("`2Mapping saved for " .. worldName .. ".`o")
                player:playAudio("success.wav")
                mm_buildSpecificManager(player)
            else
                player:onConsoleMessage("`4Both world and music file names are required.`o")
                player:playAudio("bleep_fail.wav")
            end
        else
            local worldToRemove = button:match("^specific_remove_(.+)$")
            if worldToRemove then
                mm_Config.specificWorldMusic[worldToRemove] = nil
                mm_saveConfig()
                player:onConsoleMessage("`2Mapping removed for " .. worldToRemove .. ".`o")
                player:playAudio("trash.wav")
                mm_buildSpecificManager(player)
            end
            local worldToEdit = button:match("^specific_edit_(.+)$")
            if worldToEdit then
                local musicFile = mm_Config.specificWorldMusic[worldToEdit]
                mm_buildSpecificManager(player, worldToEdit, musicFile)
            end
        end
        return true
    end
    
    if dialogName == "mm_whitelist_manager" then
        if button == "whitelist_add" then
            local worldName = data.whitelist_world:upper()
            if worldName ~= "" then
                mm_Config.whitelistedWorlds[worldName] = true
                mm_saveConfig()
                player:onConsoleMessage("`2" .. worldName .. " added to whitelist.`o")
                player:playAudio("success.wav")
                mm_buildWhitelistManager(player)
            end
        else
            local worldToRemove = button:match("^whitelist_remove_(.+)$")
            if worldToRemove then
                mm_Config.whitelistedWorlds[worldToRemove] = nil
                mm_saveConfig()
                player:onConsoleMessage("`2" .. worldToRemove .. " removed from whitelist.`o")
                player:playAudio("trash.wav")
                mm_buildWhitelistManager(player)
            end
        end
        return true
    end

    if dialogName == "mm_player_music_manager" then
        if button == "pmusic_add_new" then
            mm_buildPlayerMusicEditor(player)
        else
            local removeIndex = tonumber(button:match("^pmusic_remove_(%d+)$"))
            if removeIndex then
                table.remove(mm_Config.playerSongs, removeIndex)
                mm_saveConfig()
                player:onConsoleMessage("`2Song removed successfully.`o")
                player:playAudio("trash.wav")
                mm_buildPlayerMusicManager(player)
            end
            local editIndex = tonumber(button:match("^pmusic_edit_(%d+)$"))
            if editIndex then
                mm_buildPlayerMusicEditor(player, editIndex)
            end
        end
        return true
    end

    if dialogName == "mm_player_music_editor" then
        if button == "pmusic_cancel" then
            mm_buildPlayerMusicManager(player)
        elseif button == "pmusic_save" then
            local title = data.pmusic_title
            local file = data.pmusic_file
            if title == "" or file == "" then
                player:onConsoleMessage("`4Title and file cannot be empty.`o")
                player:playAudio("bleep_fail.wav")
                return true
            end
            local newSong = { title = title, file = file }
            if state.editingSongIndex then
                mm_Config.playerSongs[state.editingSongIndex] = newSong
            else
                table.insert(mm_Config.playerSongs, newSong)
            end
            mm_saveConfig()
            player:onConsoleMessage("`2Player song list updated.`o")
            player:playAudio("success.wav")
            mm_buildPlayerMusicManager(player)
        end
        return true
    end
    
    if dialogName == "mm_player_main" then
        if button == "stop_music" then
            player:sendAction("action|play_music\nfile|\n0|0")
            return true
        end
        local songIndex = tonumber(button:match("^pmusic_play_(%d+)$"))
        if songIndex and mm_Config.playerSongs[songIndex] then
            local song = mm_Config.playerSongs[songIndex]
            local fullPath = mm_Config.BASE_PATH .. serverID .. "/" .. song.file
            player:sendAction("action|play_music\nfile|" .. fullPath .. "\n0|0")
            return true
        end
    end

    return false
end)

onPlayerEnterWorldCallback(function(world, player)
    local worldName = player:getWorldName():upper()
    local musicToPlay = ""

    if mm_Config.specificWorldMusic[worldName] then
        musicToPlay = mm_Config.specificWorldMusic[worldName]
    elseif mm_Config.whitelistedWorlds[worldName] then
        return
    elseif mm_Config.globalMusic.file and mm_Config.globalMusic.file ~= "" then
        musicToPlay = mm_Config.globalMusic.file
    end

    if musicToPlay ~= "" then
        local fullPath = mm_Config.BASE_PATH .. serverID .. "/" .. musicToPlay
        player:sendAction("action|play_music\nfile|" .. fullPath .. "\n0|0")
    end
end)

onPlayerLeaveWorldCallback(function(world, player)
    local worldName = world:getName():upper()
    if mm_Config.specificWorldMusic[worldName] or (mm_Config.globalMusic.file and mm_Config.globalMusic.file ~= "" and not mm_Config.whitelistedWorlds[worldName]) then
         player:sendAction("action|play_music\nfile|\n0|0")
    end
end)

onPlayerDisconnectCallback(function(player)
    if mm_sessionState[player:getNetID()] then
        mm_sessionState[player:getNetID()] = nil
    end
end)

onAutoSaveRequest(function()
    mm_saveConfig()
end)

mm_loadConfig()