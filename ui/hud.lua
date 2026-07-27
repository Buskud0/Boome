local HUD = {}

function HUD.draw()
    HUD.drawHealth()
    HUD.drawStamina()
    HUD.drawStats()
end

function HUD.drawHealth()
    local barWidth = 100
    local barHeight = 8
    local barX = 30 + camera.x
    local barY = scrHeight - 100 + camera.y
    local healthRatio = player.health / 100

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthRatio, barHeight)
end

function HUD.drawStamina()
    local barWidth = 100
    local barHeight = 8
    local barX = 30 + camera.x
    local barY = scrHeight - 85 + camera.y
    local staminaRatio = player.stamina / player.maxStamina

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    love.graphics.setColor(0, 0.7, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * staminaRatio, barHeight)
end

function HUD.drawStats()
    local font = love.graphics.newFont("fonts/Gamer.ttf", 30)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WAVE: " .. currentRound, 30 + camera.x, scrHeight - 70 + camera.y)
    love.graphics.print("KILL COUNT: " .. killCount, 30 + camera.x, scrHeight - 50 + camera.y)
    love.graphics.print("$" .. player.money, 30 + camera.x, scrHeight - 30 + camera.y)
end

return HUD
