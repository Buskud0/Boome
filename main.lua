require "conf"
Object = require "lib/classic"
require "player"
require "bullet"
require "zombie"
require "damagetext"
scrWidth, scrHeight = love.graphics.getDimensions()
--local isDown = love.keyboard.isDown
love.graphics.setBackgroundColor(0.6, 0.8, 1)


function love.load()
    bulletSpeed = 1500
    bulletDamage = 23
    player = Player(-20+scrWidth/2,-20+scrHeight/2)
    bullets = {}
    zombies = {}
    damageTexts = {}
    killCount = 0
end

function love.update(dt)
    if #zombies == 0 then addZombies(5) end

    player:update(dt)

    for _, bullet in ipairs(bullets) do
        bullet:update(dt)
    end

    for i, zombie in ipairs(zombies) do
        zombie:update(dt)
        seperateZombies()
        if zombie.health<=0 then  --if zombie dies
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
                table.insert(damageTexts, DamageText(-bulletDamage, bullet.x, bullet.y))
                zombie.health=zombie.health-bulletDamage
                table.remove(bullets, i)
            end
        end
    end

    for i, damageText in ipairs(damageTexts) do
        damageText:update(dt)
        if damageText.destruct == true then table.remove(damageTexts, i) end
    end
end

function love.draw()
    player:draw()
    printKillCount()

    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end

    for _, zombie in ipairs(zombies) do
        zombie:draw()
    end

    for _, damageText in ipairs(damageTexts) do
        damageText:draw()
    end

end

function love.keypressed(key)
    if key == 'escape' then love.event.quit() end
    
end

function love.mousepressed(x, y, button) --shoot towards mouse function
    if button == 1 then
        local startX = player.x + player.width / 2
        local startY = player.y + player.height / 2
        local mouseX = x
        local mouseY = y
        
        local angle = math.atan2((mouseY - startY), (mouseX - startX))
        
        local bulletDx = bulletSpeed * math.cos(angle)
        local bulletDy = bulletSpeed * math.sin(angle)
        
        table.insert(bullets, Bullet(startX, startY, bulletDx, bulletDy))
    end
end

function collision(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

function addZombies(count)
    for i = 1, count do
        table.insert(zombies, Zombie(math.random(0, scrWidth), math.random(0, scrHeight)))
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
                local push = 1

                z1.x = z1.x + (dx / dist) * push
                z1.y = z1.y + (dy / dist) * push
                z2.x = z2.x - (dx / dist) * push
                z2.y = z2.y - (dy / dist) * push
            end
        end
    end
end

function printKillCount()
    local font = love.graphics.newFont("fonts/Gamer.ttf", 200)
    love.graphics.setFont(font)
    love.graphics.setColor({1,1,1})
    love.graphics.print(killCount, 30, scrHeight - 150)
end