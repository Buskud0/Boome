Zombie = Entity:extend()

function Zombie:new(type, x, y)
    Zombie.super.new(self, x, y)
    self.type = type or "normal"
    self.dx = 0
    self.dy = 0
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
    self:_moveTowardPlayer(dt)
end

function Zombie:_moveTowardPlayer(dt)
    self.dx = player.x - self.x
    self.dy = player.y - self.y
    local dist = math.sqrt(self.dx^2 + self.dy^2)
    if dist ~= 0 then
        self.dx = self.dx / dist
        self.dy = self.dy / dist
    end
    tryMove(self, self.dx * self.speed * dt, self.dy * self.speed * dt, false)
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
