Zombie = Entity:extend()
local Pathfinding = require "core.pathfinding"

local PATH_RECALC_INTERVAL = 0.3
local WAYPOINT_RADIUS = 6
local SEPARATION_RADIUS = 30
local SEPARATION_WEIGHT = 0.7

function Zombie:new(type, x, y)
    Zombie.super.new(self, x, y)
    self.type = type or "normal"
    self:_applyTypeStats()
    self.health = self.maxHealth
    self.sprite = "zombie_" .. self.type
    self.path = {}
    self.pathTimer = 0
    self.weapon = Weapon.create("FISTS")
    self.attackRange = self.weapon.range
    self.attackCooldown = 1
    self.attackTimer = 0
    self.stabTimer = 0
    self.stabDirX, self.stabDirY = 0, 0
end

function Zombie:_applyTypeStats()
    if self.type == "normal" then
        self.speed = 50
        self.maxHealth = 100
        self.color = {1, 0.2, 0}
    elseif self.type == "heavy" then
        self.speed = 25
        self.maxHealth = 300
        self.color = {1, 0.2, 0.5}
    elseif self.type == "light" then
        self.speed = 100
        self.maxHealth = 50
        self.color = {0.8, 0.6, 0}
    end
end

function Zombie:update(dt)
    Zombie.super.update(self, dt)
    self:_updateStab(dt)

    local dist = self:_distanceToPlayer()
    if dist == 0 then return end

    if self:_updateAttack(dt, dist) then return end

    self:_moveTowardPlayer(dt)
end

function Zombie:_distanceToPlayer()
    local cx, cy = self:getCenter()
    local px, py = player:getCenter()
    local dx, dy = px - cx, py - cy
    return math.sqrt(dx * dx + dy * dy)
end

function Zombie:_updateAttack(dt, dist)
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    if dist > self.attackRange then return false end

    local dirX, dirY = self:_getDirectionToPlayer()

    if self.attackTimer > 0 then return true end

    self.attackTimer = self.attackCooldown
    self:_startStabAnimation(dirX, dirY)
    self:_damagePlayerIfInRange(dirX, dirY)
    return true
end

function Zombie:_getDirectionToPlayer()
    local cx, cy = self:getCenter()
    local px, py = player:getCenter()
    local dx, dy = px - cx, py - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return 0, 0 end
    return dx / dist, dy / dist
end

function Zombie:_startStabAnimation(dirX, dirY)
    self.stabTimer = MELEE_STAB_DURATION
    self.stabDirX, self.stabDirY = dirX, dirY
end

function Zombie:_damagePlayerIfInRange(dirX, dirY)
    local cx, cy = self:getCenter()
    local px, py = player:getCenter()
    local tx = cx + dirX * self.attackRange
    local ty = cy + dirY * self.attackRange
    if Collisions.segmentHitsCircle(cx, cy, tx, ty, px, py, player.radius) then
        player:takeDamage(self.weapon.damage)
    end
end

function Zombie:_moveTowardPlayer(dt)
    local step = self.speed * dt * self:getSpeedMultiplier() * self:getHitSlowMultiplier()
    local cx, cy = self:getCenter()
    local px, py = player:getCenter()

    self:_refreshPath(dt, cx, cy, px, py)
    local moveX, moveY = self:_getPathDirection(cx, cy)
    if not moveX then
        moveX, moveY = self:_getDirectionToPlayer()
    end

    moveX, moveY = self:_steerAroundOtherZombies(cx, cy, moveX, moveY)

    tryMove(self, moveX * step, moveY * step, false)
end

