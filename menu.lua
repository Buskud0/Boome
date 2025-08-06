Menu = Object:extend()

function Menu:new()
	self.width = scrWidth/4
	self.height = scrHeight/2
	self.x = scrWidth/2 - self.width/2
	self.y = scrHeight/2 - self.height/2
end

function Menu:update(dt)
	
end

function Menu:draw()
	self:drawBackground()
end

function Menu:drawBackground()
	love.graphics.setColor({1,1,1})
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	self:print("GAME PAUSED", 0)
end

function Menu:print(text, offset)
	offset = offset or 0
	self:grid()
	local font = love.graphics.newFont("fonts/Gamer.ttf", 40)
	love.graphics.setFont(font)
	love.graphics.setColor({0,0,0})
	local textWidth = font:getWidth(text)
	love.graphics.print(text, self.x + self.width/2-textWidth/2, self.y + offset)
end

function Menu:grid()
	love.graphics.setColor({0.9,0.9,0.9})
	local ySize = 40
	local rows = 7
	for i = 1, rows do
		love.graphics.rectangle("fill", self.x, self.y+ySize*i, self.width, ySize-3)
	end
end