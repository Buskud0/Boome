-- HUD: core state and lifecycle. Draw behavior is attached by the mixin
-- required at the bottom of this file.

local Config = require "core.config"

local MONEY_COUNT_RATE = Config.HUD_MONEY_COUNT_RATE

local HUD = {}
HUD.__index = HUD

function HUD.new(state)
    local self = setmetatable({}, HUD)
    self.state = state
    self.displayMoney = 0
    return self
end

function HUD:reset()
    self.displayMoney = 0
end

function HUD:update(dt)
    self:animateMoney(dt)
end

function HUD:animateMoney(dt)
    local target = self.state.player.money
    local display = self.displayMoney
    if display == target then return end

    local diff = target - display
    local step = MONEY_COUNT_RATE * dt
    if math.abs(diff) <= step then
        self.displayMoney = target
    else
        self.displayMoney = display + step * (diff > 0 and 1 or -1)
    end
end

require("ui.hud.hud_draw")(HUD)

return HUD
