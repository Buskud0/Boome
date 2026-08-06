-- Short-lived expanding explosion flash. Spawned by the Explosion system.
-- Lives in state.explosions; the horde loop updates and draws it.

local Object = require "lib.classic"

local ExplosionEffect = Object:extend()

local DURATION = 0.4

function ExplosionEffect:new(state, x, y, radius)
    self.state = state
    self.x = x
    self.y = y
    self.radius = radius
    self.timer = DURATION
    self.destruct = false
end

function ExplosionEffect:update(dt)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.destruct = true
    end
end

function ExplosionEffect:draw()
    local progress = 1 - self.timer / DURATION
    local eased = 1 - (1 - progress) * (1 - progress)
    local radius = self.radius * eased
    local alpha = math.max(0, 1 - progress)

    love.graphics.setColor(1, 0.9, 0.5, alpha * 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", self.x, self.y, radius)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 0.6, 0.2, alpha * 0.4)
    love.graphics.circle("fill", self.x, self.y, radius * 0.7)

    love.graphics.setColor(1, 1, 0.8, alpha * 0.6)
    love.graphics.circle("fill", self.x, self.y, radius * 0.25)
end

return ExplosionEffect
