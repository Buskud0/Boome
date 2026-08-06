-- Horde shop interaction: proximity "OPEN SHOP" outline above the shop.
-- Attaches methods to the Horde factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Coordinates = require "core.coordinates"

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

return function(Horde)
    function Horde:computeShopButtonRect(record)
        local x, y, w, h = self.state.grid:recordWorldRect(record)
        return { x = x, y = y, w = w, h = h }
    end

    function Horde:updateShopButton()
        self.shopRecord = nil
        self.shopButtonRect = nil
        local state = self.state
        if state.buyMenu.isOpen or (state.menu and state.menu:isOpen()) then return end
        if not state.player or not state.grid then return end
        local cx, cy = state.player:getCenter()
        local record, kind = state.grid:nearestInteractable(cx, cy, Config.INTERACT_RANGE)
        if not record or kind ~= "shop" then return end
        self.shopRecord = record
        self.shopButtonRect = self:computeShopButtonRect(record)
    end

    function Horde:isPointInShopButton(x, y)
        local rect = self.shopButtonRect
        if not rect then return false end
        return isPointInRect(x, y, rect)
    end

    function Horde:tryOpenShop(sx, sy)
        if not self.shopButtonRect then return false end
        local wx, wy = Coordinates.screenToWorld(self.state, sx, sy)
        if not self:isPointInShopButton(wx, wy) then return false end
        if not self.state.buyMenu.isOpen then
            self.state.buyMenu:open()
        end
        return true
    end

    function Horde:drawShopButton()
        local rect = self.shopButtonRect
        if not rect then return end

        local hovered = false
        local mx, my = love.mouse.getPosition()
        local wx, wy = Coordinates.screenToWorld(self.state, mx, my)
        if self:isPointInShopButton(wx, wy) then hovered = true end

        local x, y, w, h = rect.x, rect.y, rect.w, rect.h
        if hovered then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", x + 2, y + 2, w - 4, h - 4)
        love.graphics.setLineWidth(1)

        local font = Fonts.get(16)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        local lines = { "OPEN", "SHOP" }
        local lineHeight = font:getHeight() * 0.8
        local startY = y + h / 2 - lineHeight * #lines / 2
        for i, lineText in ipairs(lines) do
            local lineW = font:getWidth(lineText)
            love.graphics.print(lineText, x + w / 2 - lineW / 2, startY + (i - 1) * lineHeight)
        end
    end
end
