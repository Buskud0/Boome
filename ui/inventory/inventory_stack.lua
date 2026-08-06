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

    function Inventory:hasRoomFor(item)
        if self:isStackable(item) then
            for i = 1, self.MAX_SLOTS do
                local slot = self.state.items[i]
                if slot and slot.model == item.model then
                    if slot.count + item.count <= stackSizeOf(item.model) then
                        return true
                    end
                end
            end
        end
        return self:findFirstEmptySlot() ~= nil
    end

    function Inventory:addItem(item)
        if self:isStackable(item) then
            for i = 1, self.MAX_SLOTS do
                local slot = self.state.items[i]
                if slot and slot.model == item.model then
                    if slot.count + item.count <= stackSizeOf(item.model) then
                        slot.count = slot.count + item.count
                        return true
                    end
                end
            end
        end
        local empty = self:findFirstEmptySlot()
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
end
