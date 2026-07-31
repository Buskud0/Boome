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

    local wantToSprint = Input.isDown("sprint")
    local currentSprinting = wantToSprint and self.stamina >= STAMINA_USE_THRESHOLD

    local oldX, oldY = self.x, self.y
    self:_handleMovement(dt, currentSprinting)

    local actuallyMoved = self.x ~= oldX or self.y ~= oldY
    local isSprinting = currentSprinting and actuallyMoved
    self:_applyStamina(dt, isSprinting)
    self.isSprinting = isSprinting

    if self.health <= 0 then resetGame() end
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
    local speed = (isSprinting and self.speed * PLAYER_SPRINT_MULTIPLIER or self.speed) * self:getSpeedMultiplier() * self:getHitSlowMultiplier()

    local dx, dy = 0, 0
    if Input.isDown("move_up") then dy = dy - speed * dt end
    if Input.isDown("move_down") then dy = dy + speed * dt end
    if Input.isDown("move_left") then dx = dx - speed * dt end
    if Input.isDown("move_right") then dx = dx + speed * dt end
    tryMove(self, dx, dy)
end
