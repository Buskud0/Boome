local MapBuilderHUD = {}

local SLOT_SIZE = 52
local SLOT_GAP = 8
local SLOT_COUNT = MapBuilder.QUICK_ACCESS_COUNT
local HUD_BOTTOM_MARGIN = 12
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 36

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end

function MapBuilderHUD.getSlotRects()
    local totalWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
    local startX = math.floor(scrWidth / 2 - totalWidth / 2 + camera.x)
    local slotY = scrHeight - SLOT_SIZE - HUD_BOTTOM_MARGIN + camera.y
    local rects = {}
    for i = 1, SLOT_COUNT do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function MapBuilderHUD.getSaveButtonRect()
    return { x = scrWidth - BUTTON_WIDTH - 16 + camera.x, y = 16 + camera.y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT }
end

function MapBuilderHUD.getRevertButtonRect()
    local saveRect = MapBuilderHUD.getSaveButtonRect()
    return { x = saveRect.x - BUTTON_WIDTH - 8, y = saveRect.y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT }
end

function MapBuilderHUD.isPointerOverHUD(worldX, worldY)
    for _, rect in ipairs(MapBuilderHUD.getSlotRects()) do
        if isPointInRect(worldX, worldY, rect) then return true end
    end
    if isPointInRect(worldX, worldY, MapBuilderHUD.getSaveButtonRect()) then return true end
    if isPointInRect(worldX, worldY, MapBuilderHUD.getRevertButtonRect()) then return true end
    return false
end

function MapBuilderHUD.drawSlots()
    for i, rect in ipairs(MapBuilderHUD.getSlotRects()) do
        MapBuilderHUD.drawSlot(rect, i)
    end
end

function MapBuilderHUD.drawSlot(rect, index)
    MapBuilderHUD.drawSlotBackground(rect, index == MapBuilder.selectedSlot)
    MapBuilderHUD.drawSlotIcon(rect, MapBuilder.quickAccess[index])
    MapBuilderHUD.drawSlotNumber(rect, index)
end

function MapBuilderHUD.drawSlotBackground(rect, isSelected)
    if isSelected then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    else
        love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    end
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
end

function MapBuilderHUD.drawSlotIcon(rect, slot)
    if slot then
        Textures.draw(slot.material, rect.x + 5, rect.y + 5, rect.w - 10, rect.h - 10)
    end
end

function MapBuilderHUD.drawSlotNumber(rect, index)
    local font = love.graphics.newFont("fonts/Gamer.ttf", 14)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(index), rect.x + 3, rect.y + 3)
end

function MapBuilderHUD.drawRevertButton()
    local rect = MapBuilderHUD.getRevertButtonRect()
    local canRevert = MapBuilder.hasUnsavedChanges and MapBuilder.hasSavedFile
    MapBuilderHUD.drawButton(rect, "REVERT", 16, canRevert, {0.6, 0.4, 0.2, 0.9})
end

function MapBuilderHUD.drawSaveButton()
    local rect = MapBuilderHUD.getSaveButtonRect()
    MapBuilderHUD.drawButton(rect, "SAVE", 20, MapBuilder.hasUnsavedChanges, {0.2, 0.6, 0.2, 0.9})
end

function MapBuilderHUD.drawButton(rect, label, fontSize, isActive, activeColor)
    if isActive then
        love.graphics.setColor(activeColor)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    end
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)

    local font = love.graphics.newFont("fonts/Gamer.ttf", fontSize)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local labelW = font:getWidth(label)
    love.graphics.print(label, rect.x + rect.w / 2 - labelW / 2, rect.y + 8)
end

function MapBuilderHUD.draw()
    MapBuilderHUD.drawSlots()
    MapBuilderHUD.drawRevertButton()
    MapBuilderHUD.drawSaveButton()
end

return MapBuilderHUD
