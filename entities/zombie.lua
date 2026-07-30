Zombie = Entity:extend()
local Pathfinding = require "core.pathfinding"

function Zombie:new(type, x, y)
    Zombie.super.new(self, x, y)
    self.type = type or "normal"
    if self.type == "normal" then
        self.speed = 50
        self.maxHealth = 100
        self.color = {1, 0.2, 0}
        self.damage = 60
    end
    if self.type == "heavy" then
        self.speed = 25
        self.maxHealth = 300
        self.color = {1, 0.2, 0.5}
        self.damage = 90
    end
    if self.type == "light" then
        self.speed = 100
        self.maxHealth = 50
        self.color = {0.8, 0.6, 0}
        self.damage = 30
    end
    self.health = self.maxHealth
    self.hasHitPlayer = false
    self.sprite = "zombie_" .. self.type
    self.path = {}
end

function Zombie:update(dt)
    local cx, cy = self:getCenter()
    local px, py = player:getCenter()
    local dx = px - cx
    local dy = py - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return end

    local nx = dx / dist
    local ny = dy / dist
    local step = self.speed * dt
    local moveX, moveY

    if not grid:isCircleBlocked(cx + nx * step, cy + ny * step, self.radius) then
        self.path = {}
        moveX, moveY = nx, ny
    else
        if #self.path < 2 then
            local startCol = math.floor(cx / grid.tileSize) + 1
            local startRow = math.floor(cy / grid.tileSize) + 1
            local endCol = math.floor(px / grid.tileSize) + 1
            local endRow = math.floor(py / grid.tileSize) + 1
            self.path = Pathfinding.findPath(startCol, startRow, endCol, endRow, grid, 2)
        end

        if #self.path >= 2 then
            local target = self.path[2]
            local targetX = (target.col - 1) * grid.tileSize + grid.tileSize / 2
            local targetY = (target.row - 1) * grid.tileSize + grid.tileSize / 2
            local tdx = targetX - cx
            local tdy = targetY - cy
            if tdx * tdx + tdy * tdy < 9 then
                table.remove(self.path, 1)
            else
                local tdist = math.sqrt(tdx * tdx + tdy * tdy)
                moveX = tdx / tdist
                moveY = tdy / tdist
            end
        end
    end

    if moveX and moveY then
        tryMove(self, moveX * step, moveY * step, false)
    end
end

function Zombie:draw()
    Zombie.super.draw(self)
    self:drawHealthBar()
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
