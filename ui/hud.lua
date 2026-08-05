local Config = require "core.config"
local Fonts = require "core.fonts"

local HUD = {}
HUD.__index = HUD

local BAR_WIDTH = Config.HUD_BAR_WIDTH
local BAR_HEIGHT = Config.HUD_BAR_HEIGHT
local MONEY_COUNT_RATE = Config.HUD_MONEY_COUNT_RATE

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

function HUD:draw()
    self:drawHealth()
    self:drawStamina()
    self:drawStats()
end

function HUD:drawHealth()
    self:drawBar(30 + self.state.camera.x, self.state.scrHeight - 100 + self.state.camera.y, self.state.player.health / 100, {1, 0.2, 0.2})
end

function HUD:drawStamina()
    local player = self.state.player
    self:drawBar(30 + self.state.camera.x, self.state.scrHeight - 85 + self.state.camera.y, player.stamina / player.maxStamina, {0, 0.7, 1})
end

function HUD:drawBar(x, y, ratio, fillColor)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", x, y, BAR_WIDTH, BAR_HEIGHT)
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", x, y, BAR_WIDTH * ratio, BAR_HEIGHT)
end

function HUD:drawStats()
    local font = Fonts.get(30)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WAVE: " .. self.state.currentRound, 30 + self.state.camera.x, self.state.scrHeight - 70 + self.state.camera.y)
    love.graphics.print("KILL COUNT: " .. self.state.killCount, 30 + self.state.camera.x, self.state.scrHeight - 50 + self.state.camera.y)
    love.graphics.print("$" .. math.floor(self.displayMoney + 0.5), 30 + self.state.camera.x, self.state.scrHeight - 30 + self.state.camera.y)
end

return HUD
