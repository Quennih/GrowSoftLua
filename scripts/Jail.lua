-- Nama File: DisconnectPlayer.lua

local Roles = {
    ROLE_NONE = 0,
    ROLE_DEVELOPER = 51 -- ID 51 adalah untuk Developer
}

-- Mendaftarkan perintah Lua baru: /disc <nama-pemain>
registerLuaCommand({
    command = "disc",
    roleRequired = Roles.ROLE_DEVELOPER, -- Hanya Developer yang bisa menggunakan perintah ini
    description = "Disconnects a specified player."
})

-- Fungsi untuk menemukan pemain berdasarkan nama bersih (clean name)
local function findPlayer(name)
    local lowerName = string.lower(name)
    for _, p in ipairs(getServerPlayers()) do
        if string.lower(p:getCleanName()) == lowerName then
            return p
        end
    end
    return nil
end

-- Callback saat pemain mengetik perintah
onPlayerCommandCallback(function(world, player, fullCommand)
    local commandName, args = fullCommand:match("^(%S+)%s*(.*)$")
    commandName = string.lower(commandName)
    
    -- Periksa apakah perintah yang digunakan adalah /disc
    if commandName == "disc" then
        -- Verifikasi peran (Role) untuk memastikan hanya Developer yang bisa lanjut
        if not player:hasRole(Roles.ROLE_DEVELOPER) then
            player:onConsoleMessage("`4Akses ditolak.`o Hanya Developer yang bisa menggunakan perintah ini.")
            player:playAudio("audio/bleep_fail.wav")
            return true
        end
        
        local targetName = args:match("^(%S+)$")
        
        -- Periksa format penggunaan perintah
        if not targetName then
            player:onConsoleMessage("`4Penggunaan:`o /disc <nama-pemain>")
            player:playAudio("audio/bleep_fail.wav")
            return true
        end
        
        -- Cari pemain target
        local targetPlayer = findPlayer(targetName)
        
        if targetPlayer then
            -- Lakukan disconnect
            targetPlayer:disconnect()
            
            -- Kirim pesan notifikasi ke admin yang menjalankan perintah
            player:onConsoleMessage("`2Berhasil memutuskan koneksi pemain: `o" .. targetPlayer:getName())
            player:playAudio("audio/success.wav")
        else
            -- Pemain tidak ditemukan
            player:onConsoleMessage("`4Pemain '" .. targetName .. "' tidak ditemukan atau tidak online.")
            player:playAudio("audio/bleep_fail.wav")
        end
        
        return true
    end
    
    return false
end)