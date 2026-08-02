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

-- settings (PLAYER_FOV, PERIPHERAL_*, LIGHT_*) are in core/config.lua

function Player:isScoped()
    return weapon ~= nil and weapon:isScoping()
end

function Player:getFov()
    local scoped = self:_getScopedFov()
    local progress = weapon and weapon.scopeProgress or 0
    return PLAYER_FOV + (scoped - PLAYER_FOV) * progress
end

function Player:_getScopedFov()
    local scope = weapon and weapon.scope or 50
    local fov = PLAYER_SCOPED_FOV_BASE - PLAYER_SCOPED_FOV_PER_SCOPE * scope
    return math.max(math.rad(fov), PLAYER_MIN_SCOPED_FOV)
end

function Player:drawLocalLighting()
    love.graphics.push()
    love.graphics.origin()

    love.graphics.stencil(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", self:_getLightConeVertices())
    end, "replace", 1)

    love.graphics.setStencilTest("less", 1)
    love.graphics.setColor(0, 0, 0, PLAYER_LIGHT_DARKNESS)
    love.graphics.rectangle("fill", 0, 0, scrWidth, scrHeight)
    love.graphics.setStencilTest()

    love.graphics.pop()
end

function Player:_getLightConeVertices()
    local px, py = self:getCenter()
    local aimAngle = self:_getAimAngle(px, py)
    local rayAngles = self:_getRayAngles(px, py, aimAngle)
    return self:_castVisionRays(px, py, rayAngles, self:_getVisionRadius())
end

function Player:_getAimAngle(px, py)
    local mx, my = screenToWorld(love.mouse.getPosition())
    local dx, dy = mx - px, my - py
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return -math.pi / 2 end
    local step = self:getFov() / PLAYER_LIGHT_SEGMENTS
    return math.floor(math.atan2(dy, dx) / step + 0.5) * step
end

function Player:_getVisionRadius()
    return math.sqrt(mapWidth * mapWidth + mapHeight * mapHeight)
end

function Player:_getRayAngles(px, py, aimAngle)
    local fov = self:getFov()
    local half = fov / 2
    local step = fov / PLAYER_LIGHT_SEGMENTS
    local minAngle = aimAngle - half
    local maxAngle = aimAngle + half

    local rayAngles = {}
    for i = 0, PLAYER_LIGHT_SEGMENTS do
        rayAngles[#rayAngles + 1] = minAngle + step * i
    end

    local corners = grid:getVisionCornerAngles(px, py, minAngle - PLAYER_LIGHT_CORNER_EPS, maxAngle + PLAYER_LIGHT_CORNER_EPS)
    for i = 1, #corners do
        rayAngles[#rayAngles + 1] = corners[i] - PLAYER_LIGHT_CORNER_EPS
        rayAngles[#rayAngles + 1] = corners[i] + PLAYER_LIGHT_CORNER_EPS
    end

    table.sort(rayAngles)
    return rayAngles
end

function Player:_castVisionRays(px, py, rayAngles, radius)
    local vertices = {}
    local sx, sy = worldToScreen(px, py)
    vertices[#vertices + 1] = sx
    vertices[#vertices + 1] = sy
    for i = 1, #rayAngles do
        local hx, hy = self:_castVisionRay(px, py, rayAngles[i], radius)
        local vx, vy = worldToScreen(hx, hy)
        vertices[#vertices + 1] = vx
        vertices[#vertices + 1] = vy
    end
    return vertices
end

function Player:_castVisionRay(x, y, angle, maxDist)
    local ts = grid.tileSize
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    local maxX = x + dx * maxDist
    local maxY = y + dy * maxDist

    local col = math.floor(x / ts) + 1
    local row = math.floor(y / ts) + 1
    local endCol = math.floor(maxX / ts) + 1
    local endRow = math.floor(maxY / ts) + 1

    local stepX = 0
    if dx > 0 then stepX = 1 elseif dx < 0 then stepX = -1 end
    local stepY = 0
    if dy > 0 then stepY = 1 elseif dy < 0 then stepY = -1 end

    local tDeltaX = stepX ~= 0 and (ts / math.abs(dx)) or math.huge
    local tDeltaY = stepY ~= 0 and (ts / math.abs(dy)) or math.huge

    local tMaxX, tMaxY = math.huge, math.huge
    if stepX == 1 then
        tMaxX = (col * ts - x) / math.abs(dx)
    elseif stepX == -1 then
        tMaxX = (x - (col - 1) * ts) / math.abs(dx)
    end
    if stepY == 1 then
        tMaxY = (row * ts - y) / math.abs(dy)
    elseif stepY == -1 then
        tMaxY = (y - (row - 1) * ts) / math.abs(dy)
    end

    while true do
        if col == endCol and row == endRow then return maxX, maxY end
        local tHit
        if tMaxX < tMaxY - PLAYER_LIGHT_GRID_TIE_BREAK then
            tHit = tMaxX
            tMaxX = tMaxX + tDeltaX
            col = col + stepX
        else
            tHit = tMaxY
            tMaxY = tMaxY + tDeltaY
            row = row + stepY
        end
        if grid:isTileVisionBlocked(col, row) then
            return x + dx * tHit, y + dy * tHit
        end
    end
end

function Player:isInVisionCone(wx, wy)
    local px, py = self:getCenter()
    local dx, dy = wx - px, wy - py
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return true end

    local aimAngle = self:_getAimAngle(px, py)
    local dot = dx * math.cos(aimAngle) + dy * math.sin(aimAngle)
    return dot >= dist * math.cos(self:getFov() / 2)
end

function Player:getVisibilityAlphaFor(wx, wy)
    if self:isInVisionCone(wx, wy) then return 1 end
    local px, py = self:getCenter()
    local dx, dy = wx - px, wy - py
    local distSq = dx * dx + dy * dy
    if distSq <= PLAYER_PERIPHERAL_RADIUS * PLAYER_PERIPHERAL_RADIUS then return PLAYER_PERIPHERAL_ALPHA end
    return 0
end
