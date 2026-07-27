Player = Object:extend()

function Player:new(x, y)
    self.width = 40
    self.height = 40
    self.speed = 200
    self.color = {0, 1, 0}
    self.health = 100
    self.money = 0
    self.x = x
    self.y = y
end

function Player:update(dt)
    if self.y>=0                      and Input.isDown("move_up") then self.y = self.y - self.speed*dt end
    if self.y<=mapHeight-self.height  and Input.isDown("move_down") then self.y = self.y + self.speed*dt end
    if self.x>=0                      and Input.isDown("move_left") then self.x = self.x - self.speed*dt end
    if self.x<=mapWidth-self.width    and Input.isDown("move_right") then self.x = self.x + self.speed*dt end

    if self.health <= 0 then
        resetGame()
    end

end

function Player:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end