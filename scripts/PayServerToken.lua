print("(Loaded) Pay Server Token Script for GrowSoft")

local serverTokenID = 20234

local payTokenCommand = {
    command = "paytoken",
    roleRequired = 0,
    description = "Send Premium WL to another player."
}

registerLuaCommand(payTokenCommand)

local function findPlayerByNameInsensitive(inputName)
    local target = string.lower(inputName)
    for _, p in ipairs(getServerPlayers()) do
        if string.lower(p:getCleanName()) == target then
            return p
        end
    end
    return nil
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, args = fullCommand:match("^(%S+)%s*(.*)$")
    if command ~= payTokenCommand.command then return false end

    local targetName, amountStr = args:match("^(%S+)%s+(%S+)$")
    if not targetName or not amountStr then
        player:onConsoleMessage("Usage: /" .. command .. " <playerName> <amount>")
        player:playAudio("thwoop.wav")
        return true
    end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        player:onConsoleMessage("Invalid amount. Must be a positive number.")
        player:onTextOverlay("`4Failed")
        player:playAudio("bleep_fail.wav")
        return true
    end

    local target = findPlayerByNameInsensitive(targetName)
    if not target then
        player:onConsoleMessage("Player '" .. targetName .. "' not found or not online.")
        player:onTextOverlay("`4Failed")
        player:playAudio("bleep_fail.wav")
        return true
    end

    if target:getUserID() == player:getUserID() then 
        player:onConsoleMessage("You laugh nervously as you try to give " .. getItem(serverTokenID):getName() .. " to yourself!")
        player:onTextOverlay("`4Failed")
        player:playAudio("bleep_fail.wav")
        return true
    end

    if command == paypwlCommand.command then

        if player:getCoins() < amount then
            player:onConsoleMessage("You don't have enough " .. getItem(serverTokenID):getName() .. "!")
            player:onTextOverlay("`4Failed")
            player:playAudio("bleep_fail.wav")
            return true
        end

        player:removeCoins(amount, 0)
        player:onConsoleMessage("You gave " .. amount .. " " .. getItem(serverTokenID):getName() ..  " to " .. target:getName() .. "!")
        player:onConsoleMessage(player:getCoins() .. " " .. getItem(serverTokenID):getName() .. " left.")
        player:onTextOverlay("`2Success")
        player:playAudio("coin_flip.wav")

        target:addCoins(amount)
        target:onConsoleMessage("Player " .. player:getName() .. " gave you " .. amount .. " " .. getItem(serverTokenID):getName() .. "!")
        target:onConsoleMessage("You now have " .. target:getCoins() .. " " .. getItem(serverTokenID):getName() .. " in total.")
        target:playAudio("cash_register.wav")
    end

    return true
end)