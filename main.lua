--bullets slow down zombies when hit
--add more different kinds of zombies
--work on the menu

require "conf"
require "config"
Object = require "lib.classic"
Input = require "input"
Textures = require "textures"
require "entities.entity"
require "entities.player"
require "entities.bullet"
require "entities.zombie"
require "damagetext"
require "weapon"
require "menu"
require "grid"
require "entities.powerUp"
Collisions = require "collisions"

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
    Textures.load("spritesheet.png", 40)
    Textures.define("empty", 1)
    Textures.define("wall", 2)
    resetGame()
end

function resetGame()
    mapWidth = MAP_WIDTH
    mapHeight = MAP_HEIGHT
    killCount = 0
    currentRound = 0
    zombieCount = STARTING_ZOMBIE_COUNT
    currentWeaponIndex = 1
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
    table.insert(weapons, Weapon("MAC-10"))
    table.insert(weapons, Weapon("AWP"))
    table.insert(weapons, Weapon("REMINGTON-870"))
    table.insert(weapons, Weapon("AK47"))
    paused = false
end

function ManageRounds()
    if #zombies == 0 then
        currentRound = currentRound + 1
        mostKills = currentRound
        addZombies("normal", zombieCount)
        addZombies("heavy", currentRound/3)
        addZombies("light", currentRound/2)
        zombieCount = zombieCount + 2
        for i, weapon in ipairs(weapons) do
            weapon.reloadCooldown = 0
            weapon.capacity = weapon.magSize
        end
    end
end

function onZombieKilled(zombie, index)
    print("killed " .. zombie.type .. " zombie")
    table.remove(zombies, index)
    killCount = killCount + 1
    if zombie.type == "light" then player.money = player.money + 5 end
    if zombie.type == "normal" then player.money = player.money + 10 end
    if zombie.type == "heavy" then player.money = player.money + 15 end
    local powerUpChance = math.random(1, 5)
    if powerUpChance == 1 then table.insert(powerUps, powerUp(zombie.x, zombie.y, "money")) end
    if powerUpChance == 2 then table.insert(powerUps, powerUp(zombie.x, zombie.y, "health")) end
end

function updateDamageTexts(dt)
    for i = #damageTexts, 1, -1 do
        damageTexts[i]:update(dt)
        if damageTexts[i].destruct then table.remove(damageTexts, i) end
    end
end

function tryMove(entity, dx, dy)
    local newX = entity.x + dx
    local newY = entity.y + dy
    if not grid:isBlocked(newX, entity.y, entity.width, entity.height) and newX >= 0 and newX <= mapWidth - entity.width then
        entity.x = newX
    end
    if not grid:isBlocked(entity.x, newY, entity.width, entity.height) and newY >= 0 and newY <= mapHeight - entity.height then
        entity.y = newY
    end
end

function love.update(dt)
    if not paused then
        --changes weapon to whichever one is selected by player
        weapon = weapons[currentWeaponIndex]

        ManageRounds()

        player:update(dt)
        weapon:update(dt)
        menu:update(dt)
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

    printHUD()
    if paused then menu:draw() end
   
end

function love.keypressed(key)
    local action = Input.getActionForKey(key)
    if action == "pause" then paused = not paused
    elseif action == "reload" then weapon.capacity = 0
    elseif action == "weapon1" then currentWeaponIndex = 1
    elseif action == "weapon2" then currentWeaponIndex = 2
    elseif action == "weapon3" then currentWeaponIndex = 3
    elseif action == "weapon4" then currentWeaponIndex = 4
    elseif action == "weapon5" then currentWeaponIndex = 5 end
end

function addZombies(type, count)
    local minDistance = 500

    for i = 1, count do
        local x, y
        repeat
            x = math.random(0, mapWidth)
            y = math.random(0, mapHeight)
        until math.sqrt((x - player.x)^2 + (y - player.y)^2) > minDistance

        table.insert(zombies, Zombie(type, x, y))
    end

end

function printHUD()
    local font = love.graphics.newFont("fonts/Gamer.ttf", 100)
    local font2 = love.graphics.newFont("fonts/Gamer.ttf", 30)
    love.graphics.setColor({1,1,1})
    love.graphics.setFont(font)
    love.graphics.print(math.floor(player.health), 30 + camera.x, scrHeight - 150 + camera.y)
    love.graphics.setFont(font2)
    love.graphics.print("WAVE: " .. currentRound, 30 + camera.x, scrHeight - 70 + camera.y)
    love.graphics.print("KILL COUNT: " .. killCount, 30 + camera.x, scrHeight - 50 + camera.y)
    love.graphics.print("$" .. player.money, 30 + camera.x, scrHeight - 30 + camera.y)
    
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