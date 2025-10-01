--bullets slow down zombies when hit
--add more different kinds of zombies
--work on the menu

require "conf"
Object = require "lib/classic"
require "player"
require "bullet"
require "zombie"
require "damagetext"
require "weapon"
require "menu"
require "grid"

scrWidth, scrHeight = love.graphics.getDimensions()
love.graphics.setBackgroundColor(0.6, 0.6, 0.6)
maxKills = 0
maxRounds = 0

function love.load()
    mapWidth = 1000
    mapHeight = 1000
    killCount = 0
    currentRound = 0
    zombieCount = 2
    currentWeaponIndex = 1
    camera = {x=0, y=0}
    grid = Grid()
    menu = Menu()
    love.mouse.setCursor(love.mouse.getSystemCursor("crosshair"))
    player = Player(-20+mapWidth/2,-20+mapHeight/2)
    bullets = {}
    zombies = {}
    weapons = {}
    damageTexts = {}
    table.insert(weapons, Weapon("M9"))
    table.insert(weapons, Weapon("MAC-10"))
    table.insert(weapons, Weapon("REMINGTON-870"))
    table.insert(weapons, Weapon("AWP"))
    table.insert(weapons, Weapon("AK47"))
    paused = false
    
end

function love.update(dt)
    if not paused then
        --changes weapon to whichever one is selected by player
        weapon = weapons[currentWeaponIndex]

        --adds zombies more zombies whenever there is none
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

        player:update(dt)
        weapon:update(dt)
        menu:update(dt)
        updateCamera()

        for _, bullet in ipairs(bullets) do
            bullet:update(dt)
        end

        for i, zombie in ipairs(zombies) do
            zombie:update(dt)
            seperateZombies()
            if zombie.health <= 0 then  --if zombie dies
                table.remove(zombies, i) 
                killCount = killCount + 1
            end
            if collision(zombie, player) then
                love.load()
            end
        end

        for i, bullet in ipairs(bullets) do
            for _, zombie in ipairs(zombies) do
                if collision(bullet, zombie) then 
                    table.insert(damageTexts, DamageText(-bullet.damage, bullet.x, bullet.y))
                    zombie.health = zombie.health - bullet.damage
                    table.remove(bullets, i)
                end
            end
        end

        for i, damageText in ipairs(damageTexts) do
            damageText:update(dt)
            if damageText.destruct == true then table.remove(damageTexts, i) end
        end
    end
    if killCount > maxKills then maxKills = killCount end
    if currentRound-1 > maxRounds then maxRounds = currentRound-1 end
end

function love.draw()
    love.graphics.translate(-camera.x, -camera.y)
    -- Draw map
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)

    grid:draw()
    printHUD()

    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end

    for _, zombie in ipairs(zombies) do
        zombie:draw()
    end

    for _, damageText in ipairs(damageTexts) do
        damageText:draw()
    end


    player:draw()
    weapon:draw()
    if paused then menu:draw() end

   
end

function love.keypressed(key)
    if key == 'escape' then paused = not paused
    elseif key == 'r' then weapon.capacity = 0
    elseif key == '1' then currentWeaponIndex = 1
    elseif key == '2' then currentWeaponIndex = 2
    elseif key == '3' then currentWeaponIndex = 3 
    elseif key == '4' then currentWeaponIndex = 4
    elseif key == '5' then currentWeaponIndex = 5 end
end

function collision(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

function addZombies(type, count)
    local minDistance = 250

    for i = 1, count do
        local x, y
        repeat
            x = math.random(0, mapWidth)
            y = math.random(0, mapHeight)
        until math.sqrt((x - player.x)^2 + (y - player.y)^2) > minDistance

        table.insert(zombies, Zombie(type, x, y))
    end

end

function seperateZombies()
    for i, z1 in ipairs(zombies) do
        for j, z2 in ipairs(zombies) do
            if i ~= j and collision(z1, z2) then
                local dx = z1.x - z2.x
                local dy = z1.y - z2.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist == 0 then dist = 1 end  -- prevent divide by zero

                z1.x = z1.x + (dx / dist)
                z1.y = z1.y + (dy / dist)
                z2.x = z2.x - (dx / dist)
                z2.y = z2.y - (dy / dist)
            end
        end 
    end
end

function printHUD()
    local font = love.graphics.newFont("fonts/Gamer.ttf", 200)
    local font2 = love.graphics.newFont("fonts/Gamer.ttf", 30)
    love.graphics.setColor({1,1,1})
    love.graphics.setFont(font)
    love.graphics.print(currentRound, 30 + camera.x, scrHeight - 190 + camera.y)
    love.graphics.setFont(font2)
    love.graphics.print("KILL COUNT: " .. killCount, 30 + camera.x, scrHeight - 40 + camera.y)
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