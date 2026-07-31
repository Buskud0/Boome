Entity = Object:extend()

function Entity.load()
    Textures.load("images/entity_spritesheet.png", 40)
    Textures.define("player", 1)
    Textures.define("zombie_normal", 2)
    Textures.define("zombie_heavy", 3)
    Textures.define("zombie_light", 4)
    Textures.define("bullet", 5)
    Textures.define("powerup_health", 6)
    Textures.define("powerup_money", 7)
end

function Entity:new(x, y)
    self.x = x
    self.y = y
    self.width = 30
    self.height = 30
    self.radius = 15
    self.health = 100
    self.color = {1, 1, 1}
    self.hitSlowTimer = 0
end

function Entity:update(dt)
    if self.hitSlowTimer > 0 then
        self.hitSlowTimer = math.max(0, self.hitSlowTimer - dt)
    end
end

function Entity:takeDamage(amount)
    self.health = self.health - amount
    self.hitSlowTimer = ENTITY_HIT_SLOW_DURATION
end

function Entity:getHitSlowMultiplier()
    if self.hitSlowTimer > 0 then
        return ENTITY_HIT_SLOW_FACTOR
    end
    return 1
end

function Entity:getCenter()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Entity:getSpeedMultiplier()
    local cx, cy = self:getCenter()
    local material = grid:getMaterialAt(cx, cy)
    if material then
        local item = BUILDING_ITEMS[material]
        if item and item.speedMultiplier then
            return item.speedMultiplier
        end
    end
    return 1
end

function Entity:draw()
    self:drawBody()
    if Debug.isEnabled() then self:drawHitbox() end
end

function Entity:drawBody()
    if self.sprite then
        Textures.draw(self.sprite, self.x, self.y, self.width, self.height)
    else
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
end

function Entity:drawHitbox()
    local cx, cy = self:getCenter()
    love.graphics.setColor(1, 0, 1, 0.5)
    love.graphics.circle("line", cx, cy, self.radius)
    love.graphics.setColor(1, 1, 0, 0.3)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.circle("fill", cx, cy, 2)
end
