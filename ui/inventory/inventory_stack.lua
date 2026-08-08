-- Inventory stacking: generic merge/decrement for stackable items.
-- Stacking is an inventory-layer concern; item objects just carry a `count`.

local Config = require "core.config"

local function stackSizeOf(model)
    local stats = Config.ITEMS[model]
    if stats and stats.stackSize then return stats.stackSize end
    return 1
end

return function(Inventory)
    function Inventory:isStackable(item)
        return item ~= nil and item.isItem == true
    end

    function Inventory:_slotRangeFor(item)
        return 1, self.MAX_SLOTS
    end

    function Inventory:_findMergeSlot(item)
        if not self:isStackable(item) then return nil end
        local first, last = self:_slotRangeFor(item)
        for i = first, last do
            local slot = self.state.items[i]
            if slot and slot.model == item.model and slot.count + item.count <= stackSizeOf(item.model) then
                return i
            end
        end
        return nil
    end

    function Inventory:hasRoomFor(item)
        if self:_findMergeSlot(item) then return true end
        return self:_firstEmptySlotFor(item) ~= nil
    end

    function Inventory:_firstEmptySlotFor(item)
        local first, last = self:_slotRangeFor(item)
        for i = first, last do
            if not self.state.items[i] then
                return i
            end
        end
        return nil
    end

    function Inventory:addItem(item)
        local merge = self:_findMergeSlot(item)
        if merge then
            self.state.items[merge].count = self.state.items[merge].count + item.count
            return true
        end
        local empty = self:_firstEmptySlotFor(item)
        if not empty then return false end
        self:setSlot(empty, item)
        return true
    end

    function Inventory:findItemSlot(model)
        for i = 1, self.MAX_SLOTS do
            local slot = self.state.items[i]
            if slot and slot.model == model and slot.count and slot.count > 0 then
                return i, slot
            end
        end
        return nil
    end

    function Inventory:countModel(model)
        local total = 0
        for i = 1, self.MAX_SLOTS do
            local slot = self.state.items[i]
            if slot and slot.model == model and slot.count then
                total = total + slot.count
            end
        end
        return total
    end

    function Inventory:decrementItemSlot(slot, amount)
        local item = self.state.items[slot]
        if not item or not item.count then return end
        item.count = item.count - amount
        if item.count <= 0 then
            self:setSlot(slot, nil)
            self:keepSelectionValid(slot, slot)
        end
    end

    function Inventory:isEquippable(obj)
        return obj ~= nil
    end

    function Inventory:isSlotEquippable(i)
        return i >= 1 and i <= self.HOTBAR_SLOTS and self:isEquippable(self.state.items[i])
    end

    -- Returns the equipped tool model that can repair this record, or nil.
    function Inventory:repairMaterialFor(record)
        local weapon = self.state.weapon
        if not weapon or not weapon.isItem or not record then return nil end
        local materials = Config.REPAIR_TOOLS[weapon.model]
        if not materials or not materials[record.material] then return nil end
        if record.health >= self.state.grid:_maxHealth(record.material) then return nil end
        return weapon.model
    end

    function Inventory:repairRecord(record)
        local model = self:repairMaterialFor(record)
        if not model then return false end
        local index = self.state.currentWeaponIndex
        local equipped = index and self.state.items[index]
        if not equipped or equipped.model ~= model then return false end
        self:decrementItemSlot(index, 1)
        self.state.grid:repairRecord(record)
        self.state.suppressSwing = true
        return true
    end
end
