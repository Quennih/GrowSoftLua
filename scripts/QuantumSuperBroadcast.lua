print("(Loaded) Quantum Super Broadcast Script for GrowSoft")

local Roles = {
    ROLE_DEVELOPER = 51,
}

local qsbCommand = {
    command = "qsb",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Broadcast a message to all online players."
}

registerLuaCommand(qsbCommand)

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, message = fullCommand:match("^(%S+)%s*(.*)")

    if command == qsbCommand.command then
        if not player:hasRole(qsbCommand.roleRequired) then
            player:onConsoleMessage("`4Unknown command. `oEnter /? for a list of valid commands.")
            return true
        end

        if message and message ~= "" then
            local count = 0
            for _, p in ipairs(getServerPlayers()) do
                if p:getOnlineStatus() then
                    p:onTextOverlay("`2Developer Broadcast: `w" .. message)
                    count = count + 1
                end
            end
            player:onConsoleMessage("`2Broadcast sent to " .. count .. " player(s).")
        else
            player:onConsoleMessage("`4Invalid Input")
        end
        return true
    end

    return false
end)