--bullets slow down zombies when hit
--add more different kinds of zombies
--work on the menu

require "conf"
require "core.config"
Object = require "lib.classic"
Input = require "core.input"
Textures = require "core.textures"
require "entities.entity"
require "entities.player"
require "entities.bullet"
require "entities.zombie"
require "ui.damagetext"
require "systems.weapon"
require "ui.menu"
require "core.grid"
require "entities.PowerUp"
Collisions = require "core.collisions"
HUD = require "ui.hud"
Survival = require "gamemodes.survival"
Inventory = require "ui.inventory"
BuyMenu = require "ui.buymenu"

function loadRecord()
    local record = love.filesystem.read("record.txt")
    if record then
        maxRounds, maxKills = record:match("(%d+)%s+(%d+)")
        maxRounds = tonumber(maxRounds) or 0
        maxKills = tonumber(maxKills) or 0
    else
        maxRounds = 0
        maxKills = 0
    end
end

function love.load()
    scrWidth, scrHeight = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.6, 0.6, 0.6)
    loadRecord()
    love.mouse.setCursor(love.mouse.getSystemCursor("crosshair"))
    Input.load()
    Textures.load("images/spritesheet.png", 40)
    Textures.define("empty", 1)
    Textures.define("wall", 2)
    Textures.load("images/spritesheet_entities.png", 40)
    Textures.define("player", 1)
    Textures.define("zombie_normal", 2)
    Textures.define("zombie_heavy", 3)
    Textures.define("zombie_light", 4)
    Textures.define("bullet", 5)
    Textures.define("powerup_health", 6)
    Textures.define("powerup_money", 7)
    Textures.load("images/itemSpriteSheet.png", 40)
    Inventory.load()
    resetGame()
end

function resetGame()
    mapWidth = MAP_WIDTH
    mapHeight = MAP_HEIGHT
    killCount = 0
    currentWeaponIndex = 1
    Survival.reset()
    camera = {x=0, y=0}
    grid = Grid()
    menu = Menu()
    player = Player(mapWidth/2 - 20, mapHeight/2 - 20)
    bullets = {}
    zombies = {}
    weapons = {}
    damageTexts = {}
    powerUps = {}
    table.insert(weapons, Weapon("M9"))
    paused = false
    BuyMenu.close()
end

function onZombieKilled(zombie, index)
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

function updateDamageTexts(dt)
    for i = #damageTexts, 1, -1 do
        damageTexts[i]:update(dt)
        if damageTexts[i].destruct then table.remove(damageTexts, i) end
    end
end

function tryMove(entity, dx, dy, constrainToMap)
    if constrainToMap == nil then constrainToMap = true end
    local newX = entity.x + dx
    local newY = entity.y + dy
    if not grid:isBlocked(newX, entity.y, entity.width, entity.height) and (not constrainToMap or (newX >= 0 and newX <= mapWidth - entity.width)) then
        entity.x = newX
    end
    if not grid:isBlocked(entity.x, newY, entity.width, entity.height) and (not constrainToMap or (newY >= 0 and newY <= mapHeight - entity.height)) then
        entity.y = newY
    end
    resolveStuck(entity)
end

function resolveStuck(entity)
    if entity.x < 0 then entity.x = 0
    elseif entity.x > mapWidth - entity.width then entity.x = mapWidth - entity.width end
    if entity.y < 0 then entity.y = 0
    elseif entity.y > mapHeight - entity.height then entity.y = mapHeight - entity.height end

    if not grid:isBlocked(entity.x, entity.y, entity.width, entity.height) then return end

    local tileSize = Textures.getTileSize()
    for offset = 1, tileSize do
        if not grid:isBlocked(entity.x + offset, entity.y, entity.width, entity.height) then
            entity.x = entity.x + offset
            break
        end
        if not grid:isBlocked(entity.x - offset, entity.y, entity.width, entity.height) then
            entity.x = entity.x - offset
            break
        end
        if not grid:isBlocked(entity.x, entity.y + offset, entity.width, entity.height) then
            entity.y = entity.y + offset
            break
        end
        if not grid:isBlocked(entity.x, entity.y - offset, entity.width, entity.height) then
            entity.y = entity.y - offset
            break
        end
    end
