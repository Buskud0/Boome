-- Runtime collision resolution between bullets, zombies and walls.

local Collision = require "world.physics.collision"
local DamageText = require "entities.damage_text"

local EntityCollision = {}

function EntityCollision.bulletVsZombie(state)
    for i = #state.bullets, 1, -1 do
        local bullet = state.bullets[i]
        local consumed = false
        for _, zombie in ipairs(state.zombies) do
            if not consumed and not bullet.hitZombies[zombie] and Collision.check(bullet, zombie) then
                bullet.hitZombies[zombie] = true
                table.insert(state.damageTexts, DamageText(-bullet.damage, bullet.x, bullet.y))
                zombie:takeDamage(bullet.damage)
                if not bullet:applyPenetrationLoss() then
                    consumed = true
                end
            end
        end
        if consumed then
            table.remove(state.bullets, i)
        end
    end
end

function EntityCollision.seperateZombies(state)
    for i, z1 in ipairs(state.zombies) do
        for j = i + 1, #state.zombies do
            local z2 = state.zombies[j]
            if Collision.check(z1, z2) then
                local dx = z1.x - z2.x
                local dy = z1.y - z2.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist == 0 then dist = 1 end

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

function EntityCollision.bulletVsWalls(state)
    for i = #state.bullets, 1, -1 do
        local bullet = state.bullets[i]
        local cx, cy = bullet.x + bullet.width / 2, bullet.y + bullet.height / 2
        local radius = bullet.radius or math.min(bullet.width, bullet.height) / 2
        local record, isObject = state.grid:destructibleRecordAt(cx, cy)
        local blocked = state.grid:isCircleBlocked(cx, cy, radius)
        local remove = blocked and not isObject
        if record and not bullet.penetratedTiles[record] then
            bullet.penetratedTiles[record] = true
            state.grid:damageTile(cx, cy, bullet.damage)
            remove = remove or not bullet:applyPenetrationLoss()
        end
        if remove then
            table.remove(state.bullets, i)
        end
    end
end

return EntityCollision
