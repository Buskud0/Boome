-- Weapon shop: purchase and input logic. Attaches methods to the BuyMenu factory.

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

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
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

    function BuyMenu:canAffordWeapon(model)
        return self.state.player.money >= priceOf(model)
    end

    function BuyMenu:wrapSelection(index)
        if index < 1 then return #self.sortedWeapons end
        if index > #self.sortedWeapons then return 1 end
        return index
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

    function BuyMenu:getMouseSelectionState()
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

    function BuyMenu:updateHover(rect, mouseX, mouseY, index)
        if self:isPointInRect(mouseX, mouseY, rect) then
            self.selection = index
        end
    end

    function BuyMenu:isPointInRect(x, y, rect)
        return isPointInRect(x, y, rect)
    end

    function BuyMenu:handleAction(action)
        if action == "menu_up" then
            self.useMouseSelection = false
            self.selection = self:wrapSelection(self.selection - 1)
        elseif action == "menu_down" then
            self.useMouseSelection = false
            self.selection = self:wrapSelection(self.selection + 1)
        elseif action == "menu_confirm" then
            self:confirmPurchase()
        end
    end

    function BuyMenu:wheelmoved(direction)
        if direction > 0 then
            self.selection = self:wrapSelection(self.selection - 1)
        elseif direction < 0 then
            self.selection = self:wrapSelection(self.selection + 1)
        end
    end

    function BuyMenu:confirmPurchase()
        local model = self.sortedWeapons[self.selection]
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
        for i, rect in ipairs(self.optionRects) do
            if self:isPointInRect(worldX, worldY, rect) then
                self.selection = i
                self:confirmPurchase()
                return
            end
        end
        self:close()
    end
end
