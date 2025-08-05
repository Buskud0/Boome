Weapon = Object:extend()

function Weapon:new(model)
	self.model = model
	self.firerateCooldown = 0
	self.bulletSpeed = 1500
	self.reloadCooldown = 0
	self.reloading = false
	self.shotFirstBullet = false
	self.bulletAmount = 1
	self.spread = 0
	self.reloadProgress = 0
	self.firerateProgress = 0

	if model == "m9" then
		self.automatic = false
		self.damage = 13
		self.magSize = 15
		self.reloadTime = 1
		self.firerate = 0.15
	elseif model == "mac10" then
		self.automatic = true
		self.damage = 12
		self.magSize = 30
		self.reloadTime = 2
		self.firerate = 0.1
	elseif model == "remington870" then
		self.automatic = false
		self.damage = 9
		self.magSize = 5
		self.reloadTime = 4
		self.firerate = 1
		self.bulletAmount = 12
		self.spread = 12
	elseif model == "AWM" then
		self.automatic = false
		self.damage = 100
		self.magSize = 5
		self.reloadTime = 3
		self.firerate = 1.5
	end

	self.capacity = self.magSize
end

function Weapon:update(dt)
	--update firerate and reload cooldowns
    if self.firerateCooldown > 0 then 
    	self.firerateCooldown = self.firerateCooldown - dt 
    	if self.firerate >= 1 then self.firerateProgress = (1 - self.firerateCooldown / self.firerate) end
    end
    if self.reloadCooldown > 0 then 
    	self.reloadCooldown = self.reloadCooldown - dt 
    	self.reloadProgress = (1 - self.reloadCooldown / self.reloadTime)
    end
    --reload weapon
    if self.capacity <= 0 and self.reloading == false then
    	self.reloadCooldown = self.reloadTime
    	self.reloading = true
    end
    --do while reloading
    if self.reloading and self.reloadCooldown <= 0 then 
		self.capacity = self.magSize 
		self.reloadProgress = 0
		self.reloading = false
    end
    --shoot
    if love.mouse.isDown(1) and self.firerateCooldown <= 0 and not self.reloading and not self.shotFirstBullet then
    		for i = 1, self.bulletAmount do self:shootBullet() end
        	self.firerateCooldown = self.firerate
        	if not self.automatic then self.shotFirstBullet = true end
        	self.capacity = self.capacity - 1
    elseif not love.mouse.isDown(1) then self.shotFirstBullet = false end
end


function Weapon:draw()
	local font = love.graphics.newFont("fonts/Gamer.ttf", 40)
	love.graphics.setFont(font)
	love.graphics.setColor({1,1,1}) 
	love.graphics.print(self.model .. " " .. self.capacity .. "/" .. self.magSize .. " " , 10, 0)
	if self.reloading then 
		love.graphics.arc("fill", love.mouse.getX(), love.mouse.getY(), 15, 0, math.pi*2 * self.reloadProgress) 
	end
	if self.firerateCooldown > 0 and not self.reloading then 
		love.graphics.arc("line", love.mouse.getX(), love.mouse.getY(), 15, 0, math.pi*2 * self.firerateProgress) 
	end
end

function Weapon:shootBullet()
    local startX = player.x + player.width / 2
    local startY = player.y + player.height / 2
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()
    
    local bulletDx = mouseX - startX
	local bulletDy = mouseY - startY
	local length = math.sqrt(bulletDx*bulletDx + bulletDy*bulletDy)
	if (length ~= 0) then
  		bulletDx = bulletDx/length + randNegPos(0.01)*self.spread
  		bulletDy = bulletDy/length + randNegPos(0.01)*self.spread
	end
    bulletDx = bulletDx * self.bulletSpeed
    bulletDy = bulletDy * self.bulletSpeed
    table.insert(bullets, Bullet(startX, startY, bulletDx, bulletDy, self.damage))
end

