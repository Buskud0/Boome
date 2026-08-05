-- Pure geometric collision tests. No runtime state needed.

local Collision = {}

function Collision.check(a, b)
    local ax, ay = a.x + a.width / 2, a.y + a.height / 2
    local bx, by = b.x + b.width / 2, b.y + b.height / 2
    local ar = a.radius or math.min(a.width, a.height) / 2
    local br = b.radius or math.min(b.width, b.height) / 2
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy < (ar + br) * (ar + br)
end

function Collision.segmentHitsCircle(px, py, qx, qy, cx, cy, r)
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

function Collision.circleHitsSector(px, py, dx, dy, halfAngle, radius, cx, cy, r)
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

    return Collision.segmentHitsCircle(px, py, px + edgeX1 * radius, py + edgeY1 * radius, cx, cy, r)
        or Collision.segmentHitsCircle(px, py, px + edgeX2 * radius, py + edgeY2 * radius, cx, cy, r)
end

return Collision
