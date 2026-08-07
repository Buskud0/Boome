-- Shared list-menu helpers (selection, wheel, hover, confirm) used by the
-- weapon shop and workshop craft menu factories. Factories must expose:
--   self.sortedItems  -- ordered list of entry models/ids
--   self.selection    -- current index
--   self.lastMouseX/Y, self.useMouseSelection, self.optionRects
-- and implement a confirmSelection() that acts on sortedItems[selection].

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

return function(Menu)
    function Menu:wrapSelection(index)
        if index < 1 then return #self.sortedItems end
        if index > #self.sortedItems then return 1 end
        return index
    end

    function Menu:wheelmoved(direction)
        if direction > 0 then
            self.selection = self:wrapSelection(self.selection - 1)
        elseif direction < 0 then
            self.selection = self:wrapSelection(self.selection + 1)
        end
    end

    function Menu:getMouseSelectionState()
        local camera = self.state.camera
        local mouseX = love.mouse.getX() + camera.x
        local mouseY = love.mouse.getY() + camera.y
        local mouseMoved = mouseX ~= self.lastMouseX or mouseY ~= self.lastMouseY
        if mouseMoved then
            self.lastMouseX = mouseX
            self.lastMouseY = mouseY
        end
        return mouseX, mouseY, mouseMoved
    end

    function Menu:updateHover(rect, mouseX, mouseY, index)
        if self:isPointInRect(mouseX, mouseY, rect) then
            self.selection = index
        end
    end

    function Menu:isPointInRect(x, y, rect)
        return isPointInRect(x, y, rect)
    end

    function Menu:handleAction(action)
        if action == "menu_up" then
            self.useMouseSelection = false
            self.selection = self:wrapSelection(self.selection - 1)
        elseif action == "menu_down" then
            self.useMouseSelection = false
            self.selection = self:wrapSelection(self.selection + 1)
        elseif action == "menu_confirm" then
            self:confirmSelection()
        end
    end
end
