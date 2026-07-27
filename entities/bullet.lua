Bullet = Object:extend()

function Bullet:new(x, y, dx, dy, damage)
	self.x = x
	self.y = y
	self.width = 4
	self.height = 4
	self.dx = dx
	self.dy = dy
	self.damage = damage
	self.sprite = "bullet"
end

function Bullet:draw()
    Textures.draw(self.sprite, self.x, self.y, self.width, self.height)
end

function Bullet:update(dt)
	self.x = self.x + (self.dx * dt)
    self.y = self.y + (self.dy * dt)
end