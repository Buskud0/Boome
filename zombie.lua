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
end