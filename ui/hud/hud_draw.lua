-- HUD: rendering. Attaches methods to the HUD factory.

local Config = require "core.config"
local Fonts = require "core.fonts"

local BAR_WIDTH = Config.HUD_BAR_WIDTH
local BAR_HEIGHT = Config.HUD_BAR_HEIGHT

return function(HUD)
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
end
