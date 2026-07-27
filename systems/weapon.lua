Weapon = Object:extend()

function Weapon:new(model)
    local stats = WEAPONS[model]
    if not stats then error("unknown weapon model: " .. model) end

    self.model = model
    self.bulletSpeed = WEAPON_BULLET_SPEED

    self.automatic = stats.automatic
    self.damage = stats.damage
    self.magSize = stats.magSize
    self.reloadTime = stats.reloadTime
    self.firerate = stats.firerate
    self.bulletAmount = stats.bulletAmount
    self.spread = stats.spread

    self.capacity = self.magSize
    self.firerateCooldown = 0
    self.reloadCooldown = 0
    self.reloading = false
    self.shotFirstBullet = false
    self.reloadProgress = 0
    self.firerateProgress = 0
end

function Weapon:update(dt)
    self:_updateFirerateCooldown(dt)
    self:reload(dt)
    self:_tryShoot()
end

function Weapon:_updateFirerateCooldown(dt)
    if self.firerateCooldown > 0 then
        self.firerateCooldown = self.firerateCooldown - dt
        if self.firerate >= 1 then
            self.firerateProgress = 1 - self.firerateCooldown / self.firerate
        end
    end
end

function Weapon:_tryShoot()
    if not Input.isDown("shoot") then
        self.shotFirstBullet = false
        return
    end
    if self.firerateCooldown > 0 or self.reloading or self.shotFirstBullet then
        return
    end
    for i = 1, self.bulletAmount do
        self:shootBullet()
    end
    self.firerateCooldown = self.firerate
    if not self.automatic then self.shotFirstBullet = true end
    self.capacity = self.capacity - 1
end

function Weapon:draw()
    local font = love.graphics.newFont("fonts/Gamer.ttf", 40)
    love.graphics.setFont(font)
    love.graphics.setColor({1, 1, 1})
    love.graphics.print(self.model .. " " .. self.capacity .. "/" .. self.magSize .. " ", 10 + camera.x, 0 + camera.y)
    if self.reloading then
        love.graphics.arc("fill", love.mouse.getX() + camera.x, love.mouse.getY() + camera.y, 15, 0, math.pi * 2 * self.reloadProgress)
    end
    if self.firerateCooldown > 0 and not self.reloading then
        love.graphics.arc("line", love.mouse.getX() + camera.x, love.mouse.getY() + camera.y, 15, 0, math.pi * 2 * self.firerateProgress)
    end
end

function Weapon:shootBullet()
    local startX = player.x + player.width / 2
    local startY = player.y + player.height / 2
    local mouseX = love.mouse.getX() + camera.x
    local mouseY = love.mouse.getY() + camera.y

    local bulletDx = mouseX - startX
    local bulletDy = mouseY - startY
    local length = math.sqrt(bulletDx * bulletDx + bulletDy * bulletDy)
    if length ~= 0 then
        bulletDx = bulletDx / length + randNegPos(0.01) * self.spread
        bulletDy = bulletDy / length + randNegPos(0.01) * self.spread
    end
    bulletDx = bulletDx * self.bulletSpeed
    bulletDy = bulletDy * self.bulletSpeed
    table.insert(bullets, Bullet(startX, startY, bulletDx, bulletDy, self.damage))
end

function Weapon:reload(dt)
    if self.reloadCooldown > 0 then
        self.reloadCooldown = self.reloadCooldown - dt
        self.reloadProgress = 1 - self.reloadCooldown / self.reloadTime
    end

    if self.capacity <= 0 and not self.reloading then
        self.reloadCooldown = self.reloadTime
        self.reloading = true
    end

    if self.reloading and self.reloadCooldown <= 0 then
        self.capacity = self.magSize
        self.reloadProgress = 0
        self.reloading = false
    end
end
