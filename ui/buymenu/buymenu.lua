-- Weapon shop: core state and lifecycle. Purchase logic and draw behavior are
-- attached by the mixins required at the bottom of this file.

local Config = require "core.config"

local BuyMenu = {}
BuyMenu.__index = BuyMenu

function BuyMenu.new(state)
    local self = setmetatable({}, BuyMenu)
    self.state = state
    self.isOpen = false
    self.selection = 1
    self.optionRects = {}
    self.sortedItems = {}
    self.scrollY = 0
    self.maxScroll = 0
    self.dragScroll = false
    self.dragOffset = 0
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
    self.scrollY = 0
    self.maxScroll = 0
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

local OPTION_GAP = Config.BUYMENU_OPTION_GAP

function BuyMenu:ensureSelectedVisible()
    local panelHeight = self.panelRect and self.panelRect.h or 0
    local visibleH = panelHeight - Config.BUYMENU_OPTIONS_OFFSET_Y - 16
    local base = (self.selection - 1) * OPTION_GAP
    local minS = math.max(0, base - (visibleH - Config.BUYMENU_OPTION_HEIGHT))
    local maxS = math.min(self.maxScroll, base)
    if self.scrollY < minS then
        self.scrollY = minS
    elseif self.scrollY > maxS then
        self.scrollY = maxS
    end
end

function BuyMenu:wheelmoved(direction)
    local step = Config.BUYMENU_OPTION_GAP
    self.scrollY = self.scrollY - direction * step
    if self.scrollY < 0 then self.scrollY = 0 end
    if self.scrollY > self.maxScroll then self.scrollY = self.maxScroll end
end

function BuyMenu:scrollToWorldY(worldY)
    local sbx, trackTop, trackH, thumbH, thumbTop, thumbRange = self:scrollbarGeometry()
    if not thumbRange or thumbRange <= 0 then return end
    local t = (worldY - self.dragOffset - trackTop) / thumbRange
    t = math.max(0, math.min(1, t))
    self.scrollY = math.max(0, math.min(self.maxScroll, t * self.maxScroll))
end

function BuyMenu:mousemoved(worldX, worldY)
    if self.dragScroll then
        self:scrollToWorldY(worldY)
    end
end

function BuyMenu:mousereleased()
    self.dragScroll = false
end

function BuyMenu:handleAction(action)
    if action == "menu_up" then
        self.useMouseSelection = false
        self.selection = self:wrapSelection(self.selection - 1)
        self:ensureSelectedVisible()
    elseif action == "menu_down" then
        self.useMouseSelection = false
        self.selection = self:wrapSelection(self.selection + 1)
        self:ensureSelectedVisible()
    elseif action == "menu_confirm" then
        self:confirmSelection()
    end
end

return BuyMenu
