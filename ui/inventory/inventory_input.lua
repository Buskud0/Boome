-- Inventory: mouse drag/drop input. Attaches methods to the Inventory factory.

local Config = require "core.config"

local DRAG_THRESHOLD = Config.INVENTORY_DRAG_THRESHOLD

return function(Inventory)
    function Inventory:mousepressed(worldX, worldY, button)
        if button == 2 then
            self:handleRightClick(worldX, worldY)
            return
        end
        if button ~= 1 then return end
        local panel, slot = self:getPanelAt(worldX, worldY)
        if panel and self:getItemAt(panel, slot) then
            self:startDrag(panel, slot, worldX, worldY)
        end
    end

    function Inventory:handleRightClick(worldX, worldY)
        if not self.isOpen then return end
        local panel, slot = self:getPanelAt(worldX, worldY)
        if panel and self:getItemAt(panel, slot) then
            self:dropItemAt(panel, slot)
        end
    end

    function Inventory:startDrag(panel, slot, worldX, worldY)
        self.drag = {
            panel = panel,
            slot = slot,
            startX = worldX,
            startY = worldY,
        }
    end

    function Inventory:clearDrag()
        self.drag = nil
    end

    function Inventory:dragItem()
        return self:getItemAt(self.drag.panel, self.drag.slot)
    end

    function Inventory:isDragClick(worldX, worldY)
        local dx = worldX - self.drag.startX
        local dy = worldY - self.drag.startY
        return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
    end

    function Inventory:mousereleased(worldX, worldY, button)
        if button ~= 1 or not self.drag then return end
        if self:isDragClick(worldX, worldY) then
            self:selectWeaponSlot(self.drag.panel, self.drag.slot)
            return
        end
        self:trySwapWithTarget(worldX, worldY)
    end

    function Inventory:trySwapWithTarget(worldX, worldY)
        local targetPanel, targetIndex = self:getPanelAt(worldX, worldY)
        if targetPanel then
            self:moveItem(self.drag.panel, self.drag.slot, targetPanel, targetIndex)
        end
        self:clearDrag()
    end
end
