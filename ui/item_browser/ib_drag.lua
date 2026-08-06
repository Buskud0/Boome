-- Item browser: mouse drag, auto-place and drop. Attaches methods to the
-- ItemBrowser factory.

local Config = require "core.config"

local PANEL_WIDTH = Config.ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = Config.ITEM_BROWSER_PANEL_HEIGHT
local ITEM_CELL_SIZE = Config.ITEM_BROWSER_ITEM_CELL_SIZE
local DRAG_THRESHOLD = Config.ITEM_BROWSER_DRAG_THRESHOLD

local function isPointInRect(x, y, rectX, rectY, w, h)
    return x >= rectX and x <= rectX + w and y >= rectY and y <= rectY + h
end

return function(ItemBrowser)
    function ItemBrowser:handleOutsideClick(px, py, worldX, worldY)
        if isPointInRect(worldX, worldY, px, py, PANEL_WIDTH, PANEL_HEIGHT) then return false end
        self:close()
        return true
    end

    function ItemBrowser:handleSearchClick(px, py, worldX, worldY)
        if isPointInRect(worldX, worldY, px + 10, py + 36, PANEL_WIDTH - 20, 24) then
            self.searchFocused = true
            return true
        end
        return false
    end

    function ItemBrowser:handleGridClick(px, py, worldX, worldY)
        local found = false
        self:forEachItemCell(px, py, function(item, cellX, cellY)
            if not found and isPointInRect(worldX, worldY, cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE) then
                self.draggedItem = item
                self.dragStartX = worldX
                self.dragStartY = worldY
                found = true
            end
        end)
        return found
    end

    function ItemBrowser:handleFilterClick(px, py, worldX, worldY)
        for _, rect in ipairs(self:filterRects(px, py)) do
            if isPointInRect(worldX, worldY, rect.x, rect.y, rect.w, rect.h) then
                self:setFilter(rect.id)
                return true
            end
        end
        return false
    end

    function ItemBrowser:mousepressed(worldX, worldY)
        if not self.isOpen then return end

        local px, py = self:getPanelPosition()

        if self:handleOutsideClick(px, py, worldX, worldY) then return end
        if self:handleFilterClick(px, py, worldX, worldY) then return end
        if self:handleSearchClick(px, py, worldX, worldY) then return end

        self.searchFocused = false
        self:handleGridClick(px, py, worldX, worldY)
    end

    function ItemBrowser:autoPlaceItem(item)
        local mapBuilder = self.state.mapBuilder
        for i = 1, mapBuilder.QUICK_ACCESS_COUNT do
            if not mapBuilder.quickAccess[i] then
                mapBuilder:setQuickAccess(i, item.key)
                return true
            end
        end
        return false
    end

    function ItemBrowser:dropOnSlot(worldX, worldY, item)
        for i, rect in ipairs(self.state.mapBuilderHUD:getSlotRects()) do
            if isPointInRect(worldX, worldY, rect.x, rect.y, rect.w, rect.h) then
                self.state.mapBuilder:setQuickAccess(i, item.key)
                return true
            end
        end
        return false
    end

    function ItemBrowser:mousereleased(worldX, worldY)
        if not self.draggedItem then return end

        local item = self.draggedItem
        self.draggedItem = nil

        if self:wasDragClick(worldX, worldY) then
            self:autoPlaceItem(item)
            return
        end

        self:dropOnSlot(worldX, worldY, item)
    end

    function ItemBrowser:wasDragClick(worldX, worldY)
        local dx = worldX - self.dragStartX
        local dy = worldY - self.dragStartY
        return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
    end
end
