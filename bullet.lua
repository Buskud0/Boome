Bullet = Object:extend()

function Bullet:new(x, y, dx, dy, damage)
	self.x = x
	self.y = y
	self.width = 4
	self.height = 4
	self.dx = dx
	self.dy = dy
	self.damage = damage
end

function Bullet:update(dt)
	self.x = self.x + (self.dx * dt)
    self.y = self.y + (self.dy * dt)
end

function Bullet:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end