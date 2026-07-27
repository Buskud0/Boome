Player = Entity:extend()

function Player:new(x, y)
    Player.super.new(self, x, y)
    self.speed = PLAYER_SPEED
    self.color = {0, 1, 0}
    self.money = 0
    self.maxStamina = PLAYER_MAX_STAMINA
    self.stamina = self.maxStamina
    self.isSprinting = false
    self.sprite = "player"
end

function Player:takeDamage(amount)
    self.health = self.health - amount
    table.insert(damageTexts, DamageText(-amount, self.x, self.y, 1, {1, 0, 0}))
end

function Player:update(dt)
    local isSprinting = self:_updateStamina(dt)
    local speed = isSprinting and self.speed * PLAYER_SPRINT_MULTIPLIER or self.speed

    local dx, dy = 0, 0
    if Input.isDown("move_up") then dy = dy - speed * dt end
    if Input.isDown("move_down") then dy = dy + speed * dt end
    if Input.isDown("move_left") then dx = dx - speed * dt end
    if Input.isDown("move_right") then dx = dx + speed * dt end
    tryMove(self, dx, dy)
    if self.health <= 0 then resetGame() end
end

function Player:_updateStamina(dt)
    local wantToSprint = Input.isDown("sprint")
    local canKeepSprinting = self.stamina > 0 and self.isSprinting
    local canStartSprinting = self.stamina > PLAYER_SPRINT_THRESHOLD
    local isSprinting = wantToSprint and (canKeepSprinting or canStartSprinting)

    if isSprinting then
        self.stamina = math.max(0, self.stamina - PLAYER_SPRINT_DRAIN_RATE * dt)
    else
        self.stamina = math.min(self.maxStamina, self.stamina + PLAYER_STAMINA_RECOVERY_RATE * dt)
    end

    self.isSprinting = isSprinting
    return isSprinting
end
