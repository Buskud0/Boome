Zombie = Entity:extend()
local Pathfinding = require "core.pathfinding"

local PATH_RECALC_INTERVAL = 0.3
local WAYPOINT_RADIUS = 6

function Zombie:new(type, x, y)
    Zombie.super.new(self, x, y)
    self.type = type or "normal"
    if self.type == "normal" then
        self.speed = 50
        self.maxHealth = 100
        self.color = {1, 0.2, 0}
    end
    if self.type == "heavy" then
        self.speed = 25
        self.maxHealth = 300
        self.color = {1, 0.2, 0.5}
    end
    if self.type == "light" then
        self.speed = 100
        self.maxHealth = 50
        self.color = {0.8, 0.6, 0}
    end
    self.health = self.maxHealth
    self.sprite = "zombie_" .. self.type
    self.path = {}
    self.pathTimer = 0
    self.directionX, self.directionY = 0, 0
    self.weapon = Weapon.create("knife")
    self.attackRange = self.weapon.range
    self.attackCooldown = 1
    self.attackTimer = 0
    self.stabTimer = 0
    self.stabDirX, self.stabDirY = 0, 0
end

function Zombie:update(dt)
    Zombie.super.update(self, dt)
    self:_updateStab(dt)

    local cx, cy = self:getCenter()
    local px, py = player:getCenter()
    local dx = px - cx
    local dy = py - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return end

    if self:_updateAttack(dt, dist, dx, dy, px, py) then return end

    local step = self.speed * dt * self:getSpeedMultiplier() * self:getHitSlowMultiplier()
    local moveX, moveY

    -- Always plan a path toward the player and follow it.
    self:_refreshPath(dt, cx, cy, px, py)
    moveX, moveY = self:_getPathDirection(cx, cy)
    if not moveX then
        moveX, moveY = dx / dist, dy / dist
    end

    self.directionX, self.directionY = moveX, moveY
    tryMove(self, moveX * step, moveY * step, false)
end

function Zombie:_updateAttack(dt, dist, dx, dy, px, py)
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    if dist > self.attackRange then return false end

    local dirX, dirY = dx / dist, dy / dist
    self.directionX, self.directionY = dirX, dirY

    if self.attackTimer > 0 then return true end

    self.attackTimer = self.attackCooldown
    self.stabTimer = MELEE_STAB_DURATION
    self.stabDirX, self.stabDirY = dirX, dirY

    local cx, cy = self:getCenter()
    local tx = cx + dirX * self.attackRange
    local ty = cy + dirY * self.attackRange
    if Collisions.segmentHitsCircle(cx, cy, tx, ty, px, py, player.radius) then
        player:takeDamage(self.weapon.damage)
    end
    return true
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
    Zombie.super.draw(self)
    self:drawHealthBar()
    self:_drawStab()
    if debugDraw then self:drawDebug() end
end

function Zombie:_drawStab()
    if self.stabTimer <= 0 then return end

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

function Zombie:drawDebug()
    local cx, cy = self:getCenter()

    -- Predicted movement direction
    love.graphics.setColor(0, 1, 1, 0.9)
    love.graphics.line(cx, cy, cx + self.directionX * 30, cy + self.directionY * 30)

    -- Planned path waypoints
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
    if self.health > self.maxHealth/4*2 then love.graphics.setColor({0.2, 1, 0.2})
    elseif self.health > self.maxHealth/4 then love.graphics.setColor({1, 0.7, 0.1})
    else love.graphics.setColor({1, 0.2, 0.2}) end
    love.graphics.rectangle("fill", self.x, self.y+self.height+offset, self.width*self.health/self.maxHealth, height)
end
