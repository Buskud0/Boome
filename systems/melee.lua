Melee = Weapon:extend()

function Melee:new(model)
    Melee.super.new(self, model)
    local stats = WEAPONS[model]

    self.range = stats.range or 50
    self.swingRange = self.range
    self.swingHalfAngle = MELEE_SWING_HALF_ANGLE

    self.stabTimer = 0
    self.stabDirX, self.stabDirY = 0, 0
    self.swingTimer = 0
    self.swingShotFirst = false
    self.swingDirX, self.swingDirY = 0, 0
end

function Melee:update(dt)
    Weapon.update(self, dt)
    self:_updateStab(dt)
    self:_updateSwing(dt)
    self:_trySwing()
end

function Melee:drawWorld()
    self:_drawStab()
    self:_drawSwing()
end

function Melee:_tryAttack()
    if Inventory.dragSlot or ignoreMouseUntilRelease then return end
    if not Input.isDown("shoot") then
        self.shotFirstBullet = false
        return
    end
    if self.firerateCooldown > 0 or self.shotFirstBullet then return end
    if not self:_spendStamina(MELEE_STAB_STAMINA_COST) then return end

    self:_performStab()

    self.firerateCooldown = self.firerate
    if not self.automatic then self.shotFirstBullet = true end
end

function Melee:_updateStab(dt)
    if self.stabTimer > 0 then
        self.stabTimer = math.max(0, self.stabTimer - dt)
    end
end

function Melee:_trySwing()
    if Inventory.dragSlot or ignoreMouseUntilRelease then return end
    if not Input.isDown("swing") then
        self.swingShotFirst = false
        return
    end
    if self.firerateCooldown > 0 or self.swingShotFirst then return end
    if not self:_spendStamina(MELEE_SWING_STAMINA_COST) then return end

    self:_performSwing()

    self.firerateCooldown = self.firerate
    if not self.automatic then self.swingShotFirst = true end
end

function Melee:_spendStamina(cost)
    if player.stamina >= STAMINA_USE_THRESHOLD then
        player:spendStamina(cost)
        return true
    end
    return false
end

function Melee:_updateSwing(dt)
    if self.swingTimer > 0 then
        self.swingTimer = math.max(0, self.swingTimer - dt)
    end
end

function Melee:_performSwing()
    local px, py = player:getCenter()
    local dirX, dirY = self:_getAimDirection(px, py)
    if dirX == 0 and dirY == 0 then return end

    self.swingTimer = MELEE_SWING_DURATION
    self.swingDirX, self.swingDirY = dirX, dirY

    for _, zombie in ipairs(zombies) do
        local zx, zy = zombie:getCenter()
        if Collisions.circleHitsSector(px, py, dirX, dirY, self.swingHalfAngle, self.swingRange, zx, zy, zombie.radius) then
            zombie:takeDamage(self.damage)
            table.insert(damageTexts, DamageText(-self.damage, zombie.x, zombie.y))
        end
    end
end

function Melee:_performStab()
    local px, py = player:getCenter()
    local dirX, dirY = self:_getAimDirection(px, py)
    if dirX == 0 and dirY == 0 then return end

    self.stabTimer = MELEE_STAB_DURATION
    self.stabDirX, self.stabDirY = dirX, dirY

    local tx = px + dirX * self.range
    local ty = py + dirY * self.range

    for _, zombie in ipairs(zombies) do
        local zx, zy = zombie:getCenter()
        if Collisions.segmentHitsCircle(px, py, tx, ty, zx, zy, zombie.radius) then
            zombie:takeDamage(self.damage)
            table.insert(damageTexts, DamageText(-self.damage, zombie.x, zombie.y))
        end
    end
end

function Melee:_drawStab()
    if self.stabTimer <= 0 then return end

    local px, py = player:getCenter()
    local progress = 1 - self.stabTimer / MELEE_STAB_DURATION
    local extend = progress < 0.5 and progress * 2 or 2 - progress * 2
    local length = self.range * extend

    local ex = px + self.stabDirX * length
    local ey = py + self.stabDirY * length

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.line(px, py, ex, ey)
    love.graphics.setLineWidth(1)
end

function Melee:_drawSwing()
    if self.swingTimer <= 0 then return end

    local px, py = player:getCenter()
    local baseAngle = math.atan2(self.swingDirY, self.swingDirX)
    local progress = 1 - self.swingTimer / MELEE_SWING_DURATION
    local swingAngle = baseAngle - self.swingHalfAngle + self.swingHalfAngle * 2 * progress

    local ex = px + math.cos(swingAngle) * self.swingRange
    local ey = py + math.sin(swingAngle) * self.swingRange

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.line(px, py, ex, ey)
    love.graphics.setLineWidth(1)
end
