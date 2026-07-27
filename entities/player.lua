Player = Entity:extend()

function Player:new(x, y)
    Player.super.new(self, x, y)
    self.speed = 200
    self.color = {0, 1, 0}
    self.money = 0
end

function Player:update(dt)
    local dx, dy = 0, 0
    if Input.isDown("move_up") then dy = dy - self.speed * dt end
    if Input.isDown("move_down") then dy = dy + self.speed * dt end
    if Input.isDown("move_left") then dx = dx - self.speed * dt end
    if Input.isDown("move_right") then dx = dx + self.speed * dt end
    tryMove(self, dx, dy)
    if self.health <= 0 then resetGame() end
end
