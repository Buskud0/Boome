local HUD = {}

local BAR_WIDTH = HUD_BAR_WIDTH
local BAR_HEIGHT = HUD_BAR_HEIGHT
local MONEY_COUNT_RATE = HUD_MONEY_COUNT_RATE

function HUD.reset()
    HUD.displayMoney = 0
end

function HUD.update(dt)
    HUD.animateMoney(dt)
end

function HUD.animateMoney(dt)
    local target = player.money
    local display = HUD.displayMoney
    if display == target then return end

    local diff = target - display
    local step = MONEY_COUNT_RATE * dt
    if math.abs(diff) <= step then
        HUD.displayMoney = target
    else
        HUD.displayMoney = display + step * (diff > 0 and 1 or -1)
    end
end

function HUD.draw()
    HUD.drawHealth()
    HUD.drawStamina()
    HUD.drawStats()
end

function HUD.drawHealth()
    HUD.drawBar(30 + camera.x, scrHeight - 100 + camera.y, player.health / 100, {1, 0.2, 0.2})
end

function HUD.drawStamina()
    HUD.drawBar(30 + camera.x, scrHeight - 85 + camera.y, player.stamina / player.maxStamina, {0, 0.7, 1})
end

function HUD.drawBar(x, y, ratio, fillColor)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", x, y, BAR_WIDTH, BAR_HEIGHT)
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", x, y, BAR_WIDTH * ratio, BAR_HEIGHT)
end

function HUD.drawStats()
    local font = Fonts.get(30)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WAVE: " .. currentRound, 30 + camera.x, scrHeight - 70 + camera.y)
    love.graphics.print("KILL COUNT: " .. killCount, 30 + camera.x, scrHeight - 50 + camera.y)
    love.graphics.print("$" .. math.floor(HUD.displayMoney + 0.5), 30 + camera.x, scrHeight - 30 + camera.y)
end

return HUD
