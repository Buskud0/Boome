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
mostKills = 0

function love.load()
    grid = Grid()
    menu = Menu()
    love.mouse.setCursor(love.mouse.getSystemCursor("crosshair"))
    player = Player(-20+scrWidth/2,-20+scrHeight/2)
    bullets = {}
    zombies = {}
    weapons = {}
    damageTexts = {}
    killCount = 0
    zombieCount = 3
    currentWeaponIndex = 1
    table.insert(weapons, Weapon("M9"))
    table.insert(weapons, Weapon("MAC-10"))
    table.insert(weapons, Weapon("REMINGTON-870"))
    table.insert(weapons, Weapon("AWM"))
    paused = false
    currentRound = 0
end

function love.update(dt)
    if not paused then
        --changes weapon to whichever one is selected by player
        weapon = weapons[currentWeaponIndex]

        --adds zombies more zombies whenever there is none
        if #zombies == 0 then 
            currentRound = currentRound + 1
            mostKills = currentRound
            addZombies(zombieCount) 
            zombieCount = zombieCount + 3
        end

        player:update(dt)
        weapon:update(dt)

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
end

function love.draw()
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
    elseif key == '4' then currentWeaponIndex = 4 end
end

function collision(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

function addZombies(count)
    local minDistance = 250

    for i = 1, count do
        local x, y
        repeat
            x = math.random(0, scrWidth)
            y = math.random(0, scrHeight)
        until math.sqrt((x - player.x)^2 + (y - player.y)^2) > minDistance

        table.insert(zombies, Zombie(x, y))
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
    love.graphics.print(currentRound, 30, scrHeight - 190)
    love.graphics.setFont(font2)
    love.graphics.print("KILL COUNT: " .. killCount, 30, scrHeight - 40)
end

function randNegPos(number)
    local number = number or 1
    return number * (math.random(0, 1) == 0 and -1 or 1)
end
