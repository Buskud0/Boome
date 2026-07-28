local Horde = {}

Horde.maxRounds = 0
Horde.maxKills = 0

function Horde.loadScoreRecord()
    local record = love.filesystem.read("record.txt")
    if record then
        Horde.maxRounds, Horde.maxKills = record:match("(%d+)%s+(%d+)")
        Horde.maxRounds = tonumber(Horde.maxRounds) or 0
        Horde.maxKills = tonumber(Horde.maxKills) or 0
    else
        Horde.maxRounds = 0
        Horde.maxKills = 0
    end
end

function Horde.saveScoreRecord()
    love.filesystem.write("record.txt", Horde.maxRounds .. " " .. Horde.maxKills)
end

function Horde.reset()
    currentRound = 1
    zombieCount = STARTING_ZOMBIE_COUNT
    Horde.state = "intro"
    Horde.introTimer = 5
    Horde.spawnQueue = {}
    Horde.spawnTimer = 0
    Horde:buildQueue()
end

function Horde.waveUpdate(dt)
    if Horde.state == "intro" then
        Horde.introTimer = Horde.introTimer - dt
        if Horde.introTimer <= 0 then
            Horde.state = "spawning"
            Horde.spawnTimer = 1
        end
    elseif Horde.state == "spawning" then
        Horde.spawnTimer = Horde.spawnTimer - dt
        if Horde.spawnTimer <= 0 and #Horde.spawnQueue > 0 then
            local zombieType = table.remove(Horde.spawnQueue, 1)
            Horde.spawnZombie(zombieType)
            Horde.spawnTimer = 1
        end
        if #Horde.spawnQueue == 0 then
            Horde.state = "waiting"
        end
    elseif Horde.state == "waiting" then
        if #zombies == 0 then
            currentRound = currentRound + 1
            zombieCount = zombieCount + 2
            for i, w in ipairs(weapons) do
                w.reloadCooldown = 0
                w.capacity = w.magSize
            end
            Horde:buildQueue()
            Horde.state = "intro"
            Horde.introTimer = 5
        end
    end
end

function Horde:buildQueue()
    local queue = {}
    local function append(count, zombieType)
        for i = 1, math.floor(count) do
            table.insert(queue, zombieType)
        end
    end
    append(zombieCount, "normal")
    append(currentRound / 3, "heavy")
    append(currentRound / 2, "light")
    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end
    Horde.spawnQueue = queue
end

function Horde.drawOverlay()
    if Horde.state ~= "intro" then return end
    local alpha = math.max(0, Horde.introTimer / 5)
    local text = "WAVE " .. currentRound
    local font = love.graphics.newFont("fonts/Gamer.ttf", 80)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, alpha)
    local textW = font:getWidth(text)
    love.graphics.print(text, scrWidth / 2 - textW / 2 + camera.x, scrHeight / 2 - 40 + camera.y)
end

function Horde.spawnZombie(type)
    local minDistance = 500
    local x, y
    repeat
        x = math.random(0, mapWidth)
        y = math.random(0, mapHeight)
    until math.sqrt((x - player.x)^2 + (y - player.y)^2) > minDistance
    local zombie = Zombie(type, x, y)
    resolveStuck(zombie)
    table.insert(zombies, zombie)
end

function Horde.onZombieKilled(zombie, index)
    print("killed " .. zombie.type .. " zombie")
    table.remove(zombies, index)
    killCount = killCount + 1
    if zombie.type == "light" then player.money = player.money + 5 end
    if zombie.type == "normal" then player.money = player.money + 10 end
    if zombie.type == "heavy" then player.money = player.money + 15 end
    local powerUpChance = math.random(1, 10)
    if powerUpChance == 1 then table.insert(powerUps, PowerUp(zombie.x, zombie.y, "money")) end
    if powerUpChance == 2 then table.insert(powerUps, PowerUp(zombie.x, zombie.y, "health")) end
end

function Horde.updateDamageTexts(dt)
    for i = #damageTexts, 1, -1 do
        damageTexts[i]:update(dt)
        if damageTexts[i].destruct then table.remove(damageTexts, i) end
    end
end

function Horde.updateCamera()
    camera.x = player.x - scrWidth / 2
    camera.y = player.y - scrHeight / 2
    if camera.x < 0 then camera.x = 0 end
    if camera.y < 0 then camera.y = 0 end
    if camera.x > mapWidth - scrWidth then camera.x = mapWidth - scrWidth end
    if camera.y > mapHeight - scrHeight then camera.y = mapHeight - scrHeight end
end

function Horde.cycleWeapon(direction)
    repeat
        currentWeaponIndex = currentWeaponIndex + direction
        if currentWeaponIndex < 1 then currentWeaponIndex = #weapons end
        if currentWeaponIndex > #weapons then currentWeaponIndex = 1 end
    until weapons[currentWeaponIndex]
end

function Horde.handleKey(key, action)
    if action == "reload" then
        weapon.capacity = 0
    elseif action == "weapon1" and weapons[1] then
        currentWeaponIndex = 1
    elseif action == "weapon2" and weapons[2] then
        currentWeaponIndex = 2
    elseif action == "weapon3" and weapons[3] then
        currentWeaponIndex = 3
    elseif action == "weapon4" and weapons[4] then
        currentWeaponIndex = 4
    elseif action == "weapon5" and weapons[5] then
        currentWeaponIndex = 5
    elseif key == "left" then
        Horde.cycleWeapon(-1)
    elseif key == "right" then
        Horde.cycleWeapon(1)
    end
end

function Horde.mainUpdate(dt)
    weapon = weapons[currentWeaponIndex]
    Horde.waveUpdate(dt)
    player:update(dt)
    if not BuyMenu.isOpen() then
        weapon:update(dt)
    end
    Horde.updateCamera()
    Collisions.bulletVsZombie()
    Collisions.zombieVsPlayer()
    Collisions.seperateZombies()
    for _, bullet in ipairs(bullets) do
        bullet:update(dt)
    end
    Collisions.bulletVsWalls()
    for i, zombie in ipairs(zombies) do
        zombie:update(dt)
        if zombie.health <= 0 then Horde.onZombieKilled(zombie, i) end
    end
    for i, powerUp in ipairs(powerUps) do
        powerUp:update(dt)
    end
    Horde.updateDamageTexts(dt)
    if currentRound - 1 > Horde.maxRounds then Horde.maxRounds = currentRound - 1 end
    if killCount > Horde.maxKills then Horde.maxKills = killCount end
end

function Horde.draw()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    grid:draw()
    for _, powerUp in ipairs(powerUps) do
        powerUp:draw()
    end
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end
    for _, zombie in ipairs(zombies) do
        zombie:draw()
    end
    player:draw()
    weapon:draw()
    for _, damageText in ipairs(damageTexts) do
        damageText:draw()
    end
    HUD.draw()
    Inventory.draw()
    Horde.drawOverlay()
    BuyMenu.draw()
end

return Horde
