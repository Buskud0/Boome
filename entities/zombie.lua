Zombie = Entity:extend()

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
    tryMove(self, nx * step, ny * step, false)
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
