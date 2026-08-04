local Horde = {}

function Horde.loadScoreRecord()
    local record = love.filesystem.read("record.txt")
    if not record then
        Horde.maxRounds = 0
        Horde.maxKills = 0
        return
    end
    Horde.maxRounds, Horde.maxKills = record:match("(%d+)%s+(%d+)")
    Horde.maxRounds = tonumber(Horde.maxRounds) or 0
    Horde.maxKills = tonumber(Horde.maxKills) or 0
end

function Horde.saveScoreRecord()
    love.filesystem.write("record.txt", Horde.maxRounds .. " " .. Horde.maxKills)
end

function Horde.reset()
    Inventory.close()
    currentRound = 1
    zombieCount = STARTING_ZOMBIE_COUNT
    Horde.state = "intro"
    Horde.introTimer = ROUND_FREEZE_TIME
    Horde.roundTextTimer = ROUND_TEXT_TIME
    Horde.spawnQueue = {}
    Horde.spawnTimer = 0
    Horde:buildQueue()
end

function Horde.waveUpdate(dt)
    if Horde.roundTextTimer and Horde.roundTextTimer > 0 then
        Horde.roundTextTimer = math.max(0, Horde.roundTextTimer - dt)
    end
    if Horde.state == "intro" then
        Horde.updateIntro(dt)
    elseif Horde.state == "spawning" then
        Horde.updateSpawning(dt)
    elseif Horde.state == "waiting" then
        Horde.updateWaiting()
    end
end

function Horde.updateIntro(dt)
    Horde.introTimer = Horde.introTimer - dt
    if Horde.introTimer <= 0 then
        Horde.state = "spawning"
        Horde.spawnTimer = 2
    end
end

function Horde.updateSpawning(dt)
    Horde.spawnTimer = Horde.spawnTimer - dt
    if Horde.spawnTimer <= 0 and #Horde.spawnQueue > 0 then
        Horde.spawnNextQueuedZombie()
    end
    if #Horde.spawnQueue == 0 then
        Horde.state = "waiting"
    end
end

function Horde.updateWaiting()
    if #zombies == 0 then
        Horde.startNextRound()
    end
end

function Horde.startNextRound()
    currentRound = currentRound + 1
    zombieCount = zombieCount + 2
    grid:regrowAll()
    Horde.refillWeaponAmmo()
    Horde:buildQueue()
    Horde.state = "intro"
    Horde.introTimer = ROUND_FREEZE_TIME
    Horde.roundTextTimer = ROUND_TEXT_TIME
end

function Horde.refillWeaponAmmo()
    for _, w in ipairs(weapons) do
        if w.magSize then
            w.reloadCooldown = 0
            w.capacity = w.magSize
        end
    end
end

function Horde.spawnNextQueuedZombie()
    local zombieType = table.remove(Horde.spawnQueue, 1)
    Horde.spawnZombie(zombieType)
    Horde.spawnTimer = 2
end

function Horde:buildQueue()
    local queue = {}
    Horde.addZombiesToQueue(queue, zombieCount, "normal")
    Horde.addZombiesToQueue(queue, currentRound / 3, "heavy")
    Horde.addZombiesToQueue(queue, currentRound / 2, "light")
    Horde.shuffleQueue(queue)
    Horde.spawnQueue = queue
end

function Horde.addZombiesToQueue(queue, count, zombieType)
    for i = 1, math.floor(count) do
        table.insert(queue, zombieType)
    end
end

function Horde.shuffleQueue(queue)
    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end
end

function Horde.spawnZombie(type)
    local x, y = Horde.findRandomSpawnPosition()
    local zombie = Zombie(type, x, y)
    resolveStuck(zombie)
    table.insert(zombies, zombie)
end

function Horde.findRandomSpawnPosition()
    local minDistance = 500
    local x, y
    repeat
        x = math.random(0, mapWidth)
        y = math.random(0, mapHeight)
    until math.sqrt((x - player.x)^2 + (y - player.y)^2) > minDistance
    return x, y
