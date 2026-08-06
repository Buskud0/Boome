-- Map builder HUD: drawing. Attaches methods to the MapBuilderHUD factory.

local Fonts = require "core.fonts"
local Textures = require "core.textures"

return function(MapBuilderHUD)
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
end
