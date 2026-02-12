print("(Loaded) Quantum Broadcast Command - Albin")

registerLuaCommand({
    command = "qsb",
    roleRequired = 51,
    description = "Quantum Broadcast"
})

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if not cmd or cmd:lower() ~= "qsb" then
        return false
    end

    local text = fullCommand:match("^%S+%s+(.+)$")
    if not text or text == "" then
        player:sendVariant({"OnConsoleMessage", "`oUsage: /qsb <text>"})
        return true
    end

    local senderName = player:getName()
    local formattedMessage = string.format("`cQuantum Broadcast [`0From `c%s`0]: `^%s", senderName, text)

    for _, plr in ipairs(getServerPlayers() or {}) do
        if plr:isOnline() then
            plr:sendVariant({"OnConsoleMessage", formattedMessage})

            local notif = string.format("[`c%s``] `o\n`^%s", senderName, text)
            plr:sendVariant({
                "OnAddNotification",
                "interface/science_button.rttex",
                notif,
                "audio/hub_open.wav"
            })
        end
    end

    return true
end)