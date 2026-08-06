local Object = require "lib.classic"
local Config = require "core.config"
local Textures = require "core.textures"
local Debug = require "core.debug"

local Entity = Object:extend()

local HIT_SLOW_DURATION = Config.ENTITY_HIT_SLOW_DURATION
local HIT_SLOW_FACTOR = Config.ENTITY_HIT_SLOW_FACTOR

function Entity.load()
    Textures.load("images/entity_spritesheet.png", 40)
    Textures.define("player", 1)
    Textures.define("zombie_rotter", 2)
    Textures.define("zombie_lastBreath", 3)
    Textures.define("zombie_runner", 4)
    Textures.define("bullet", 5)
    Textures.define("powerup_health", 6)
    Textures.define("powerup_money", 7)
    Textures.define("zombie_spidor", 8)
end

function Entity:new(state, x, y)
    self.state = state
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
    self.hitSlowTimer = HIT_SLOW_DURATION
end

function Entity:getHitSlowMultiplier()
    if self.hitSlowTimer > 0 then
        return HIT_SLOW_FACTOR
    end
    return 1
end

function Entity:getCenter()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Entity:getSpeedMultiplier()
    local cx, cy = self:getCenter()
    local material = self.state.grid:getMaterialAt(cx, cy)
    if material then
        local item = Config.BUILDING_ITEMS[material]
        if item and item.speedMultiplier then
            return item.speedMultiplier
        end
    end
    return 1
end

function Entity:isOccludedFrom(ox, oy)
    local cx, cy = self:getCenter()
    return self.state.grid:segmentBlocksVision(ox, oy, cx, cy)
end

function Entity:draw(alpha)
    self:drawBody(alpha)
    if Debug.isEnabled() then self:drawHitbox() end
end

function Entity:drawBody(alpha)
    local player = self.state.player
    if self ~= player and self:isOccludedFrom(player:getCenter()) then return end
    if self.sprite then
        Textures.draw(self.sprite, self.x, self.y, self.width, self.height, alpha)
    else
        local c = self.color
        love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
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

return Entity
