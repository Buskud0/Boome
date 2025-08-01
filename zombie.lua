Zombie = Object:extend()

function Zombie:new(x, y)
    self.width = 40
    self.height = 40
    self.speed = 50
    self.color = {1, 0.2, 0}
    self.health = 100
    self.x = x
    self.y = y
end

function Zombie:update(dt)
    if player.x > self.x then self.x = self.x + (self.speed * dt) end
    if player.x < self.x then self.x = self.x - (self.speed * dt) end
    if player.y > self.y then self.y = self.y + (self.speed * dt) end
    if player.y < self.y then self.y = self.y - (self.speed * dt) end
end

function Zombie:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    drawHealthBar(self)
end

function drawHealthBar(self)
    local offset = 5
    local height = 3
    love.graphics.setColor({0, 0, 0})
    love.graphics.rectangle("line", self.x, self.y+self.height+offset, self.width, height)
    love.graphics.setColor({1, 1, 1})
    love.graphics.rectangle("fill", self.x, self.y+self.height+offset, self.width, height)
    love.graphics.setColor({0.2, 1, 0.2})
    love.graphics.rectangle("fill", self.x, self.y+self.height+offset, self.width*self.health*0.01, height)
end
