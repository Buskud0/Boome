local Collisions = {}

function Collisions.check(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

function Collisions.bulletVsZombie()
    for i, bullet in ipairs(bullets) do
        for _, zombie in ipairs(zombies) do
            if Collisions.check(bullet, zombie) then 
                table.insert(damageTexts, DamageText(-bullet.damage, bullet.x, bullet.y))
                zombie.health = zombie.health - bullet.damage
                table.remove(bullets, i)
            end
        end
    end
end

function Collisions.zombieVsPlayer()
    for i, zombie in ipairs(zombies) do
        if not zombie.hasHitPlayer and Collisions.check(zombie, player) then 
            player:takeDamage(zombie.damage)
            zombie.hasHitPlayer = true
            table.remove(zombies, i)
        end
    end
end

function Collisions.seperateZombies()
    for i, z1 in ipairs(zombies) do
        for j = i+1, #zombies do
            local z2 = zombies[j]
            if Collisions.check(z1, z2) then
                local dx = z1.x - z2.x
                local dy = z1.y - z2.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist == 0 then dist = 1 end  -- prevent divide by zero

                local pushX = (dx / dist) * 0.5
                local pushY = (dy / dist) * 0.5

                z1.x = z1.x + pushX
                z1.y = z1.y + pushY
                z2.x = z2.x - pushX
                z2.y = z2.y - pushY
            end
        end
    end
end

function Collisions.bulletVsWalls()
    for i, bullet in ipairs(bullets) do
        if grid:isBlocked(bullet.x, bullet.y, bullet.width, bullet.height) then
            table.remove(bullets, i)
        end
    end
end

return Collisions