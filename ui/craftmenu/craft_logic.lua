-- Workshop crafting: recipe queries, material handling and direct crafting.
-- Attaches methods to the CraftMenu factory. Selection/wheel/hover helpers
-- come from the shared ui.menu_common mixin.

local Config = require "core.config"
local Item = require "core.item"

return function(CraftMenu)
    function CraftMenu:getRecipesSorted()
        local all = {}
        for model, _ in pairs(Config.CRAFT_RECIPES) do
            table.insert(all, model)
        end
        table.sort(all)
        return all
    end

    function CraftMenu:materialsFor(model)
        local recipe = Config.CRAFT_RECIPES[model]
        return recipe and recipe.materials or {}
    end

    function CraftMenu:hasMaterials(model)
        local inventory = self.state.inventory
        for _, mat in ipairs(self:materialsFor(model)) do
            if inventory:countModel(mat[1]) < mat[2] then return false end
        end
        return true
    end

    function CraftMenu:consumeMaterials(model)
        local inventory = self.state.inventory
        for _, mat in ipairs(self:materialsFor(model)) do
            local slot = inventory:findItemSlot(mat[1])
            if slot then inventory:decrementItemSlot(slot, mat[2]) end
        end
    end

    function CraftMenu:refundMaterials(model)
        local inventory = self.state.inventory
        for _, mat in ipairs(self:materialsFor(model)) do
            inventory:addItem(Item.new(mat[1], mat[2]))
        end
    end

    function CraftMenu:craft(model)
        if not self:hasMaterials(model) then
            self.state.toast:show("Not enough materials!", 1.5)
            return
        end
        self:consumeMaterials(model)
        if not self.state.inventory:addItem(Item.new(model, 1)) then
            self:refundMaterials(model)
            self.state.toast:show("Inventory full!", 2)
        end
    end

    function CraftMenu:confirmSelection()
        local model = self.sortedItems[self.selection]
        if model then self:craft(model) end
    end

    function CraftMenu:mousepressed(worldX, worldY)
        for i, rect in ipairs(self.optionRects) do
            if self:isPointInRect(worldX, worldY, rect) then
                self.selection = i
                self:craft(self.sortedItems[i])
                return true
            end
        end
        return false
    end
end