end

function love.update(dt)
    if not paused then
        --changes weapon to whichever one is selected by player
        weapon = weapons[currentWeaponIndex]

        Survival.update(dt)

        player:update(dt)
        if not BuyMenu.isOpen() then
            weapon:update(dt)
        end
        updateCamera()
        Collisions.bulletVsZombie()
        Collisions.zombieVsPlayer()
        Collisions.seperateZombies()

        for _, bullet in ipairs(bullets) do
            bullet:update(dt)
        end

        Collisions.bulletVsWalls()

        for i, zombie in ipairs(zombies) do
            zombie:update(dt)
            if zombie.health <= 0 then onZombieKilled(zombie, i) end
        end

        for i, powerUp in ipairs(powerUps) do
            powerUp:update(dt)
        end

        updateDamageTexts(dt)
    end
    menu:update(dt)
    if currentRound-1 > maxRounds then maxRounds = currentRound-1 end
    if killCount > maxKills then maxKills = killCount end
end

function love.quit()
    love.filesystem.write("record.txt", maxRounds .. " " .. maxKills)
end

function love.draw()
    love.graphics.translate(-camera.x, -camera.y)
    -- Draw map
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
    Survival.draw()
    BuyMenu.draw()
    if paused then menu:draw() end
   
end

function love.keypressed(key)
    local action = Input.getActionForKey(key)

    if action == "pause" then
        if BuyMenu.isOpen() then
            BuyMenu.close()
        elseif menu:isOpen() then
            menu:closeSubmenu()
            paused = menu:isOpen()
        else
            menu:openSubmenu("main")
            paused = menu:isOpen()
        end
    elseif action == "buy" then
        if not menu:isOpen() then
            BuyMenu.toggle()
        end
    elseif menu:isOpen() then
        menu:handleAction(action)
        paused = menu:isOpen()
    elseif BuyMenu.isOpen() then
        BuyMenu.handleAction(action)
    elseif action == "reload" then
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
        repeat
            currentWeaponIndex = currentWeaponIndex - 1
            if currentWeaponIndex < 1 then currentWeaponIndex = #weapons end
        until weapons[currentWeaponIndex]
    elseif key == "right" then
        repeat
            currentWeaponIndex = currentWeaponIndex + 1
            if currentWeaponIndex > #weapons then currentWeaponIndex = 1 end
        until weapons[currentWeaponIndex]
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and menu:isOpen() then
        menu:mousepressed(x + camera.x, y + camera.y)
        paused = menu:isOpen()
    elseif button == 1 and BuyMenu.isOpen() then
        BuyMenu.mousepressed(x + camera.x, y + camera.y)
    end
end

function love.wheelmoved(x, y)
    if paused then return end
    if BuyMenu.isOpen() then
        BuyMenu.wheelmoved(y)
        return
    end
    if y > 0 then
        repeat
            currentWeaponIndex = currentWeaponIndex - 1
            if currentWeaponIndex < 1 then currentWeaponIndex = #weapons end
        until weapons[currentWeaponIndex]
    elseif y < 0 then
        repeat
            currentWeaponIndex = currentWeaponIndex + 1
            if currentWeaponIndex > #weapons then currentWeaponIndex = 1 end
        until weapons[currentWeaponIndex]
    end
end

function spawnZombie(type)
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

function randNegPos(number)
    local number = number or 1
    return number * (math.random(0, 1) == 0 and -1 or 1)
end

function updateCamera()
    camera.x = player.x - scrWidth/2
    camera.y = player.y - scrHeight/2

    if camera.x < 0 then camera.x = 0 end
    if camera.y < 0 then camera.y = 0 end
    if camera.x > mapWidth - scrWidth then
        camera.x = mapWidth - scrWidth
    end
    if camera.y > mapHeight - scrHeight then
        camera.y = mapHeight - scrHeight
    end
end