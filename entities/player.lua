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

local PLAYER_FOV = math.rad(100)
local SCOPED_FOV = math.rad(10)
local LIGHT_DARKNESS = 0.05
local LIGHT_SEGMENTS = 32

function Player:isScoped()
    return weapon ~= nil and weapon:isScoping()
end

function Player:getFov()
    if self:isScoped() then return SCOPED_FOV end
    return PLAYER_FOV
end

function Player:drawLocalLighting()
    love.graphics.push()
    love.graphics.origin()

    love.graphics.stencil(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", self:_getLightConeVertices())
    end, "replace", 1)

    love.graphics.setStencilTest("less", 1)
    love.graphics.setColor(0, 0, 0, LIGHT_DARKNESS)
    love.graphics.rectangle("fill", 0, 0, scrWidth, scrHeight)
    love.graphics.setStencilTest()

    love.graphics.pop()
end

function Player:_getLightConeVertices()
    local px, py = self:getCenter()
    local sx, sy = worldToScreen(px, py)
    local mx, my = love.mouse.getPosition()
    local dx, dy = mx - sx, my - sy
    local len = math.sqrt(dx * dx + dy * dy)
    local angle = -math.pi / 2
    if len > 0 then
        angle = math.atan2(dy, dx)
    end

    local radius = math.sqrt(scrWidth * scrWidth + scrHeight * scrHeight)
    local fov = self:getFov()
    local half = fov / 2
    local vertices = { sx, sy }
    for i = 0, LIGHT_SEGMENTS do
        local a = angle - half + fov * (i / LIGHT_SEGMENTS)
        vertices[#vertices + 1] = sx + math.cos(a) * radius
        vertices[#vertices + 1] = sy + math.sin(a) * radius
    end
    return vertices
end

function Player:isInVisionCone(wx, wy)
    local px, py = self:getCenter()
    local mx, my = screenToWorld(love.mouse.getPosition())
    local dx, dy = wx - px, wy - py
    local mdx, mdy = mx - px, my - py
    local dist = math.sqrt(dx * dx + dy * dy)
    local mdist = math.sqrt(mdx * mdx + mdy * mdy)
    if dist == 0 or mdist == 0 then return true end
    local dot = (dx * mdx + dy * mdy) / (dist * mdist)
    return dot >= math.cos(self:getFov() / 2)
end
