Entity = Object:extend()

function Entity:new(x, y)
    self.x = x
    self.y = y
    self.width = 40
    self.height = 40
    self.radius = 18
    self.health = 100
    self.color = {1, 1, 1}
end

function Entity:getCenter()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Entity:draw()
    if self.sprite then
        Textures.draw(self.sprite, self.x, self.y, self.width, self.height)
    else
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
    if debugDraw then self:drawHitbox() end
end

function Entity:drawHitbox()
    local cx, cy = self:getCenter()
    love.graphics.setColor(1, 0, 1, 0.5)
    love.graphics.circle("line", cx, cy, self.radius)
    love.graphics.setColor(1, 1, 0, 0.3)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.circle("fill", cx, cy, 2)
end
