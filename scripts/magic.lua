-- Magic Particle Effect Script
print("(Loaded) Magic Particle Effect script for GrowSoft")

---------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------

local config = {
    required_role = 51,
    particle_count = 30, -- How many particles per effect type
    radius = 150, -- How far particles spread from player (in pixels)
    spawn_delay = 0.1, -- Delay between each particle spawn (in seconds)
    vanish_duration = 3.0 -- Total duration before invisibility kicks in (seconds)
}

---------------------------------------------------------
-- PARTICLE HELPER FUNCTIONS
---------------------------------------------------------

-- Function to send particle to all players in the world
local function broadcastParticle(world, particle_id, x, y)
    if not world then return end
    local players = world:getPlayers()
    
    for _, p in ipairs(players) do
        if p.onParticleEffect then
            p:onParticleEffect(particle_id, x, y, 0, 0, 0)
        end
    end
end

-- Function to create particle effect TYPE 1
local function createParticleEffect1(world, player)
    if not player or not world then return end
    
    local playerID = player:getUserID()
    local centerX = player:getPosX() + 15
    local centerY = player:getPosY() + 15
    
    for i = 1, config.particle_count do
        timer.setTimeout(i * config.spawn_delay, function(uid, baseX, baseY)
            local p = getPlayer(uid)
            if not p or not p:getWorld() then return end
            
            local currentWorld = p:getWorld()
            local offsetX = math.random(-config.radius, config.radius)
            local offsetY = math.random(-config.radius, config.radius)
            local particleX = baseX + offsetX
            local particleY = baseY + offsetY
            
            broadcastParticle(currentWorld, 323, particleX, particleY)
        end, playerID, centerX, centerY)
    end
end

-- Function to create particle effect TYPE 2
local function createParticleEffect2(world, player)
    if not player or not world then return end
    
    local playerID = player:getUserID()
    local centerX = player:getPosX() + 15
    local centerY = player:getPosY() + 15
    
    for i = 1, config.particle_count do
        timer.setTimeout(i * config.spawn_delay, function(uid, baseX, baseY)
            local p = getPlayer(uid)
            if not p or not p:getWorld() then return end
            
            local currentWorld = p:getWorld()
            local offsetX = math.random(-config.radius, config.radius)
            local offsetY = math.random(-config.radius, config.radius)
            local particleX = baseX + offsetX
            local particleY = baseY + offsetY
            
            broadcastParticle(currentWorld, 2, particleX, particleY)
        end, playerID, centerX, centerY)
    end
end

-- Function to create particle effect TYPE 3
local function createParticleEffect3(world, player)
    if not player or not world then return end
    
    local playerID = player:getUserID()
    local centerX = player:getPosX() + 15
    local centerY = player:getPosY() + 15
    
    for i = 1, config.particle_count do
        timer.setTimeout(i * config.spawn_delay, function(uid, baseX, baseY)
            local p = getPlayer(uid)
            if not p or not p:getWorld() then return end
            
            local currentWorld = p:getWorld()
            local offsetX = math.random(-config.radius, config.radius)
            local offsetY = math.random(-config.radius, config.radius)
            local particleX = baseX + offsetX
            local particleY = baseY + offsetY
            
            broadcastParticle(currentWorld, 3, particleX, particleY)
        end, playerID, centerX, centerY)
    end
end

-- Function to spawn all particle effects
local function spawnAllParticles(world, player)
    createParticleEffect1(world, player)
    createParticleEffect2(world, player)
    createParticleEffect3(world, player)
end

---------------------------------------------------------
-- COMMAND REGISTRATION
---------------------------------------------------------

local magicCommand = {
    command = "magic",
    roleRequired = config.required_role,
    description = "Spawns magical particle effects around you"
}

local vanishCommand = {
    command = "vanish",
    roleRequired = config.required_role,
    description = "Spawns particles and toggles invisibility using /invis"
}

registerLuaCommand(magicCommand)
registerLuaCommand(vanishCommand)

---------------------------------------------------------
-- COMMAND CALLBACK
---------------------------------------------------------

onPlayerCommandCallback(function(world, player, fullCommand)
    local command, args = fullCommand:match("^(%S+)%s*(.*)")
    
    -- /MAGIC COMMAND - Just particles, no invisibility
    if command == magicCommand.command then
        -- Check if player has required role
        if not player:hasRole(config.required_role) then
            player:onConsoleMessage("`4You need role ID " .. config.required_role .. " to use this command!")
            return true
        end
        
        -- Create magic effect
        player:onConsoleMessage("`oMagical particles summoned!``")
        -- player:onTalkBubble(player:getNetID(), "`9 Magic!", 0)
        player:sendAction("action|play_sfx\nfile|audio/gem_pickup.wav\ndelayMS|0")
        
        spawnAllParticles(world, player)
        
        return true
    end
    
    -- /VANISH COMMAND - Particles + Toggle Invisibility using /invis
    if command == vanishCommand.command then
        -- Check if player has required role
        if not player:hasRole(config.required_role) then
            player:onConsoleMessage("`4You need role ID " .. config.required_role .. " to use this command!")
            return true
        end
        
        -- Show vanish message
        player:onConsoleMessage("`oVanishing into thin air...``")
        -- player:onTalkBubble(player:getNetID(), "`9 Vanish!", 0)
        player:sendAction("action|play_sfx\nfile|audio/gem_pickup.wav\ndelayMS|0")
        
        -- Spawn particles
        spawnAllParticles(world, player)
        
        -- Execute /invis after particles finish
        local playerID = player:getUserID()
        timer.setTimeout(config.vanish_duration, function(uid)
            local p = getPlayer(uid)
            if not p then return end
            
            local w = p:getWorld()
            if not w then return end
            
            -- Try Method 1: Using sendPlayerMessage
            w:sendPlayerMessage(p, "/invis")
            
            -- Optional: Add sound effect
            p:sendAction("action|play_sfx\nfile|audio/checkpoint.wav\ndelayMS|0")
        end, playerID)
        
        return true
    end
    
    return false
end)