-- Weapon shop: rendering. Attaches methods to the BuyMenu factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"

local PANEL_WIDTH = Config.BUYMENU_PANEL_WIDTH
local OPTION_HEIGHT = Config.BUYMENU_OPTION_HEIGHT
local OPTION_GAP = Config.BUYMENU_OPTION_GAP
local TITLE_OFFSET_Y = Config.BUYMENU_TITLE_OFFSET_Y
local MONEY_OFFSET_Y = Config.BUYMENU_MONEY_OFFSET_Y
local OPTIONS_OFFSET_Y = Config.BUYMENU_OPTIONS_OFFSET_Y

return function(BuyMenu)
    function BuyMenu:draw()
        if not self.isOpen then return end

        self.optionRects = {}
        local optionCount = #self.sortedWeapons
        local panelHeight = OPTIONS_OFFSET_Y + optionCount * OPTION_GAP + 16
        local px = math.floor(self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x)
        local py = math.floor(self.state.scrHeight / 2 - panelHeight / 2 + self.state.camera.y)

        local mouseX, mouseY, mouseMoved = self:getMouseSelectionState()
        self:drawPanel(px, py, panelHeight)
        self:drawTitle(px, py)
        self:drawMoney(px, py)
        self:drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
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
        local alpha = self:playerHasWeapon(model) and 0.4 or 1
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
        love.graphics.print("$" .. Config.WEAPONS[model].price, rect.x + rect.w - 74, rect.y + 8)
    end

    function BuyMenu:drawWeaponStatus(rect, model)
        local font = Fonts.get(18)
        love.graphics.setFont(font)
        if self:playerHasWeapon(model) then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.print("OWNED", rect.x + rect.w - 80, rect.y + 8)
        else
            self:drawWeaponPrice(rect, model)
        end
    end

    function BuyMenu:drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
        local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }
        table.insert(self.optionRects, rect)

        if mouseMoved and self.useMouseSelection then
            self:updateHover(rect, mouseX, mouseY, i)
        end

        self:drawSelectionHighlight(rect, i)
        self:drawWeaponIcon(rect, model)
        self:drawWeaponName(rect, model)
        self:drawWeaponStatus(rect, model)
    end

    function BuyMenu:drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
        local optionY = py + OPTIONS_OFFSET_Y
        for i, model in ipairs(self.sortedWeapons) do
            self:drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
            optionY = optionY + OPTION_GAP
        end
    end
end