end

function Horde.onZombieKilled(zombie, index)
    Horde.removeZombie(zombie, index)
    killCount = killCount + 1
    Horde.rewardKill(zombie)
    Horde.maybeDropPowerUp(zombie)
end

function Horde.removeZombie(zombie, index)
    table.remove(zombies, index)
end

function Horde.rewardKill(zombie)
    if zombie.type == "light" then player.money = player.money + 5 end
    if zombie.type == "normal" then player.money = player.money + 10 end
    if zombie.type == "heavy" then player.money = player.money + 15 end
end

function Horde.maybeDropPowerUp(zombie)
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

function Horde.updateCamera(dt)
    Horde.followPlayer()
    if weapon then weapon:updateScope(dt) end
    Horde.clampCameraToMap()
end

function Horde.followPlayer()
    local cx, cy = scrWidth / 2, scrHeight / 2
    camera.x = (player.x - cx) * camera.zoom
    camera.y = (player.y - cy) * camera.zoom
end

function Horde.clampCameraToMap()
    local cx, cy = scrWidth / 2, scrHeight / 2
    local minCamX = cx * (1 - camera.zoom)
    local minCamY = cy * (1 - camera.zoom)
    local maxCamX = (mapWidth - cx) * camera.zoom - cx
    local maxCamY = (mapHeight - cy) * camera.zoom - cy

    if camera.x < minCamX then camera.x = minCamX end
    if camera.y < minCamY then camera.y = minCamY end
    if camera.x > maxCamX then camera.x = maxCamX end
    if camera.y > maxCamY then camera.y = maxCamY end
end

function Horde.cycleWeapon(direction)
    local start = currentWeaponIndex or (direction > 0 and 0 or 6)
    local target = Horde.findNextWeaponSlot(start, direction)
    if target then
        currentWeaponIndex = target
    end
end

function Horde.findNextWeaponSlot(startIndex, direction)
    local target = startIndex + direction
    while target >= 1 and target <= 5 do
        if weapons[target] then return target end
        target = target + direction
    end
    return nil
end

function Horde.handleKey(key, action)
    if Horde.handleWeaponSlotKey(key) then return end
    if action == "reload" then
        Horde.handleReload()
    elseif action == "inventory" then
        Inventory.toggle()
    elseif action == "drop" then
        Inventory.dropHeldWeapon()
    elseif action == "cycle_prev" then
        Horde.cycleWeapon(-1)
    elseif action == "cycle_next" then
        Horde.cycleWeapon(1)
    end
end

function Horde.handleReload()
    if weapon and weapon.magSize and weapon.capacity < weapon.magSize then
        weapon.capacity = 0
    end
end

function Horde.handleWeaponSlotKey(key)
    for slot = 1, 5 do
        if Input.isActionBoundToKey("weapon" .. slot, key) then
            if currentWeaponIndex == slot then
                currentWeaponIndex = nil
            elseif weapons[slot] then
                currentWeaponIndex = slot
            else
                currentWeaponIndex = nil
            end
            return true
        end
    end
    return false
end

function Horde.mainUpdate(dt)
    Horde.setActiveWeapon()
    Horde.waveUpdate(dt)
    player:update(dt)
    Horde.updateActiveWeapon(dt)
    Horde.updateCamera(dt)
    Collisions.bulletVsZombie()
    Collisions.seperateZombies()
    Horde.updateBullets(dt)
    Collisions.bulletVsWalls()
    Horde.updateZombies(dt)
    Horde.updatePowerUps(dt)
    Horde.updateWeaponPickups(dt)
    Horde.updateDamageTexts(dt)
    Horde.updateScoreRecord()
    HUD.update(dt)
end

function Horde.updateWeaponPickups(dt)
    for _, pickup in ipairs(weaponPickups) do
        pickup:update(dt)
    end
end

