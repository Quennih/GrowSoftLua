print("Loaded drop_ten_items_command by MarineGTPS")

-- Definisi Peran (Roles)
local Roles = {
    ROLE_CREATOR = 7,
    ROLE_DEVELOPER = 51 -- Contoh: Jika Anda ingin hanya developer yang bisa menggunakan
}

-- Data Command untuk perintah /drop10items
local dropTenItemsCommandData = {
    command = "dgacha",
    roleRequired = Roles.ROLE_DEVELOPER,
    roleRequired = Roles.ROLE_CREATOR, -- Ubah ke Roles.ROLE_DEVELOPER jika hanya ingin developer yang bisa
    description = "Menjatuhkan 10 item berbeda ke dunia di lokasi Anda."
}

-- Item yang akan dijatuhkan (ID dan jumlah) Ubah ID nya Bosku Jangan Murni Kali Comot nya
local itemsToDrop = {
    { id = 20616, amount = 10 },   -- Dirt
    { id = 12600, amount = 10 },   -- Rock
    { id = 836, amount = 10 },   -- Door
    { id = 3402, amount = 10 },  -- Sign
    { id = 11038, amount = 10 },  -- Lava
    { id = 9350, amount = 10 },  -- Cave Background
    { id = 20614, amount = 10 },  -- Wood Block
    { id = 20258, amount = 10 },  -- Grass
    { id = 25160, amount = 10 },  -- Window
    { id = 1486, amount = 2 }   -- Brick
}

-- Mendaftarkan Command
registerLuaCommand(dropTenItemsCommandData)

-- Callback section
onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)%s*(.*)")

    if command == dropTenItemsCommandData.command then
        -- Periksa peran yang dibutuhkan
        if not player:hasRole(dropTenItemsCommandData.roleRequired) then
            player:onConsoleMessage("`4Tidak memiliki izin untuk menggunakan perintah ini.``")
            player:playAudio("bleep_fail.wav")
            return true
        end

        local playerPosX = player:getPosX()
        local playerPosY = player:getPosY()
        local droppedCount = 0

        for _, itemData in ipairs(itemsToDrop) do
            local itemID = itemData.id
            local amount = itemData.amount
            
            -- Memunculkan (menjatuhkan) item di posisi pemain
            world:spawnItem(playerPosX, playerPosY, itemID, amount)
            droppedCount = droppedCount + 1
        end

        player:onConsoleMessage("`2Berhasil menjatuhkan `w" .. droppedCount .. "`2 item berbeda di lokasi Anda!``")
        player:playAudio("treasure_box_open.wav")
        return true
    end
    return false
end)