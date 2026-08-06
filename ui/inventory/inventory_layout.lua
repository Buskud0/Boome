-- Inventory: slot rect math. Attaches methods to the Inventory factory.

local Config = require "core.config"

local SLOT_SIZE = Config.INVENTORY_SLOT_SIZE
local SLOT_GAP = Config.INVENTORY_SLOT_GAP
local HOTBAR_SLOTS = Config.INVENTORY_HOTBAR_SLOTS
local BACKPACK_SLOTS = Config.INVENTORY_BACKPACK_SLOTS
local BACKPACK_ROW_OFFSET = Config.INVENTORY_BACKPACK_ROW_OFFSET
local CHEST_SLOTS = Config.INVENTORY_CHEST_SLOTS
local PANEL_PADDING = 6
local PANEL_TITLE_HEIGHT = 26

return function(Inventory)
    function Inventory:getBackpackWidth()
        return BACKPACK_SLOTS * SLOT_SIZE + (BACKPACK_SLOTS - 1) * SLOT_GAP
    end

    function Inventory:getPlayerRects()
        local state = self.state
        local totalWidth = self:getBackpackWidth()
        local startX = math.floor(state.scrWidth / 2 - totalWidth / 2 + state.camera.x)
        local rects = {}
        for i = 1, self.MAX_SLOTS do
            local slotX = startX + ((i - 1) % HOTBAR_SLOTS) * (SLOT_SIZE + SLOT_GAP)
            local row = math.floor((i - 1) / HOTBAR_SLOTS)
            local slotY = (state.scrHeight - SLOT_SIZE - 12 + state.camera.y) - row * (SLOT_SIZE + SLOT_GAP)
                - (row > 0 and BACKPACK_ROW_OFFSET or 0)
            rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
        end
        return rects
    end

    function Inventory:getChestRects()
        local rects = {}
        if not self.chest then return rects end
        local startX = self:getPanelStartX()
        local backpackY = self:getPlayerRects()[HOTBAR_SLOTS + 1].y
        local chestY = backpackY - PANEL_TITLE_HEIGHT - PANEL_PADDING - SLOT_SIZE - SLOT_GAP * 2
        for i = 1, CHEST_SLOTS do
            local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
            rects[i] = { x = slotX, y = chestY, w = SLOT_SIZE, h = SLOT_SIZE }
        end
        return rects
    end

    function Inventory:getPanelStartX()
        return math.floor(self.state.scrWidth / 2 - self:getBackpackWidth() / 2 + self.state.camera.x)
    end

    function Inventory:rectHit(rect, worldX, worldY)
        return worldX >= rect.x and worldX <= rect.x + rect.w
            and worldY >= rect.y and worldY <= rect.y + rect.h
    end

    function Inventory:getPanelAt(worldX, worldY)
        for _, panel in ipairs(self:panels()) do
            for i, rect in ipairs(panel.rects()) do
                if self:rectHit(rect, worldX, worldY) then
                    return panel, i
                end
            end
        end
        return nil, nil
    end
end
