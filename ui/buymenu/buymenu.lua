-- Weapon shop: core state and lifecycle. Purchase logic and draw behavior are
-- attached by the mixins required at the bottom of this file.

local BuyMenu = {}
BuyMenu.__index = BuyMenu

function BuyMenu.new(state)
    local self = setmetatable({}, BuyMenu)
    self.state = state
    self.isOpen = false
    self.selection = 1
    self.optionRects = {}
    self.sortedItems = {}
    self.lastMouseX = -1
    self.lastMouseY = -1
    self.useMouseSelection = true
    return self
end

function BuyMenu:open()
    self.state.ignoreMouseUntilRelease = true
    self.sortedItems = self:getWeaponsSortedByPrice()
    self.isOpen = true
    self.selection = 1
    self.optionRects = {}
    self.useMouseSelection = true
    self.lastMouseX = -1
    self.lastMouseY = -1
end

function BuyMenu:close()
    self.isOpen = false
    self.optionRects = {}
    self.sortedItems = {}
end

require("ui.buymenu.buy_logic")(BuyMenu)
require("ui.buymenu.buy_draw")(BuyMenu)
require("ui.menu_common")(BuyMenu)

return BuyMenu
