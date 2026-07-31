local Collisions = {}

function Collisions.check(a, b)
    local ax, ay = a.x + a.width / 2, a.y + a.height / 2
    local bx, by = b.x + b.width / 2, b.y + b.height / 2
    local ar = a.radius or math.min(a.width, a.height) / 2
    local br = b.radius or math.min(b.width, b.height) / 2
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy < (ar + br) * (ar + br)
end

function Collisions.segmentHitsCircle(px, py, qx, qy, cx, cy, r)
    local dx = qx - px
    local dy = qy - py
    local lenSq = dx * dx + dy * dy
    if lenSq == 0 then
        local ex = cx - px
        local ey = cy - py
        return ex * ex + ey * ey <= r * r
    end
    local t = ((cx - px) * dx + (cy - py) * dy) / lenSq
    t = math.max(0, math.min(1, t))
    local closestX = px + t * dx
    local closestY = py + t * dy
    local ex = cx - closestX
    local ey = cy - closestY
    return ex * ex + ey * ey <= r * r
end

function Collisions.circleHitsSector(px, py, dx, dy, halfAngle, radius, cx, cy, r)
    local vx = cx - px
    local vy = cy - py
    local dist = math.sqrt(vx * vx + vy * vy)
    if dist == 0 then return true end

    local nx, ny = vx / dist, vy / dist
    local cosHalf = math.cos(halfAngle)
    if nx * dx + ny * dy >= cosHalf then
        return dist - radius <= r
    end

    local sinHalf = math.sin(halfAngle)
    local edgeX1 = dx * cosHalf - dy * sinHalf
    local edgeY1 = dx * sinHalf + dy * cosHalf
    local edgeX2 = dx * cosHalf + dy * sinHalf
    local edgeY2 = -dx * sinHalf + dy * cosHalf

    return segmentHitsCircle(px, py, px + edgeX1 * radius, py + edgeY1 * radius, cx, cy, r)
        or segmentHitsCircle(px, py, px + edgeX2 * radius, py + edgeY2 * radius, cx, cy, r)
end

function Collisions.bulletVsZombie()
    for i, bullet in ipairs(bullets) do
        for _, zombie in ipairs(zombies) do
            if Collisions.check(bullet, zombie) then 
                table.insert(damageTexts, DamageText(-bullet.damage, bullet.x, bullet.y))
                zombie:takeDamage(bullet.damage)
                table.remove(bullets, i)
            end
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
        local cx, cy = bullet.x + bullet.width / 2, bullet.y + bullet.height / 2
        if grid:isCircleBlocked(cx, cy, bullet.radius or math.min(bullet.width, bullet.height) / 2) then
            table.remove(bullets, i)
        end
    end
end

return Collisions