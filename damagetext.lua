DamageText = Object:extend()

function DamageText:new(text, x, y)
	self.text = text
	self.x = x
	self.y = y
	self.color = {1,1,1}
	self.duration = 0.3
	self.destruct = false
end

function DamageText:update(dt)
	if self.duration > 0 then
		self.duration = self.duration - dt
		self.y = self.y - 100 * dt
	else 
		self.destruct = true 
	end
end

function DamageText:draw()
	local font = love.graphics.newFont("fonts/Gamer.ttf", 20)
	love.graphics.setFont(font)
	love.graphics.setColor(self.color)
	love.graphics.print(self.text, self.x, self.y)
end