local Toast = {}

local SLOT_SIZE = 52
local INVENTORY_OFFSET_Y = 12
local FADE_DURATION = 0.5
local TOAST_HEIGHT = 30
local TOAST_GAP = 8
local TOAST_BASE_Y = SLOT_SIZE + INVENTORY_OFFSET_Y
local MAX_TOASTS = 3

local activeToasts = {}

local function drawToast(toast, posY, font)
    local opacity = math.min(1, toast.timer / FADE_DURATION)
    local textWidth = font:getWidth(toast.message)
    local posX = math.floor(scrWidth / 2 + camera.x - textWidth / 2)

    love.graphics.setColor(0, 0, 0, 0.6 * opacity)
    love.graphics.rectangle("fill", posX - 8, posY, textWidth + 16, TOAST_HEIGHT)

    love.graphics.setColor(1, 1, 1, opacity)
    love.graphics.print(toast.message, posX, posY + 5)
end

function Toast.show(message, duration)
    if #activeToasts >= MAX_TOASTS then
        table.remove(activeToasts, 1)
    end
    table.insert(activeToasts, {
        message = message,
        timer = duration,
    })
end

function Toast.update(dt)
    for i = #activeToasts, 1, -1 do
        local toast = activeToasts[i]
        toast.timer = toast.timer - dt
        if toast.timer <= 0 then
            table.remove(activeToasts, i)
        end
    end
end

function Toast.draw()
    local font = Fonts.get(20)
    love.graphics.setFont(font)

    local posY = scrHeight + camera.y - TOAST_BASE_Y
    for i = #activeToasts, 1, -1 do
        posY = posY - TOAST_HEIGHT - TOAST_GAP
        drawToast(activeToasts[i], posY, font)
    end
end

return Toast
