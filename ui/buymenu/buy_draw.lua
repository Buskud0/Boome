-- Weapon shop: rendering. Attaches methods to the BuyMenu factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"

local PANEL_WIDTH = Config.BUYMENU_PANEL_WIDTH
local PANEL_MAX_HEIGHT = Config.BUYMENU_PANEL_MAX_HEIGHT
local OPTION_HEIGHT = Config.BUYMENU_OPTION_HEIGHT
local OPTION_GAP = Config.BUYMENU_OPTION_GAP
local TITLE_OFFSET_Y = Config.BUYMENU_TITLE_OFFSET_Y
local MONEY_OFFSET_Y = Config.BUYMENU_MONEY_OFFSET_Y
local OPTIONS_OFFSET_Y = Config.BUYMENU_OPTIONS_OFFSET_Y
local BOTTOM_PADDING = 16

return function(BuyMenu)
    function BuyMenu:draw()
        if not self.isOpen then return end

        self.optionRects = {}
        local optionCount = #self.sortedItems
        local fullHeight = OPTIONS_OFFSET_Y + optionCount * OPTION_GAP + BOTTOM_PADDING
        local panelHeight = math.min(fullHeight, PANEL_MAX_HEIGHT)
        local px = math.floor(self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x)
        local py = math.floor(self.state.scrHeight / 2 - panelHeight / 2 + self.state.camera.y)
        self.panelRect = { x = px, y = py, w = PANEL_WIDTH, h = panelHeight }
        self.maxScroll = self:computeMaxScroll(optionCount, panelHeight)

        local mouseX, mouseY, mouseMoved = self:getMouseSelectionState()
        self:drawPanel(px, py, panelHeight)
        self:drawTitle(px, py)
        self:drawMoney(px, py)
        love.graphics.setScissor(px - self.state.camera.x, py - self.state.camera.y, PANEL_WIDTH, panelHeight)
        self:drawWeaponOptions(px, py, panelHeight, optionCount, mouseX, mouseY, mouseMoved)
        love.graphics.setScissor()
        if self.maxScroll > 0 then
            self:drawScrollbar()
        end
    end

    function BuyMenu:computeMaxScroll(optionCount, panelHeight)
        local visibleH = panelHeight - OPTIONS_OFFSET_Y - BOTTOM_PADDING
        local contentH = optionCount * OPTION_GAP
        return math.max(0, contentH - visibleH)
    end

    function BuyMenu:drawPanel(px, py, panelHeight)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
        love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
    end

    function BuyMenu:drawTitle(px, py)
        local font = Fonts.get(36)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        local title = "WEAPON SHOP"
        local titleW = font:getWidth(title)
        love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
    end

    function BuyMenu:drawMoney(px, py)
        local font = Fonts.get(20)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 0.8, 0.2)
        local text = "$" .. self.state.player.money
        local textW = font:getWidth(text)
        love.graphics.print(text, px + PANEL_WIDTH / 2 - textW / 2, py + MONEY_OFFSET_Y)
    end

    function BuyMenu:drawSelectionHighlight(rect, index)
        if index == self.selection then
            love.graphics.setColor(0.3, 0.5, 0.7)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        end
    end

    function BuyMenu:drawWeaponIcon(rect, model)
        local alpha = self:isOwned(model) and 0.4 or 1
        Textures.draw("slot_" .. model, rect.x + 4, rect.y + 4, 28, 28, alpha)
    end

    function BuyMenu:drawWeaponName(rect, model)
        local font = Fonts.get(22)
        love.graphics.setFont(font)
        love.graphics.print(model, rect.x + 40, rect.y + 6)
    end

    function BuyMenu:drawWeaponPrice(rect, model)
        if self:canAffordWeapon(model) then
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(0.8, 0.3, 0.3)
        end
        love.graphics.print("$" .. self:priceOf(model), rect.x + rect.w - 74, rect.y + 8)
    end

    function BuyMenu:drawWeaponStatus(rect, model)
        local font = Fonts.get(18)
        love.graphics.setFont(font)
        if self:isOwned(model) then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.print("OWNED", rect.x + rect.w - 80, rect.y + 8)
        else
            self:drawWeaponPrice(rect, model)
        end
    end

    function BuyMenu:drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
        local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }
        self.optionRects[i] = rect

        if mouseMoved and self.useMouseSelection then
            self:updateHover(rect, mouseX, mouseY, i)
        end

        self:drawSelectionHighlight(rect, i)
        self:drawWeaponIcon(rect, model)
        self:drawWeaponName(rect, model)
        self:drawWeaponStatus(rect, model)
    end

    function BuyMenu:drawWeaponOptions(px, py, panelHeight, optionCount, mouseX, mouseY, mouseMoved)
        if optionCount == 0 then return end
        if self.scrollY > self.maxScroll then self.scrollY = self.maxScroll end
        if self.scrollY < 0 then self.scrollY = 0 end

        local contentTop = py + OPTIONS_OFFSET_Y
        local panelBottom = py + panelHeight
        for i = 1, optionCount do
            local optionY = contentTop + (i - 1) * OPTION_GAP - self.scrollY
            if optionY + OPTION_HEIGHT > py and optionY < panelBottom then
                self:drawWeaponOption(px, optionY, i, self.sortedItems[i], mouseX, mouseY, mouseMoved)
            end
        end
    end

    function BuyMenu:scrollbarGeometry()
        local rect = self.panelRect
        if not rect then return nil end
        local trackTop = rect.y + OPTIONS_OFFSET_Y
        local trackH = rect.h - OPTIONS_OFFSET_Y - BOTTOM_PADDING
        local totalRows = #self.sortedItems
        local visibleRows = trackH / OPTION_GAP
        local thumbH = math.max(24, trackH * math.min(1, visibleRows / math.max(1, totalRows)))
        local thumbRange = trackH - thumbH
        local thumbTop = trackTop + thumbRange * (self.maxScroll > 0 and self.scrollY / self.maxScroll or 0)
        return rect.x + PANEL_WIDTH - 8, trackTop, trackH, thumbH, thumbTop, thumbRange
    end

    function BuyMenu:drawScrollbar()
        local sbx, trackTop, trackH, thumbH, thumbTop = self:scrollbarGeometry()

        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", sbx, trackTop, 4, trackH)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", sbx, thumbTop, 4, thumbH)
        love.graphics.setColor(1, 1, 1)
    end
end
