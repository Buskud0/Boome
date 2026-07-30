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
    local wantToSprint = Input.isDown("sprint")
    local currentSprinting = wantToSprint and (self.stamina > 0 and self.isSprinting or self.stamina > PLAYER_SPRINT_THRESHOLD)

    local oldX, oldY = self.x, self.y
    self:_handleMovement(dt, currentSprinting)

    local actuallyMoved = self.x ~= oldX or self.y ~= oldY
    local isSprinting = currentSprinting and actuallyMoved
    self:_applyStamina(dt, isSprinting)
    self.isSprinting = isSprinting

    if self.health <= 0 then resetGame() end
end

function Player:_applyStamina(dt, isSprinting)
    if isSprinting then
        self.stamina = math.max(0, self.stamina - PLAYER_SPRINT_DRAIN_RATE * dt)
    else
        self.stamina = math.min(self.maxStamina, self.stamina + PLAYER_STAMINA_RECOVERY_RATE * dt)
    end
end

function Player:_handleMovement(dt, isSprinting)
    local speed = isSprinting and self.speed * PLAYER_SPRINT_MULTIPLIER or self.speed
    local material = grid:getMaterialAt(self.x + self.width / 2, self.y + self.height / 2)
    if material then
        local item = BUILDING_ITEMS[material]
        if item then
            speed = speed * (item.speedMultiplier or 1)
        end
    end

    local dx, dy = 0, 0
    if Input.isDown("move_up") then dy = dy - speed * dt end
    if Input.isDown("move_down") then dy = dy + speed * dt end
    if Input.isDown("move_left") then dx = dx - speed * dt end
    if Input.isDown("move_right") then dx = dx + speed * dt end
    tryMove(self, dx, dy)
end
