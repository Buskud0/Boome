-- Runtime collision resolution between bullets, zombies and walls.

local Config = require "core.config"
local Collision = require "world.physics.collision"
local DamageText = require "entities.damage_text"

local EntityCollision = {}

function EntityCollision.bulletVsZombie(state)
    for i = #state.bullets, 1, -1 do
        local bullet = state.bullets[i]
        local consumed = bullet.damage <= 0
        if not consumed then
            for _, zombie in ipairs(state.zombies) do
                if not consumed and not bullet.hitZombies[zombie] and Collision.check(bullet, zombie) then
                    bullet.hitZombies[zombie] = true
                    table.insert(state.damageTexts, DamageText(-math.floor(bullet.damage), bullet.x, bullet.y))
                    local targetHealth = zombie.health
                    zombie:takeDamage(bullet.damage)
                    if not bullet:applyHit(targetHealth) then
                        consumed = true
                    end
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
        if bullet.damage <= 0 then
            table.remove(state.bullets, i)
        else
            local cx, cy = bullet.x + bullet.width / 2, bullet.y + bullet.height / 2
            local radius = bullet.radius or math.min(bullet.width, bullet.height) / 2
            local record = state.grid:destructibleRecordNear(cx, cy, radius)
            local remove = false
            if record and not bullet.penetratedTiles[record] then
                bullet.penetratedTiles[record] = true
                local item = Config.BUILDING_ITEMS[record.material]
                if not (item and item.bulletproof) then
                    local targetHealth = record.health
                    state.grid:damageRecord(record, bullet.damage)
                    if not (item and item.penetrative) and not bullet:applyHit(targetHealth) then
                        remove = true
                    end
                end
            elseif not record and state.grid:isCircleBlocked(cx, cy, radius) then
                remove = true
            end
            if remove then
                table.remove(state.bullets, i)
            end
        end
    end
end

return EntityCollision
