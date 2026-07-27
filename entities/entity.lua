Entity = Object:extend()

function Entity:new(x, y)
    self.x = x
    self.y = y
    self.width = 40
    self.height = 40
    self.health = 100
    self.color = {1, 1, 1}
end

function Entity:draw()
    if self.sprite then
        Textures.draw(self.sprite, self.x, self.y, self.width, self.height)
    else
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
end
