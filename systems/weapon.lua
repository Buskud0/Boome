Weapon = Object:extend()

function Weapon:new(model)
    local stats = WEAPONS[model]
    if not stats then error("unknown weapon model: " .. model) end

    self.model = model
    self.damage = stats.damage
    self.firerate = stats.firerate
    self.automatic = stats.automatic
    self.price = stats.price

    self.firerateCooldown = 0
    self.firerateProgress = 0
    self.shotFirstBullet = false
end

function Weapon.create(model)
    local stats = WEAPONS[model]
    if stats and stats.weaponType == "melee" then
        return Melee(model)
    end
    return Gun(model)
end

function Weapon:update(dt)
    self:_updateFirerateCooldown(dt)
    self:_tryAttack()
end

function Weapon:draw() end

function Weapon:drawWorld() end

function Weapon:_tryAttack() end

function Weapon:_updateFirerateCooldown(dt)
    if self.firerateCooldown > 0 then
        self.firerateCooldown = self.firerateCooldown - dt
        if self.firerate >= 1 then
            self.firerateProgress = 1 - self.firerateCooldown / self.firerate
        end
    end
end

function Weapon:_getAimDirection(startX, startY)
    local mouseX, mouseY = screenToWorld(love.mouse.getX(), love.mouse.getY())
    local dx = mouseX - startX
    local dy = mouseY - startY
    local length = math.sqrt(dx * dx + dy * dy)
    if length == 0 then return 0, 0 end
    return dx / length, dy / length
end

Gun = Weapon:extend()

function Gun:new(model)
    Gun.super.new(self, model)
    local stats = WEAPONS[model]

    self.bulletSpeed = WEAPON_BULLET_SPEED
    self.magSize = stats.magSize
    self.reloadTime = stats.reloadTime
    self.bulletAmount = stats.bulletAmount
    self.spread = stats.spread

    self.capacity = self.magSize
    self.reloadCooldown = 0
    self.reloading = false
    self.reloadProgress = 0
end

function Gun:update(dt)
    Weapon.update(self, dt)
    self:reload(dt)
end

function Gun:_tryAttack()
    if Inventory.dragSlot or ignoreMouseUntilRelease then return end
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

function Gun:draw()
    self:_drawAmmoText()
    self:_drawReloadArc()
    self:_drawFirerateArc()
end

function Gun:_drawAmmoText()
    local font = love.graphics.newFont("fonts/Gamer.ttf", 40)
    love.graphics.setFont(font)
    love.graphics.setColor({1, 1, 1})
    love.graphics.print(self.model .. " " .. self.capacity .. "/" .. self.magSize .. " ", 10 + camera.x, 0 + camera.y)
end

function Gun:_drawReloadArc()
    if not self.reloading then return end
    love.graphics.arc("fill", love.mouse.getX() + camera.x, love.mouse.getY() + camera.y, 15, 0, math.pi * 2 * self.reloadProgress)
end

function Gun:_drawFirerateArc()
    if self.firerateCooldown <= 0 or self.reloading then return end
    love.graphics.arc("line", love.mouse.getX() + camera.x, love.mouse.getY() + camera.y, 15, 0, math.pi * 2 * self.firerateProgress)
end

function Gun:shootBullet()
    local startX, startY = self:_getMuzzlePosition()
    local bulletDx, bulletDy = self:_calculateBulletDirection(startX, startY)
    table.insert(bullets, Bullet(startX, startY, bulletDx, bulletDy, self.damage))
end

function Gun:_getMuzzlePosition()
    return player.x + player.width / 2, player.y + player.height / 2
end

function Gun:_calculateBulletDirection(startX, startY)
    local dx, dy = self:_getAimDirection(startX, startY)
    if dx ~= 0 or dy ~= 0 then
        dx = dx + randNegPos(0.01) * self.spread
        dy = dy + randNegPos(0.01) * self.spread
    end
    return dx * self.bulletSpeed, dy * self.bulletSpeed
end

function Gun:reload(dt)
    self:_updateReloadCooldown(dt)
    self:_triggerReload()
    self:_completeReload()
end

function Gun:_updateReloadCooldown(dt)
    if self.reloadCooldown > 0 then
        self.reloadCooldown = self.reloadCooldown - dt
        self.reloadProgress = 1 - self.reloadCooldown / self.reloadTime
    end
end

function Gun:_triggerReload()
    if self.capacity > 0 or self.reloading then return end
    self.reloadCooldown = self.reloadTime
    self.reloading = true
end

function Gun:_completeReload()
    if not self.reloading or self.reloadCooldown > 0 then return end
    self.capacity = self.magSize
    self.reloadProgress = 0
    self.reloading = false
end
