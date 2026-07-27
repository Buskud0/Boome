Menu = Object:extend()

function Menu:new()
	self.width = 300
	self.height = 300
	self.x=0
	self.y=0
end

function Menu:update(dt)
	self.x = scrWidth/2 - self.width/2 + camera.x
	self.y = scrHeight/2 - self.height/2 + camera.y
end

function Menu:draw()
	self:drawBackground()
	self:grid()
	self:print("MAX KILLS -> "..maxKills, 30, 45)
	self:print("MAX ROUNDS SURVIVED -> "..maxRounds, 30, 85)
end

function Menu:drawBackground()
	love.graphics.setColor({1,1,1})
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	self:print("GAME PAUSED", 40, 0)
end

function Menu:print(text, fontSize, offset)
	offset = offset or 0
	local font = love.graphics.newFont("fonts/Gamer.ttf", fontSize)
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