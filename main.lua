require "conf"
Object = require "lib/classic"
require "player"
require "bullet"
require "zombie"
scrWidth, scrHeight = love.graphics.getDimensions()
--local isDown = love.keyboard.isDown
love.graphics.setBackgroundColor(0.6, 0.8, 1)
gamerFont = love.graphics.newFont("fonts/Gamer.ttf", 32)

function love.load()
    bulletSpeed = 1500
    bulletDamage = 20
    player = Player(-20+scrWidth/2,-20+scrHeight/2)
    bullets = {}
    zombies = {}
    damageTexts = {}
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
        if zombie.health<=0 then table.remove(zombies, i) end
        if collision(zombie, player) then
            love.load()
        end
    end

    for i, bullet in ipairs(bullets) do
        for _, zombie in ipairs(zombies) do
            if collision(bullet, zombie) then 
                --showDamage(bulletDamage, zombie.x, zombie.y)
                zombie.health=zombie.health-bulletDamage
                table.remove(bullets, i)
            end
        end
    end

end

function love.draw()
    player:draw()

    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end

    for _, zombie in ipairs(zombies) do
        zombie:draw()
    end

end

function love.keypressed(key)
    if key == 'escape' then love.event.quit() end
    --if key == '1' then  end
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
