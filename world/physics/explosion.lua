-- Explosion system: a radial blast that deals damage to the player, zombies
-- and destructible terrain, with more damage at the center and less toward the
-- edge. Solid objects shield the blast like bullets: they absorb its power and
-- are destroyed if it is strong enough, otherwise the blast stops at them.

local ExplosionEffect = require "entities.explosion_effect"
local DamageText = require "entities.damage_text"

local Explosion = {}

local function clamp01(v)
    return math.max(0, math.min(1, v))
end

local function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Explosion.detonate(state, centerX, centerY, radius, maxDamage, minDamage)
    local grid = state.grid

    -- Damage destructible terrain first, nearest records first, so nearer
    -- objects are resolved before they are used as shields for farther ones.
    local records = {}
    for _, list in ipairs({ grid.blockRecords, grid.objectRecords }) do
        for _, rec in ipairs(list) do
            local rx, ry = grid:recordWorldCenter(rec)
            local d = distance(centerX, centerY, rx, ry)
            if d <= radius then
                table.insert(records, { rec = rec, x = rx, y = ry, d = d })
            end
        end
    end
    table.sort(records, function(a, b) return a.d < b.d end)

    for _, entry in ipairs(records) do
        local dmg = Explosion._castBlast(state, centerX, centerY, entry.x, entry.y, radius, maxDamage, minDamage, entry.rec)
        if dmg > 0 then
            grid:damageTileBlast(entry.x, entry.y, dmg)
        end
    end

    -- Player and zombies. Rays run after terrain so walls broken by the blast
    -- no longer shield what is behind them.
    local player = state.player
    local px, py = player:getCenter()
    local pdmg = Explosion._castBlast(state, centerX, centerY, px, py, radius, maxDamage, minDamage)
    if pdmg > 0 then
        player:takeDamage(pdmg)
    end

    for _, zombie in ipairs(state.zombies) do
        local zx, zy = zombie:getCenter()
        local zdmg = Explosion._castBlast(state, centerX, centerY, zx, zy, radius, maxDamage, minDamage)
        if zdmg > 0 then
            zombie:takeDamage(zdmg)
            table.insert(state.damageTexts, DamageText(-math.floor(zdmg), zombie.x, zombie.y, 1, {1, 0.6, 0.2}))
        end
    end

    table.insert(state.explosions, ExplosionEffect(state, centerX, centerY, radius))
end

function Explosion._castBlast(state, originX, originY, targetX, targetY, radius, maxDamage, minDamage, skipRec)
    local dx = targetX - originX
    local dy = targetY - originY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > radius then return 0 end
    if dist == 0 then return maxDamage end

    local dirX = dx / dist
    local dirY = dy / dist
    local grid = state.grid
    local step = grid.tileSize / 2
    local power = maxDamage
    local seen = {}

    for t = step, dist, step do
        local px = originX + dirX * t
        local py = originY + dirY * t
        local rec = grid:destructibleRecordAt(px, py)
        if rec and rec ~= skipRec and not seen[rec] then
            seen[rec] = true
            power = power - rec.health
            if power <= 0 then return 0 end
        end
    end

    local falloff = minDamage + (maxDamage - minDamage) * clamp01(1 - dist / radius)
    return math.max(0, math.min(power, falloff))
end

return Explosion
