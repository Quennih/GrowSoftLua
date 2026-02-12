print("(Loaded) Server Lockdown Script for GrowSoft")

local SERVER_LOCKDOWN_KEY = "SERVER_LOCKDOWN_" .. getServerID()

-- Countdown (Editable)
local countdownDuration = 30

local Roles = {
    ROLE_DEVELOPER = 51,
}

local isLockDown = false
local countdownActive = false
local countdownStartTime = 0
local lastAnnouncedSecond = -1
local initialAnnounced = false

local savedData = loadDataFromServer(SERVER_LOCKDOWN_KEY)
if savedData and type(savedData) == "table" and savedData.locked ~= nil then
    isLockDown = savedData.locked
end

local function broadcast(msg)
    for _, p in pairs(getServerPlayers()) do
        p:sendVariant({ "OnConsoleMessage", msg })
    end
end

local function formatTime(seconds)
    if seconds >= 60 then
        local mins = math.floor(seconds / 60)
        return mins .. " minute" .. (mins > 1 and "s" or "")
    else
        return seconds .. " second" .. (seconds ~= 1 and "s" or "")
    end
end

local function startLockdownCountdown(player)
    if countdownActive then
        player:sendVariant({ "OnConsoleMessage", "`oLockdown countdown already running." })
        return
    end

    countdownActive = true
    countdownStartTime = os.time()
    lastAnnouncedSecond = -1
    initialAnnounced = false

    broadcast("`4Server Lockdown will begin in " .. formatTime(countdownDuration) .. "!")
end

local function enforceLockdown()
    isLockDown = true
    saveDataToServer(SERVER_LOCKDOWN_KEY, { locked = true })

    for _, p in pairs(getServerPlayers()) do
        if not p:hasRole(Roles.ROLE_DEVELOPER) then
            p:sendVariant({ "OnConsoleMessage", "`4Time to rest! Server Lockdown is now active. You have been disconnected." })
            p:disconnect()
        else
            p:sendVariant({ "OnConsoleMessage", "`2Server Lockdown is now ENABLED." })
        end
    end
end

onTick(function()
    if not countdownActive then return end

    local now = os.time()
    local elapsed = now - countdownStartTime
    local remaining = countdownDuration - elapsed

    if remaining <= 0 then
        countdownActive = false
        enforceLockdown()
        return
    end

    local shouldAnnounce = false
    if remaining <= 10 then
        shouldAnnounce = true
    elseif remaining <= 60 and remaining % 10 == 0 then
        shouldAnnounce = true
    elseif remaining % 60 == 0 then
        shouldAnnounce = true
    end

    if shouldAnnounce and remaining ~= lastAnnouncedSecond then
        lastAnnouncedSecond = remaining

        if not initialAnnounced then
            initialAnnounced = true
            return
        end

        broadcast("`4Server Lockdown in " .. formatTime(remaining) .. "!")
    end
end)

local lockTheServer = {
    command = "lock",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Starts a countdown to server lockdown."
}

registerLuaCommand(lockTheServer)

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, args = fullCommand:match("^(%S+)%s*(.*)")

    if command ~= lockTheServer.command then return false end

    if not player:hasRole(lockTheServer.roleRequired) then
        player:sendVariant({ "OnConsoleMessage", "`4Unknown Command!" })
        return true
    end

    if args == "now" then
        countdownActive = false
        isLockDown = true

        saveDataToServer(SERVER_LOCKDOWN_KEY, {
            locked = true
        })

        player:sendVariant({ "OnConsoleMessage", "`2Server Lockdown is ENABLED." })

        for _, p in ipairs(getServerPlayers()) do
            if not p:hasRole(Roles.ROLE_DEVELOPER) then
                p:sendVariant({ "OnConsoleMessage", "`4Server Lockdown is enabled. You have been disconnected." })
                p:disconnect()
            end
        end

        return true
    end

    if countdownActive or isLockDown then
        countdownActive = false
        isLockDown = false

        saveDataToServer(SERVER_LOCKDOWN_KEY, {
            locked = false
        })

        broadcast("Server Lockdown has been cancelled.")

        for _, z in pairs(getServerPlayers()) do
            z:playAudio("friend_beep.wav")
        end

        return true
    end

    startLockdownCountdown(player)

    for _, z in pairs(getServerPlayers()) do
        z:playAudio("realitytear.wav")
    end

    return true
end)

onPlayerLoginCallback(function(player)
    if isLockDown and not player:hasRole(Roles.ROLE_DEVELOPER) then
        player:sendVariant({ "OnConsoleMessage", "`4Time to rest! Server Lockdown is enabled. Try again later!" })
        player:disconnect()
        print(string.format("[Server Locked] Blocked login for %s (UserID: %d)", player:getName(), player:getUserID()))
    elseif isLockDown then
        player:sendVariant({ "OnConsoleMessage", "`2Server Locked" })
    end
end)