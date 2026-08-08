local Weapon = require "systems.weapon.weapon"
local Config = require "core.config"
local Input = require "core.input"
local Collision = require "world.physics.collision"
local DamageText = require "entities.damage_text"

local Melee = Weapon:extend()
local STAB_DURATION = Config.MELEE_STAB_DURATION
local SWING_DURATION = Config.MELEE_SWING_DURATION
local SWING_HALF_ANGLE = Config.MELEE_SWING_HALF_ANGLE
local STAB_STAMINA_COST = Config.MELEE_STAB_STAMINA_COST
local SWING_STAMINA_COST = Config.MELEE_SWING_STAMINA_COST

function Melee:new(state, model)
    Melee.super.new(self, state, model)
    local stats = Config.WEAPONS[model]

    self.range = stats.range or 50
    self.swingRange = self.range
    self.swingHalfAngle = SWING_HALF_ANGLE
    self.stabStaminaCost = stats.stabStaminaCost or STAB_STAMINA_COST
    self.swingStaminaCost = stats.swingStaminaCost or SWING_STAMINA_COST
    self.blockDamageMultiplier = stats.blockDamageMultiplier

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
    if not self:_isMeleeInputReady("shoot", "shotFirstBullet") then return end
    if not self:_spendStamina(self.stabStaminaCost) then return end

    self:_performStab()
    self:_startMeleeCooldown("shotFirstBullet")
end

function Melee:_trySwing()
    if not self:_isMeleeInputReady("swing", "swingShotFirst") then return end
    if not self:_spendStamina(self.swingStaminaCost) then return end

    self:_performSwing()
    self:_startMeleeCooldown("swingShotFirst")
end

function Melee:_isMeleeInputReady(inputAction, wasPressedFlag)
    if self.state.inventory.drag or self.state.ignoreMouseUntilRelease then return false end
    if inputAction == "swing" and self.state.suppressSwing then
        if not Input.isDown("swing") then
            self.state.suppressSwing = false
        end
        return false
    end
    if not Input.isDown(inputAction) then
        self[wasPressedFlag] = false
        return false
    end
    if self.firerateCooldown > 0 or self[wasPressedFlag] then return false end
    return true
end

function Melee:_startMeleeCooldown(wasPressedFlag)
    self.firerateCooldown = self.firerate
    if not self.automatic then self[wasPressedFlag] = true end
end

function Melee:_updateStab(dt)
    if self.stabTimer > 0 then
        self.stabTimer = math.max(0, self.stabTimer - dt)
    end
end

function Melee:_updateSwing(dt)
    if self.swingTimer > 0 then
        self.swingTimer = math.max(0, self.swingTimer - dt)
    end
end

function Melee:_spendStamina(cost)
    local player = self.state.player
    if player.stamina < cost then return false end
    player:spendStamina(cost)
    return true
end

function Melee:_performSwing()
    local px, py = self.state.player:getCenter()
    local dirX, dirY = self:_getAimDirection(px, py)
    if dirX == 0 and dirY == 0 then return end

    self:_startSwingAnimation(dirX, dirY)
    self:_damageZombiesInSector(px, py, dirX, dirY)
    self:_damageBlocksInSector(px, py, dirX, dirY)
end

function Melee:_damageBlocksInSector(px, py, dirX, dirY)
    local records = self.state.grid:destructibleRecordsInSector(px, py, dirX, dirY, self.swingHalfAngle, self.swingRange)
    for _, record in ipairs(records) do
        self.state.grid:damageRecord(record, self:_damageFor(record))
    end
end

function Melee:_damageFor(record)
    if not record or not self.blockDamageMultiplier then return self.damage end
    return self.damage * self.blockDamageMultiplier
end

function Melee:_performStab()
    local px, py = self.state.player:getCenter()
    local dirX, dirY = self:_getAimDirection(px, py)
    if dirX == 0 and dirY == 0 then return end

    self:_startStabAnimation(dirX, dirY)
    self:_damageZombiesAlongSegment(px, py, dirX, dirY)
    self:_damageBlockAtTip(dirX, dirY)
end

function Melee:_damageBlockAtTip(dirX, dirY)
    local px, py = self.state.player:getCenter()
    local tx = px + dirX * self.range
    local ty = py + dirY * self.range
    local record = self.state.grid:destructibleRecordAt(tx, ty)
    if record then
        self.state.grid:damageRecord(record, self:_damageFor(record))
    end
end

function Melee:_startSwingAnimation(dirX, dirY)
    self.swingTimer = SWING_DURATION
    self.swingDirX, self.swingDirY = dirX, dirY
end

function Melee:_startStabAnimation(dirX, dirY)
    self.stabTimer = STAB_DURATION
    self.stabDirX, self.stabDirY = dirX, dirY
end

function Melee:_damageZombiesAlongSegment(px, py, dirX, dirY)
    local tx = px + dirX * self.range
    local ty = py + dirY * self.range
    for _, zombie in ipairs(self.state.zombies) do
        local zx, zy = zombie:getCenter()
        if Collision.segmentHitsCircle(px, py, tx, ty, zx, zy, zombie.radius) then
            self:_damageZombie(zombie)
        end
    end
end

function Melee:_damageZombiesInSector(px, py, dirX, dirY)
    for _, zombie in ipairs(self.state.zombies) do
        local zx, zy = zombie:getCenter()
        if Collision.circleHitsSector(px, py, dirX, dirY, self.swingHalfAngle, self.swingRange, zx, zy, zombie.radius) then
            self:_damageZombie(zombie)
        end
    end
end

function Melee:_damageZombie(zombie)
    zombie:takeDamage(self.damage)
    table.insert(self.state.damageTexts, DamageText(-self.damage, zombie.x, zombie.y))
end

function Melee:_drawStab()
    if self.stabTimer <= 0 then return end

    local px, py = self.state.player:getCenter()
    local progress = 1 - self.stabTimer / STAB_DURATION
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

    local px, py = self.state.player:getCenter()
    local baseAngle = math.atan2(self.swingDirY, self.swingDirX)
    local progress = 1 - self.swingTimer / SWING_DURATION
    local swingAngle = baseAngle - self.swingHalfAngle + self.swingHalfAngle * 2 * progress

    local ex = px + math.cos(swingAngle) * self.swingRange
    local ey = py + math.sin(swingAngle) * self.swingRange

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.line(px, py, ex, ey)
    love.graphics.setLineWidth(1)
end

return Melee
