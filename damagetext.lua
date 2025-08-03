DamageText = Object:extend()

function DamageText:new(text, x, y)
	self.text = text
	self.x = x
	self.y = y
	self.duration = 0.5
	self.destruct = false
	self.opacity = 1
end

function DamageText:update(dt)
	if self.duration > 0 then
		self.duration = self.duration - dt
		self.y = self.y - 50 * dt
		if self.duration < 0.3 then self.opacity = self.opacity - 5 * dt end
	else 
		self.destruct = true 
	end
end

function DamageText:draw()
	local font = love.graphics.newFont("fonts/Gamer.ttf", 22)
	love.graphics.setFont(font)
	love.graphics.setColor({1,1,1,self.opacity})
	love.graphics.print(self.text, self.x, self.y)
end