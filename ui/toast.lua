local Config = require "core.config"
local Fonts = require "core.fonts"

local Toast = {}
Toast.__index = Toast

local SLOT_SIZE = Config.TOAST_SLOT_SIZE
local INVENTORY_OFFSET_Y = Config.TOAST_INVENTORY_OFFSET_Y
local FADE_DURATION = Config.TOAST_FADE_DURATION
local TOAST_BASE_Y = SLOT_SIZE + INVENTORY_OFFSET_Y
local MAX_TOASTS = Config.TOAST_MAX_TOASTS
local TOAST_HEIGHT = Config.TOAST_HEIGHT
local TOAST_GAP = Config.TOAST_GAP

function Toast.new(state)
    local self = setmetatable({}, Toast)
    self.state = state
    self.activeToasts = {}
    return self
end

local function drawToast(self, toast, posY, font)
    local opacity = math.min(1, toast.timer / FADE_DURATION)
    local textWidth = font:getWidth(toast.message)
    local posX = math.floor(self.state.scrWidth / 2 + self.state.camera.x - textWidth / 2)

    love.graphics.setColor(0, 0, 0, 0.6 * opacity)
    love.graphics.rectangle("fill", posX - 8, posY, textWidth + 16, TOAST_HEIGHT)

    love.graphics.setColor(1, 1, 1, opacity)
    love.graphics.print(toast.message, posX, posY + 5)
end

function Toast:show(message, duration)
    if #self.activeToasts >= MAX_TOASTS then
        table.remove(self.activeToasts, 1)
    end
    table.insert(self.activeToasts, {
        message = message,
        timer = duration,
    })
end

function Toast:update(dt)
    for i = #self.activeToasts, 1, -1 do
        local toast = self.activeToasts[i]
        toast.timer = toast.timer - dt
        if toast.timer <= 0 then
            table.remove(self.activeToasts, i)
        end
    end
end

function Toast:draw()
    local font = Fonts.get(20)
    love.graphics.setFont(font)

    local posY = self.state.scrHeight + self.state.camera.y - TOAST_BASE_Y
    for i = #self.activeToasts, 1, -1 do
        posY = posY - TOAST_HEIGHT - TOAST_GAP
        drawToast(self, self.activeToasts[i], posY, font)
    end
end

return Toast