function Horde.setActiveWeapon()
    local newWeapon = fists
    if currentWeaponIndex and currentWeaponIndex <= Inventory.HOTBAR_SLOTS and weapons[currentWeaponIndex] then
        newWeapon = weapons[currentWeaponIndex]
    end
    if newWeapon ~= weapon then
        Horde.resetScope(newWeapon)
    end
    weapon = newWeapon
end

function Horde.resetScope(newWeapon)
    for _, w in ipairs({weapon, newWeapon}) do
        if w and w.scopeProgress ~= nil then
            w.scopeProgress = 0
            w.scopeOffsetX = 0
            w.scopeOffsetY = 0
        end
    end
end

function Horde.updateActiveWeapon(dt)
    if not BuyMenu.isOpen() and weapon then
        weapon:update(dt)
    end
end

function Horde.updateBullets(dt)
    for _, bullet in ipairs(bullets) do
        bullet:update(dt)
    end
end

function Horde.updateZombies(dt)
    for i, zombie in ipairs(zombies) do
        zombie:update(dt)
        if zombie.health <= 0 then Horde.onZombieKilled(zombie, i) end
    end
end

function Horde.updatePowerUps(dt)
    for _, powerUp in ipairs(powerUps) do
        powerUp:update(dt)
    end
end

function Horde.updateWeaponPickups(dt)
    for _, pickup in ipairs(weaponPickups) do
        pickup:update(dt)
    end
end

function Horde.drawWeaponPickups()
    for _, pickup in ipairs(weaponPickups) do
        pickup:draw()
    end
end

function Horde.updateScoreRecord()
    if currentRound - 1 > Horde.maxRounds then Horde.maxRounds = currentRound - 1 end
    if killCount > Horde.maxKills then Horde.maxKills = killCount end
end

function Horde.draw()
    Horde.applyCameraZoom()
    Horde.drawWorld()
    player:drawLocalLighting()
    Horde.drawHUD()
end

function Horde.applyCameraZoom()
    love.graphics.push()
    love.graphics.translate(scrWidth / 2, scrHeight / 2)
    love.graphics.scale(camera.zoom)
    love.graphics.translate(-scrWidth / 2, -scrHeight / 2)
end

function Horde.drawWorld()
    Horde.drawMap()
    grid:drawObjects()
Horde.drawPowerUps()
    Horde.drawWeaponPickups()
    Horde.drawZombies()
    player:draw()
    grid:drawBushesAboveEntities()
    Horde.drawBullets()
    if weapon then weapon:drawWorld() end
    Horde.drawZombieAttacks()
    Horde.drawDamageTexts()
    love.graphics.pop()
end

function Horde.drawMap()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    grid:drawBlocks()
end

function Horde.drawPowerUps()
    for _, powerUp in ipairs(powerUps) do
        powerUp:draw()
    end
end

function Horde.drawBullets()
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end
end

function Horde.drawZombies()
    for _, zombie in ipairs(zombies) do
        zombie:draw()
    end
end

function Horde.drawZombieAttacks()
    for _, zombie in ipairs(zombies) do
        zombie:drawStab()
    end
end

function Horde.drawDamageTexts()
    for _, damageText in ipairs(damageTexts) do
        damageText:draw()
    end
end

function Horde.drawHUD()
    if weapon then weapon:draw() end
    HUD.draw()
    Inventory.draw()
    Horde.drawOverlay()
    BuyMenu.draw()
end

function Horde.drawOverlay()
    if not (Horde.roundTextTimer and Horde.roundTextTimer > 0) then return end
    local alpha = math.max(0, Horde.roundTextTimer / ROUND_TEXT_TIME)
    Horde.drawCenteredText("WAVE " .. currentRound, scrWidth / 2 + camera.x, scrHeight / 2 - 40 + camera.y, 80, alpha)
end

function Horde.drawCenteredText(text, centerX, centerY, size, alpha)
    local font = Fonts.get(size)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, alpha)
    local textW = font:getWidth(text)
    love.graphics.print(text, centerX - textW / 2, centerY)
end

return Horde
