-- Inventory: rendering. Attaches methods to the Inventory factory.

local Fonts = require "core.fonts"
local Textures = require "core.textures"

local SLOT_SIZE = require("core.config").INVENTORY_SLOT_SIZE
local BACKPACK_TITLE_SIZE = require("core.config").INVENTORY_BACKPACK_TITLE_SIZE
local PANEL_PADDING = 6
local PANEL_TITLE_HEIGHT = 26

return function(Inventory)
    function Inventory:draw()
        self:refreshChest()
        self:drawGrenadeIndicator()
        for _, panel in ipairs(self:panels()) do
            self:drawPanelFrame(panel)
            self:drawPanelSlots(panel)
        end
        self:drawHeldItemName()
        self:drawDragGhost()
    end

    function Inventory:drawGrenadeIndicator()
        local rect = self:getPlayerRects()[1]
        if not rect then return end
        local size = 34
        local gap = 18
        local x = rect.x - gap - size
        local y = rect.y + (SLOT_SIZE - size) / 2
        local count = self:countModel("GRENADE")
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2)
        Textures.draw("slot_GRENADE", x, y, size, size)
        self:drawCountBadge(x, y, count, size, 2)
    end

    function Inventory:drawPanelFrame(panel)
        if not panel.showTitle() then return end
        local rects = panel.rects()
        local frame = rects[panel.frameIndex]
        if not frame then return end
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill",
            frame.x - PANEL_PADDING, frame.y - PANEL_TITLE_HEIGHT - PANEL_PADDING,
            panel.width() + PANEL_PADDING * 2,
            PANEL_TITLE_HEIGHT + SLOT_SIZE + PANEL_PADDING * 2)
        self:drawCenteredText(panel.title,
            frame.x + panel.width() / 2,
            frame.y - PANEL_TITLE_HEIGHT + 4, BACKPACK_TITLE_SIZE, {0.9, 0.9, 0.9})
    end

    function Inventory:drawPanelSlots(panel)
        local rects = panel.rects()
        for i = 1, panel.count do
            local rect = rects[i]
            local item = panel.get(i)
            local showIndex = panel.showIndex(i)
            if item then
                self:drawSlot(rect.x, rect.y, item,
                    self:isActiveSlot(panel, i), i, showIndex)
            else
                self:drawEmptySlot(rect.x, rect.y, i, showIndex)
            end
        end
    end

    function Inventory:isActiveSlot(panel, slot)
        return self:isPlayerPanel(panel) and slot == self.state.currentWeaponIndex
    end

    function Inventory:drawHeldItemName()
        local state = self.state
        local weapon = state.items[state.currentWeaponIndex]
        local rects = self:getPlayerRects()
        local label = weapon and weapon.model or "FISTS"
        local rect = weapon and rects[state.currentWeaponIndex] or rects[1]
        if not rect then return end
        local centerX = self:getPanelStartX() + self:getBackpackWidth() / 2
        self:drawCenteredText(label, centerX, rect.y - 18, 18, {1, 1, 1})
    end

    function Inventory:drawDragGhost()
        if not self.drag then return end
        local mx, my = love.mouse.getPosition()
        local weapon = self:dragItem()
        if not weapon then return end
        local camera = self.state.camera
        Textures.draw("slot_" .. weapon.model, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
    end

    function Inventory:drawSlot(x, y, weapon, isActive, index, showIndex)
        self:drawSlotFrame(x, y, isActive)
        self:drawSlotIcon(x, y, weapon.model)
        if showIndex then
            self:drawSlotIndex(x, y, index, {1, 1, 1})
        end
        if weapon.count and weapon.count > 1 then
            self:drawCountBadge(x, y, weapon.count)
        end
        if weapon.magSize then
            self:drawAmmo(x, y, weapon)
        end
    end

    function Inventory:drawCountBadge(x, y, count, size, offset)
        size = size or SLOT_SIZE
        offset = offset or 2
        local font = Fonts.get(16)
        local text = "x" .. count
        local textW = font:getWidth(text)
        local badgeW = textW + 8
        local badgeH = 16
        local bx = x + size - badgeW - offset
        local by = y + size - badgeH - offset

        love.graphics.setFont(font)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", bx, by, badgeW, badgeH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, bx + 4, by + (badgeH - font:getHeight()) / 2)
    end

    function Inventory:drawEmptySlot(x, y, index, showIndex)
        love.graphics.setColor(0.08, 0.08, 0.08, 0.6)
        love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)
        if showIndex then
            self:drawSlotIndex(x, y, index, {0.3, 0.3, 0.3})
        end
    end

    function Inventory:drawSlotFrame(x, y, isActive)
        if isActive then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
        else
            love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
        end
        love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)
    end

    function Inventory:drawSlotIcon(x, y, model)
        local padding = 5
        Textures.draw("slot_" .. model, x + padding, y + padding, SLOT_SIZE - padding * 2, SLOT_SIZE - padding * 2)
    end

    function Inventory:drawSlotIndex(x, y, index, color)
        local font = Fonts.get(16)
        love.graphics.setFont(font)
        love.graphics.setColor(color)
        love.graphics.print(tostring(index), x + 3, y + 2)
    end

    function Inventory:drawAmmo(x, y, weapon)
        local ammo = weapon.capacity .. "/" .. weapon.magSize
        local font = Fonts.get(16)
        love.graphics.setFont(font)
        local textW = font:getWidth(ammo)
        local barY = y + SLOT_SIZE - 16

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", x + 2, barY, SLOT_SIZE - 4, 16)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(ammo, x + SLOT_SIZE / 2 - textW / 2, barY + (16 - font:getHeight()) / 2)
    end

    function Inventory:drawCenteredText(text, centerX, y, size, color)
        local font = Fonts.get(size)
        love.graphics.setFont(font)
        local textW = font:getWidth(text)
        love.graphics.setColor(color)
        love.graphics.print(text, centerX - textW / 2, y)
    end
end
