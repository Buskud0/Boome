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

    function Inventory:stackSizeOf(model)
        return stackSizeOf(model)
    end

    function Inventory:isBackpackOnly(item)
        return self:isStackable(item)
    end

    function Inventory:_slotRangeFor(item)
        if self:isBackpackOnly(item) then
            return self.HOTBAR_SLOTS + 1, self.MAX_SLOTS
        end
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
        return obj ~= nil and obj.isItem ~= true
    end

    function Inventory:isSlotEquippable(i)
        return i >= 1 and i <= self.HOTBAR_SLOTS and self:isEquippable(self.state.items[i])
    end
end
