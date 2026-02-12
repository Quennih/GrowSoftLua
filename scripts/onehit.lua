print("Loaded One-Hit Blocks Script by chatgpt")

-- Define roles
local Roles = {
    ROLE_DEVELOPER = 51,
    ROLE_NONE = 0
}

-- Define the command
local oneHitCommandData = {
    command = "onehit",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Toggles one-hit breaking for all blocks."
}

-- Register the command
registerLuaCommand(oneHitCommandData)

-- Callback section
onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)%s*(.*)")

    -- Check if the command is "/onehit"
    if command == oneHitCommandData.command then
        -- Check if the player has the required role (Developer)
        if not player:hasRole(oneHitCommandData.roleRequired) then
            player:onConsoleMessage("`4Unknown command. `oEnter /? for a list of valid commands.``")
            return true
        end

        local currentAdjustedHits = player:getAdjustedBlockHitCount()
        local newAdjustedHits

        -- Toggle between -10 (one-hit) and 0 (default)
        if currentAdjustedHits == -10 then
            newAdjustedHits = 0
            player:onConsoleMessage("`oOne-hit breaking `4disabled`. Blocks will now break at default speed.``")
        else
            newAdjustedHits = -10
            player:onConsoleMessage("`oOne-hit breaking `2enabled`. Most blocks will now break in one hit.``")
        end

        player:adjustBlockHitCount(newAdjustedHits)
        return true
    end

    return false
end)