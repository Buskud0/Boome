Bullet = Object:extend()

function Bullet:new(x, y, dx, dy, damage)
	self.x = x
	self.y = y
	self.width = 6
	self.height = 6
	self.dx = dx
	self.dy = dy
	self.damage = damage
end

function Bullet:update(dt)
	self.x = self.x + (self.dx * dt)
    self.y = self.y + (self.dy * dt)
end

function Bullet:draw()
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end