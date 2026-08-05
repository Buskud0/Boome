-- Map builder HUD: quick-access slots and save/revert buttons.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"

local MapBuilderHUD = {}
MapBuilderHUD.__index = MapBuilderHUD

local SLOT_SIZE = Config.MAPBUILDER_HUD_SLOT_SIZE
local SLOT_GAP = Config.MAPBUILDER_HUD_SLOT_GAP
local HUD_BOTTOM_MARGIN = Config.MAPBUILDER_HUD_BOTTOM_MARGIN
local BUTTON_WIDTH = Config.MAPBUILDER_HUD_BUTTON_WIDTH
local BUTTON_HEIGHT = Config.MAPBUILDER_HUD_BUTTON_HEIGHT

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function MapBuilderHUD.new(state)
    local self = setmetatable({}, MapBuilderHUD)
    self.state = state
    return self
end

function MapBuilderHUD:getSlotRects()
    local state = self.state
    local count = state.mapBuilder.QUICK_ACCESS_COUNT
    local totalWidth = count * SLOT_SIZE + (count - 1) * SLOT_GAP
    local startX = math.floor(state.scrWidth / 2 - totalWidth / 2 + state.camera.x)
    local slotY = state.scrHeight - SLOT_SIZE - HUD_BOTTOM_MARGIN + state.camera.y
    local rects = {}
    for i = 1, count do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function MapBuilderHUD:getSaveButtonRect()
    local state = self.state
    return { x = state.scrWidth - BUTTON_WIDTH - 16 + state.camera.x, y = 16 + state.camera.y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT }
end

function MapBuilderHUD:getRevertButtonRect()
    local saveRect = self:getSaveButtonRect()
    return { x = saveRect.x - BUTTON_WIDTH - 8, y = saveRect.y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT }
end

function MapBuilderHUD:isPointerOverHUD(worldX, worldY)
    for _, rect in ipairs(self:getSlotRects()) do
        if isPointInRect(worldX, worldY, rect) then return true end
    end
    if isPointInRect(worldX, worldY, self:getSaveButtonRect()) then return true end
    if isPointInRect(worldX, worldY, self:getRevertButtonRect()) then return true end
    return false
end

function MapBuilderHUD:draw()
    self:drawSlots()
    self:drawRevertButton()
    self:drawSaveButton()
end

function MapBuilderHUD:drawSlots()
    for i, rect in ipairs(self:getSlotRects()) do
        self:drawSlot(rect, i)
    end
end

function MapBuilderHUD:drawSlot(rect, index)
    local mapBuilder = self.state.mapBuilder
    self:drawSlotBackground(rect, index == mapBuilder.selectedSlot)
    self:drawSlotIcon(rect, mapBuilder.quickAccess[index])
    self:drawSlotNumber(rect, index)
end

function MapBuilderHUD:drawSlotBackground(rect, isSelected)
    if isSelected then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    else
        love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    end
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
end

function MapBuilderHUD:drawSlotIcon(rect, slot)
    if slot then
        Textures.draw(slot.material, rect.x + 5, rect.y + 5, rect.w - 10, rect.h - 10)
    end
end

function MapBuilderHUD:drawSlotNumber(rect, index)
    local font = Fonts.get(14)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(index), rect.x + 3, rect.y + 3)
end

function MapBuilderHUD:drawRevertButton()
    local rect = self:getRevertButtonRect()
    local mapBuilder = self.state.mapBuilder
    local canRevert = mapBuilder.hasUnsavedChanges and mapBuilder.hasSavedFile
    self:drawButton(rect, "REVERT", 16, canRevert, {0.6, 0.4, 0.2, 0.9})
end

function MapBuilderHUD:drawSaveButton()
    local rect = self:getSaveButtonRect()
    self:drawButton(rect, "SAVE", 20, self.state.mapBuilder.hasUnsavedChanges, {0.2, 0.6, 0.2, 0.9})
end

function MapBuilderHUD:drawButton(rect, label, fontSize, isActive, activeColor)
    if isActive then
        love.graphics.setColor(activeColor)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    end
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)

    local font = Fonts.get(fontSize)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local labelW = font:getWidth(label)
    love.graphics.print(label, rect.x + rect.w / 2 - labelW / 2, rect.y + 8)
end

return MapBuilderHUD