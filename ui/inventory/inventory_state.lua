-- Inventory: panels, container operations and selection. Attaches methods
-- to the Inventory factory.

local Config = require "core.config"
local WeaponPickup = require "entities.weapon_pickup"

local HOTBAR_SLOTS = Config.INVENTORY_HOTBAR_SLOTS
local SLOT_SIZE = Config.INVENTORY_SLOT_SIZE
local SLOT_GAP = Config.INVENTORY_SLOT_GAP
local BACKPACK_TITLE = Config.INVENTORY_BACKPACK_TITLE
local CHEST_SLOTS = Config.INVENTORY_CHEST_SLOTS
local CHEST_TITLE = Config.INVENTORY_CHEST_TITLE

return function(Inventory)
    function Inventory:findFirstEmptySlot()
        for i = 1, self.MAX_SLOTS do
            if not self.state.items[i] then
                return i
            end
        end
        return nil
    end

    function Inventory:setSlot(slot, item)
        self.state.items[slot] = item
    end

    function Inventory:playerPanel()
        return {
            id = "player",
            count = self.isOpen and self.MAX_SLOTS or HOTBAR_SLOTS,
            frameIndex = HOTBAR_SLOTS + 1,
            width = function() return self:getBackpackWidth() end,
            rects = function() return self:getPlayerRects() end,
            title = BACKPACK_TITLE,
            showTitle = function() return self.isOpen end,
            showIndex = function(i) return i <= HOTBAR_SLOTS end,
            get = function(i) return self.state.items[i] end,
            set = function(i, item) self.state.items[i] = item end,
        }
    end

    function Inventory:chestPanel()
        if not self.chest then return nil end
        return {
            id = "chest",
            count = CHEST_SLOTS,
            frameIndex = 1,
            width = function()
                return CHEST_SLOTS * SLOT_SIZE + (CHEST_SLOTS - 1) * SLOT_GAP
            end,
            rects = function() return self:getChestRects() end,
            title = CHEST_TITLE,
            showTitle = function() return true end,
            showIndex = function() return false end,
            get = function(i) return self.chest.container:get(i) end,
            set = function(i, item) self.chest.container:set(i, item) end,
        }
    end

    function Inventory:panels()
        local panels = { self:playerPanel() }
        local chest = self:chestPanel()
        if chest then panels[#panels + 1] = chest end
        return panels
    end

    function Inventory:isPlayerPanel(panel)
        return panel and panel.id == "player"
    end

    function Inventory:getItemAt(panel, slot)
        return panel.get(slot)
    end

    function Inventory:setItemAt(panel, slot, item)
        panel.set(slot, item)
    end

    function Inventory:moveItem(srcPanel, srcSlot, dstPanel, dstSlot)
        local srcItem = self:getItemAt(srcPanel, srcSlot)
        if self:isPlayerPanel(dstPanel) and dstSlot <= HOTBAR_SLOTS and self:isBackpackOnly(srcItem) then
            return
        end
        if self:isPlayerPanel(srcPanel) and srcSlot <= HOTBAR_SLOTS then
            local dstItem = self:getItemAt(dstPanel, dstSlot)
            if self:isBackpackOnly(dstItem) then
                return
            end
        end
        local temp = self:getItemAt(srcPanel, srcSlot)
        self:setItemAt(srcPanel, srcSlot, self:getItemAt(dstPanel, dstSlot))
        self:setItemAt(dstPanel, dstSlot, temp)
        local touchesPlayer = self:isPlayerPanel(srcPanel) or self:isPlayerPanel(dstPanel)
        if touchesPlayer then
            local srcIndex = self:isPlayerPanel(srcPanel) and srcSlot or nil
            local dstIndex = self:isPlayerPanel(dstPanel) and dstSlot or nil
            self:keepSelectionValid(srcIndex, dstIndex)
        end
    end

    function Inventory:dropItemAt(panel, slot)
        local item = self:getItemAt(panel, slot)
        if not item then return end
        self:setItemAt(panel, slot, nil)
        if self:isPlayerPanel(panel) then
            self:keepSelectionValid(slot, slot)
        end
        local cx, cy = self.state.player:getCenter()
        table.insert(self.state.weaponPickups, WeaponPickup(self.state, cx, cy, item))
    end

    function Inventory:dropHeldWeapon()
        if not self.state.currentWeaponIndex or not self.state.items[self.state.currentWeaponIndex] then return end
        self:dropItemAt(self:playerPanel(), self.state.currentWeaponIndex)
        self.state.currentWeaponIndex = nil
    end

    function Inventory:selectWeaponSlot(panel, slot)
        if self:isPlayerPanel(panel) and slot <= HOTBAR_SLOTS then
            self:toggleWeaponSelection(slot)
        end
        self:clearDrag()
    end

    function Inventory:toggleWeaponSelection(slot)
        if self.state.currentWeaponIndex == slot then
            self.state.currentWeaponIndex = nil
        elseif self:isEquippable(self.state.items[slot]) then
            self.state.currentWeaponIndex = slot
        else
            self.state.currentWeaponIndex = nil
        end
    end

    function Inventory:keepSelectionValid(sourceIndex, targetIndex)
        local weapons = self.state.items
        if targetIndex and targetIndex <= HOTBAR_SLOTS and self:isEquippable(weapons[targetIndex]) then
            self.state.currentWeaponIndex = targetIndex
            return
        end
        if sourceIndex and sourceIndex <= HOTBAR_SLOTS and self:isEquippable(weapons[sourceIndex]) then
            self.state.currentWeaponIndex = sourceIndex
            return
        end
        for i = 1, HOTBAR_SLOTS do
            if self:isEquippable(weapons[i]) then
                self.state.currentWeaponIndex = i
                return
            end
        end
        self.state.currentWeaponIndex = nil
    end
end
