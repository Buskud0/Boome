local MapBuilderHUD = {}

local SLOT_SIZE = 52
local SLOT_GAP = 8
local SLOT_COUNT = MapBuilder.QUICK_ACCESS_COUNT
local HUD_BOTTOM_MARGIN = 12
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 36

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
    local slotRects = MapBuilderHUD.getSlotRects()
    for _, rect in ipairs(slotRects) do
        if worldX >= rect.x and worldX <= rect.x + rect.w and
           worldY >= rect.y and worldY <= rect.y + rect.h then return true end
    end
    local saveRect = MapBuilderHUD.getSaveButtonRect()
    if worldX >= saveRect.x and worldX <= saveRect.x + saveRect.w and
       worldY >= saveRect.y and worldY <= saveRect.y + saveRect.h then return true end
    local revertRect = MapBuilderHUD.getRevertButtonRect()
    if worldX >= revertRect.x and worldX <= revertRect.x + revertRect.w and
       worldY >= revertRect.y and worldY <= revertRect.y + revertRect.h then return true end
    return false
end

function MapBuilderHUD.drawSlots()
    local rects = MapBuilderHUD.getSlotRects()
    for i, rect in ipairs(rects) do
        local slot = MapBuilder.quickAccess[i]
        local isSelected = i == MapBuilder.selectedSlot

        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
        else
            love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
        end
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)

        if slot then
            Textures.draw(slot.material, rect.x + 5, rect.y + 5, rect.w - 10, rect.h - 10)
        end

        local font = love.graphics.newFont("fonts/Gamer.ttf", 14)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(i), rect.x + 3, rect.y + 3)
    end
end

function MapBuilderHUD.drawRevertButton()
    local revertRect = MapBuilderHUD.getRevertButtonRect()
    local canRevert = MapBuilder.hasUnsavedChanges and MapBuilder.hasSavedFile

    if canRevert then
        love.graphics.setColor(0.6, 0.4, 0.2, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    end
    love.graphics.rectangle("fill", revertRect.x, revertRect.y, revertRect.w, revertRect.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", revertRect.x, revertRect.y, revertRect.w, revertRect.h)

    local font = love.graphics.newFont("fonts/Gamer.ttf", 16)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local revertLabel = "REVERT"
    local revertW = font:getWidth(revertLabel)
    love.graphics.print(revertLabel, revertRect.x + revertRect.w / 2 - revertW / 2, revertRect.y + 10)
end

function MapBuilderHUD.drawSaveButton()
    local saveRect = MapBuilderHUD.getSaveButtonRect()

    if MapBuilder.hasUnsavedChanges then
        love.graphics.setColor(0.2, 0.6, 0.2, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    end
    love.graphics.rectangle("fill", saveRect.x, saveRect.y, saveRect.w, saveRect.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", saveRect.x, saveRect.y, saveRect.w, saveRect.h)

    local font = love.graphics.newFont("fonts/Gamer.ttf", 20)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local label = "SAVE"
    local labelW = font:getWidth(label)
    love.graphics.print(label, saveRect.x + saveRect.w / 2 - labelW / 2, saveRect.y + 8)
end

function MapBuilderHUD.draw()
    MapBuilderHUD.drawSlots()
    MapBuilderHUD.drawRevertButton()
    MapBuilderHUD.drawSaveButton()
end

return MapBuilderHUD
