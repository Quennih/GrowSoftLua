print("(Loaded) Feature World Script for GrowSoft")

-- Available Colors (usage: color = colorMap.<color>)
local colorMap = {
    black        = 5,
    white        = 0xFFFFFFFF,
    blue         = 0xFF0000FF,
    lightpurple  = 0xFF00FFFF,
    cyan         = 0xFFFF00FF,
    lightviolet  = 0xFF808080,
    lightgray    = 0xFFD3D3D3,
    lightblue    = 0xFF800080,
    lightbrown   = 1215870207,
    green        = 64566271,
    lightgreen  = 0x03FFA0A0,
    randomColorOne = 1563414015,
    randomColorTwo = 1535082495,
    transparent = 4278190080,
}

-- Add Worlds Here
local initialFeatures = {
    {name = "start", color = colorMap.lightgray},
    {name = "locke", color = colorMap.lightgray},
    {name = "fishing", color = colorMap.lightgray},
}

-- Change 0 to 1 if you want to hide default pinned worlds (ex. MINES)
local hideDefaultWorld = 0

local featuredWorlds = {}

local function doFeature(worldName, color)
    local w = getWorldByName(worldName)
    if not w then return end
    local id = w:getID()
    if featuredWorlds[id] then return end
    addWorldMenuWorld(id, worldName:upper(), color, 0)
    featuredWorlds[id] = worldName
end

for _, cfg in ipairs(initialFeatures) do
    doFeature(cfg.name, cfg.color)
end

onPlayerLoginCallback(function(player)
    hideWorldMenuDefaultSpecialWorlds(hideDefaultWorld)
end)

local Roles = {
    ROLE_DEVELOPER = 51,
}

local featureCmd = {
    command = "feature",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Feature a world to the World Menu (Temporary)."
}

registerLuaCommand(featureCmd)

onPlayerCommandCallback(function(_, player, fullCommand)
    local cmd, args = fullCommand:match("^(%S+)%s*(.*)")
    if cmd ~= featureCmd.command then return false end
    if not player:hasRole(featureCmd.roleRequired) then return false end

    local worldName, colorName = args:match("^(%S+)%s*(%S*)$")
    if not worldName or worldName == "" then
        player:onConsoleMessage("Provide a world name to feature!")
        return true
    end

    if not worldName:match("^[a-zA-Z0-9]+$") then
        player:onConsoleMessage("World name must only contain letters and numbers!")
        return true
    end

    if colorName ~= "" then
        if not colorMap[colorName:lower()] then
            player:onConsoleMessage("Invalid Color! Available colors: White, Black, Blue, Lightpurple, Cyan, Lightviolet, Lightgray, Lightblue, Lightbrown, Green.")
            return true
        end
    end

    local chosenColor = colorMap[(colorName or ""):lower()] or colorMap.lightgray

    doFeature(worldName, chosenColor)
    player:onConsoleMessage("World " .. worldName:upper() .. " is now featured in the World Menu!" .. (colorName ~= "" and (" with color " .. colorName:lower() .. ".") or "."))

    return true
end)

local removeCmd = {
    command = "rfeature",
    roleRequired = Roles.ROLE_DEVELOPER,
    description = "Remove a featured world from the World Menu (Temporary)."
}

registerLuaCommand(removeCmd)

onPlayerCommandCallback(function(_, player, fullCommand)
    local cmd, worldName = fullCommand:match("^(%S+)%s*(.*)")
    if cmd ~= removeCmd.command then return false end
    if not player:hasRole(removeCmd.roleRequired) then return false end

    if not worldName or worldName == "" then
        player:onConsoleMessage("Provide a world name to remove.")
        return true
    end

    if not worldName:match("^[a-zA-Z0-9]+$") then
        player:onConsoleMessage("World name must only contain letters and numbers!")
        return true
    end

    local w = getWorldByName(worldName)

    if not w then
        player:onConsoleMessage("World " .. worldName:upper() .. " not found.")
        return true
    end

    local id = w:getID()

    if not featuredWorlds[id] then
        player:onConsoleMessage("World " .. worldName:upper() .. " is not featured.")
    else
        removeWorldMenuWorld(id)
        featuredWorlds[id] = nil
        player:onConsoleMessage("World " .. worldName:upper() .. " has been removed from the World Menu.")
    end

    return true
end)