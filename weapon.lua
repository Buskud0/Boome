Weapon = Object:extend()

function Weapon:new(model)
	self.model = model
	self.firerateCooldown = 0
	self.reloadCooldown = 0
	self.bulletSpeed = 1500


	if model == "m9" then
		self.automatic = false
		self.damage = 16
		self.magSize = 12
	end

	if model == "mac10" then
		self.automatic = true
		self.damage = 12
		self.magSize = 30
	end

	self.capacity = self.magSize
end

function Weapon:update(dt)
    if self.firerateCooldown > 0 then self.firerateCooldown = self.firerateCooldown - dt end

    if self.reloadCooldown > 0 then self.reloadCooldown = self.reloadCooldown - dt end
    if self.reloadCooldown <= 0 and self.capacity == 0 then 
    	self.capacity = self.magSize 
    	self.reloadCooldown = 2
    end

    while self.automatic == true and love.mouse.isDown(1) and self.firerateCooldown <= 0 do
        if self.capacity > 0 and self.reloadCooldown <= 0 then shootBullet(12) end
        self.firerateCooldown = 0.1
    end
end

function love.mousepressed(x, y, button) --shoot towards mouse function
    --pistol
    if weapon.automatic == false and button == 1 and weapon.firerateCooldown <= 0 then
        if weapon.capacity > 0 and weapon.reloadCooldown <= 0 then shootBullet(16) end
        weapon.firerateCooldown = 0.15
    end
end

function reload()
end

function Weapon:draw()
	local font = love.graphics.newFont("fonts/Gamer.ttf", 40)
	love.graphics.setFont(font)
	love.graphics.setColor({1,1,1}) 
	love.graphics.print(self.model .. " " .. self.capacity .. "/" .. self.magSize, 10, 0)
end

function shootBullet(damage)
    local startX = player.x + player.width / 2
    local startY = player.y + player.height / 2
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()
    
    local angle = math.atan2((mouseY - startY), (mouseX - startX))
    
    local bulletDx = weapon.bulletSpeed * math.cos(angle)
    local bulletDy = weapon.bulletSpeed * math.sin(angle)
    
    table.insert(bullets, Bullet(startX, startY, bulletDx, bulletDy, damage))
    weapon.capacity = weapon.capacity - 1
end