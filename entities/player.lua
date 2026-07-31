Player = Entity:extend()

function Player:new(x, y)
    Player.super.new(self, x, y)
    self.speed = PLAYER_SPEED
    self.color = {0, 1, 0}
    self.money = 0
    self.maxStamina = PLAYER_MAX_STAMINA
    self.stamina = self.maxStamina
    self.staminaRegenTimer = 0
    self.isSprinting = false
    self.sprite = "player"
end

function Player:takeDamage(amount)
    Player.super.takeDamage(self, amount)
    table.insert(damageTexts, DamageText(-amount, self.x, self.y, 1, {1, 0, 0}))
end

function Player:update(dt)
    Player.super.update(self, dt)
    self:_updateMovement(dt)
    if self.health <= 0 then resetGame() end
end

function Player:_updateMovement(dt)
    local isSprinting = self:_isSprinting()
    local oldX, oldY = self.x, self.y
    self:_handleMovement(dt, isSprinting)
    local actuallyMoved = self.x ~= oldX or self.y ~= oldY
    self:_applyStamina(dt, isSprinting and actuallyMoved)
    self.isSprinting = isSprinting and actuallyMoved
end

function Player:_isSprinting()
    if not Input.isDown("sprint") then return false end
    return self.stamina > STAMINA_SPRINT_THRESHOLD or (self.stamina > 0 and self.isSprinting)
end

function Player:spendStamina(amount)
    self.stamina = math.max(0, self.stamina - amount)
    self.staminaRegenTimer = STAMINA_REGEN_DELAY
end

function Player:_applyStamina(dt, isSprinting)
    if self.staminaRegenTimer > 0 then
        self.staminaRegenTimer = math.max(0, self.staminaRegenTimer - dt)
    end
    if isSprinting then
        self:spendStamina(PLAYER_SPRINT_DRAIN_RATE * dt)
    elseif self.staminaRegenTimer <= 0 then
        self.stamina = math.min(self.maxStamina, self.stamina + PLAYER_STAMINA_RECOVERY_RATE * dt)
    end
end

function Player:_handleMovement(dt, isSprinting)
    local speed = self:_getCurrentSpeed(isSprinting)
    local dx, dy = self:_readMovementInput()
    self:_applyMovement(dx, dy, speed, dt)
end

function Player:_getCurrentSpeed(isSprinting)
    local speed = self.speed
    if isSprinting then
        speed = speed * PLAYER_SPRINT_MULTIPLIER
    end
    return speed * self:getSpeedMultiplier() * self:getHitSlowMultiplier()
end

function Player:_readMovementInput()
    local dx, dy = 0, 0
    if Input.isDown("move_up") then dy = dy - 1 end
    if Input.isDown("move_down") then dy = dy + 1 end
    if Input.isDown("move_left") then dx = dx - 1 end
    if Input.isDown("move_right") then dx = dx + 1 end
    return dx, dy
end

function Player:_applyMovement(dx, dy, speed, dt)
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
        dx, dy = dx / length * speed * dt, dy / length * speed * dt
        tryMove(self, dx, dy)
    end
end
