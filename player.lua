Player = Object:extend()

function Player:new(x, y)
    self.width = 40
    self.height = 40
    self.speed = 200
    self.color = {0, 1, 0}
    self.health = 100
    self.x = x
    self.y = y
end

function Player:update(dt)
    --movement with check that player isnt out of window
    if self.y>=0                      and love.keyboard.isDown("w") then self.y = self.y - self.speed*dt end
    if self.y<=scrHeight-self.height  and love.keyboard.isDown("s") then self.y = self.y + self.speed*dt end
    if self.x>=0                      and love.keyboard.isDown("a") then self.x = self.x - self.speed*dt end
    if self.x<=scrWidth-self.width    and love.keyboard.isDown("d") then self.x = self.x + self.speed*dt end
end

function Player:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end