function Zombie:_steerAroundOtherZombies(cx, cy, moveX, moveY)
    local sepX, sepY = 0, 0
    for _, other in ipairs(zombies) do
        if other ~= self then
            local ox, oy = other:getCenter()
            local dx = cx - ox
            local dy = cy - oy
            local distSq = dx * dx + dy * dy
            if distSq > 0 and distSq < SEPARATION_RADIUS * SEPARATION_RADIUS then
                local dist = math.sqrt(distSq)
                local strength = (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS
                sepX = sepX + (dx / dist) * strength
                sepY = sepY + (dy / dist) * strength
            end
        end
    end

    local sepLen = math.sqrt(sepX * sepX + sepY * sepY)
    if sepLen == 0 then return moveX, moveY end

    local desiredX = moveX + (sepX / sepLen) * SEPARATION_WEIGHT
    local desiredY = moveY + (sepY / sepLen) * SEPARATION_WEIGHT
    local len = math.sqrt(desiredX * desiredX + desiredY * desiredY)
    if len == 0 then return moveX, moveY end
    return desiredX / len, desiredY / len
end

function Zombie:_updateStab(dt)
    if self.stabTimer > 0 then
        self.stabTimer = math.max(0, self.stabTimer - dt)
    end
end

function Zombie:_refreshPath(dt, cx, cy, px, py)
    self.pathTimer = self.pathTimer - dt
    if self.pathTimer > 0 and #self.path >= 2 then return end
    self.pathTimer = PATH_RECALC_INTERVAL

    local startCol = math.floor(cx / grid.tileSize) + 1
    local startRow = math.floor(cy / grid.tileSize) + 1
    local endCol = math.floor(px / grid.tileSize) + 1
    local endRow = math.floor(py / grid.tileSize) + 1
    self.path = Pathfinding.findPath(startCol, startRow, endCol, endRow, grid, self.radius)
end

function Zombie:_getPathDirection(cx, cy)
    while #self.path >= 2 do
        local waypoint = self.path[2]
        local wx = (waypoint.col - 1) * grid.tileSize + grid.tileSize / 2
        local wy = (waypoint.row - 1) * grid.tileSize + grid.tileSize / 2
        local dx = wx - cx
        local dy = wy - cy
        local distSq = dx * dx + dy * dy
        if distSq < WAYPOINT_RADIUS * WAYPOINT_RADIUS then
            table.remove(self.path, 1)
        else
            local dist = math.sqrt(distSq)
            return dx / dist, dy / dist
        end
    end
    return nil
end

function Zombie:draw()
    if self:_isHiddenFromPlayer() then return end
    Zombie.super.draw(self)
    self:drawHealthBar()
    if Debug.isEnabled() then self:drawDebug() end
end

function Zombie:drawStab()
    if self.stabTimer <= 0 then return end
    if self:_isHiddenFromPlayer() then return end

    local cx, cy = self:getCenter()
    local progress = 1 - self.stabTimer / MELEE_STAB_DURATION
    local extend = progress < 0.5 and progress * 2 or 2 - progress * 2
    local length = self.attackRange * extend

    local ex = cx + self.stabDirX * length
    local ey = cy + self.stabDirY * length

    love.graphics.setColor(1, 0.5, 0.5, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.line(cx, cy, ex, ey)
    love.graphics.setLineWidth(1)
end

function Zombie:_isHiddenFromPlayer()
    local cx, cy = self:getCenter()
    if self:isOccludedFrom(player:getCenter()) then return true end
    if not player:isInVisionCone(cx, cy) then return true end
    return false
end

function Zombie:drawDebug()
    self:drawPlannedPath()
end

function Zombie:drawPlannedPath()
    love.graphics.setColor(0, 1, 0, 0.6)
    for i = 2, #self.path do
        local waypoint = self.path[i]
        local wx = (waypoint.col - 1) * grid.tileSize + grid.tileSize / 2
        local wy = (waypoint.row - 1) * grid.tileSize + grid.tileSize / 2
        love.graphics.circle("fill", wx, wy, 3)
        if i > 2 then
            local prev = self.path[i - 1]
            local prevX = (prev.col - 1) * grid.tileSize + grid.tileSize / 2
            local prevY = (prev.row - 1) * grid.tileSize + grid.tileSize / 2
            love.graphics.line(prevX, prevY, wx, wy)
        end
    end
end

function Zombie:drawHealthBar()
    local offset = 5
    local height = 3
    love.graphics.setColor({0, 0, 0})
    love.graphics.rectangle("line", self.x, self.y+self.height+offset, self.width, height)
    love.graphics.setColor({1, 1, 1})
    love.graphics.rectangle("fill", self.x, self.y+self.height+offset, self.width, height)
    love.graphics.setColor(self:_getHealthBarColor())
    love.graphics.rectangle("fill", self.x, self.y+self.height+offset, self.width*self.health/self.maxHealth, height)
end

function Zombie:_getHealthBarColor()
    if self.health > self.maxHealth / 4 * 2 then
        return {0.2, 1, 0.2}
    elseif self.health > self.maxHealth / 4 then
        return {1, 0.7, 0.1}
    end
    return {1, 0.2, 0.2}
end
