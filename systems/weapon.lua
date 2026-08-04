Weapon = Object:extend()

local SCOPE_PAN_SPEED = WEAPON_SCOPE_PAN_SPEED

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

function Weapon:isScoping()
    return false
end

function Weapon:updateScope(dt) end

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
    self.hipfireSpread = stats.hipfireSpread or stats.spread
    self.penetrationLoss = stats.penetrationLoss
    self.scope = stats.scope

    self.capacity = self.magSize
    self.reloadCooldown = 0
    self.reloading = false
    self.reloadProgress = 0
    self.scopePanSpeed = SCOPE_PAN_SPEED
    self.scopeOffsetX = 0
    self.scopeOffsetY = 0
    self.scopeProgress = 0
end

function Gun:isScoping()
    return self.scope ~= nil and not self.reloading and Input.isDown("swing")
end

function Gun:updateScope(dt)
    local targetX, targetY = 0, 0
    if self:isScoping() then
        local mouseX, mouseY = screenToWorld(love.mouse.getPosition())
        local px, py = player:getCenter()
        local dx, dy = mouseX - px, mouseY - py
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            dx, dy = dx / len, dy / len
            targetX, targetY = dx * self.scope, dy * self.scope
        end
    end

    local alpha = math.min(1, self.scopePanSpeed * dt)
    self.scopeOffsetX = self.scopeOffsetX + (targetX - self.scopeOffsetX) * alpha
    self.scopeOffsetY = self.scopeOffsetY + (targetY - self.scopeOffsetY) * alpha
    local targetProgress = self:isScoping() and 1 or 0
    self.scopeProgress = self.scopeProgress + (targetProgress - self.scopeProgress) * alpha
    camera.x = camera.x + self.scopeOffsetX
    camera.y = camera.y + self.scopeOffsetY
end

function Gun:update(dt)
    Weapon.update(self, dt)
    self:reload(dt)
end

function Gun:_tryAttack()
    if not self:_isAttackPermitted() then return end
    self:_fireBullets()
    self:_registerShot()
end

function Gun:_isAttackPermitted()
    if Inventory.drag or ignoreMouseUntilRelease then return false end
    if not Input.isDown("shoot") then
        self.shotFirstBullet = false
        return false
    end
    if self.firerateCooldown > 0 or self.reloading or self.shotFirstBullet then return false end
    return true
end

function Gun:_fireBullets()
    for i = 1, self.bulletAmount do
        self:shootBullet()
    end
end

function Gun:_registerShot()
    self.firerateCooldown = self.firerate
    if not self.automatic then self.shotFirstBullet = true end
    self.capacity = self.capacity - 1
end

function Gun:draw()
    self:_drawReloadArc()
    self:_drawFirerateArc()
end

function Gun:_drawReloadArc()
    if not self.reloading then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.arc("fill", love.mouse.getX() + camera.x, love.mouse.getY() + camera.y, 15, 0, math.pi * 2 * self.reloadProgress)
end

function Gun:_drawFirerateArc()
    if self.firerateCooldown <= 0 or self.reloading then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.arc("line", love.mouse.getX() + camera.x, love.mouse.getY() + camera.y, 15, 0, math.pi * 2 * self.firerateProgress)
end

function Gun:shootBullet()
    local startX, startY = self:_getMuzzlePosition()
    local bulletDx, bulletDy = self:_calculateBulletDirection(startX, startY)
    table.insert(bullets, Bullet(startX, startY, bulletDx, bulletDy, self.damage, self.penetrationLoss))
end

function Gun:_getMuzzlePosition()
    return player.x + player.width / 2, player.y + player.height / 2
end

function Gun:getEffectiveSpread()
    return self.spread + (self.hipfireSpread - self.spread) * (1 - self.scopeProgress)
end

function Gun:_calculateBulletDirection(startX, startY)
    local dx, dy = self:_getAimDirection(startX, startY)
    if dx ~= 0 or dy ~= 0 then
        dx = dx + randNegPos(0.01) * self:getEffectiveSpread()
        dy = dy + randNegPos(0.01) * self:getEffectiveSpread()
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
