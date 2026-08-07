-- Weapon shop: purchase and input logic. Attaches methods to the BuyMenu factory.
-- Selection/wheel/hover helpers come from the shared ui.menu_common mixin.

local Config = require "core.config"
local WeaponDefs = require "systems.weapon.weapon_defs"
local Item = require "core.item"

local function priceOf(model)
    local item = Config.ITEMS[model]
    if item then return item.price end
    return Config.WEAPONS[model].price
end

local function isItemModel(model)
    return Config.ITEMS[model] ~= nil
end

return function(BuyMenu)
    function BuyMenu:isItemModel(model)
        return isItemModel(model)
    end

    function BuyMenu:priceOf(model)
        return priceOf(model)
    end

    function BuyMenu:getWeaponsSortedByPrice()
        local all = {}
        for model, stats in pairs(Config.WEAPONS) do
            if not stats.hidden then
                table.insert(all, model)
            end
        end
        for model, stats in pairs(Config.ITEMS) do
            if not stats.hidden then
                table.insert(all, model)
            end
        end
        table.sort(all, function(a, b)
            return priceOf(a) < priceOf(b)
        end)
        return all
    end

    function BuyMenu:playerHasWeapon(model)
        for i = 1, self.state.inventory.MAX_SLOTS do
            local weapon = self.state.items[i]
            if weapon and weapon.model == model then return true end
        end
        return false
    end

    function BuyMenu:isOwned(model)
        return not self:isItemModel(model) and self:playerHasWeapon(model)
    end

    function BuyMenu:canAffordWeapon(model)
        return self.state.player.money >= priceOf(model)
    end

    function BuyMenu:buyWeapon(model)
        self.state.player.money = self.state.player.money - Config.WEAPONS[model].price
        local slot = self.state.inventory:findFirstEmptySlot()
        if not slot then return end
        self.state.items[slot] = WeaponDefs.create(self.state, model)
        if slot <= self.state.inventory.HOTBAR_SLOTS then
            self.state.currentWeaponIndex = slot
        end
    end

    function BuyMenu:buyItem(model)
        local stats = Config.ITEMS[model]
        self.state.player.money = self.state.player.money - stats.price
        local item = Item.new(model, stats.stackAmount or 1)
        if not self.state.inventory:addItem(item) then
            self.state.toast:show("Inventory full!", 2)
        end
    end

    function BuyMenu:confirmSelection()
        local model = self.sortedItems[self.selection]
        if not model then return end
        if isItemModel(model) then
            if self:canAffordWeapon(model) then
                self:buyItem(model)
            end
            return
        end
        if self:playerHasWeapon(model) then return end
        if not self.state.inventory:findFirstEmptySlot() then
            self.state.toast:show("Inventory full!", 2)
            return
        end
        if self:canAffordWeapon(model) then
            self:buyWeapon(model)
        end
    end

    function BuyMenu:mousepressed(worldX, worldY)
        if self.panelRect and not self:isPointInRect(worldX, worldY, self.panelRect) then
            self:close()
            return
        end
        for i, rect in ipairs(self.optionRects) do
            if self:isPointInRect(worldX, worldY, rect) then
                self.selection = i
                self:confirmSelection()
                return
            end
        end
    end
end
