-- Item browser: rendering. Attaches methods to the ItemBrowser factory.

local Fonts = require "core.fonts"
local Textures = require "core.textures"

local PANEL_WIDTH = require("core.config").ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = require("core.config").ITEM_BROWSER_PANEL_HEIGHT
local ITEM_CELL_SIZE = require("core.config").ITEM_BROWSER_ITEM_CELL_SIZE

return function(ItemBrowser)
    function ItemBrowser:drawOverlay()
        local camera = self.state.camera
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", camera.x, camera.y, self.state.scrWidth, self.state.scrHeight)
    end

    function ItemBrowser:drawPanel(px, py)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
        love.graphics.rectangle("fill", px, py, PANEL_WIDTH, PANEL_HEIGHT)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", px, py, PANEL_WIDTH, PANEL_HEIGHT)
    end

    function ItemBrowser:drawTitle(px, py)
        local font = Fonts.get(22)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Building Items", px + 10, py + 8)
    end

    function ItemBrowser:drawSearchBox(px, py)
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", px + 10, py + 36, PANEL_WIDTH - 20, 24)

        if self.searchFocused then
            love.graphics.setColor(0.5, 0.7, 1.0)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        love.graphics.rectangle("line", px + 10, py + 36, PANEL_WIDTH - 20, 24)
    end

    function ItemBrowser:getSearchDisplayText()
        if self.searchFocused then
            local cursor = love.timer.getTime() % 1 > 0.5 and "|" or " "
            return self.searchQuery .. cursor
        end
        if self.searchQuery ~= "" then
            return self.searchQuery
        end
        return "Press SPACE or click to search"
    end

    function ItemBrowser:drawSearchText(px, py)
        love.graphics.setFont(Fonts.get(16))
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(self:getSearchDisplayText(), px + 14, py + 38)
    end

    function ItemBrowser:drawSearchBar(px, py)
        self:drawSearchBox(px, py)
        self:drawSearchText(px, py)
    end

    function ItemBrowser:drawItemGrid(px, py)
        self:forEachItemCell(px, py, function(item, cellX, cellY)
            self:drawItemCell(cellX, cellY, item)
        end)
    end

    function ItemBrowser:drawItemCell(cellX, cellY, item)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE)
        love.graphics.setColor(0.35, 0.35, 0.35)
        love.graphics.rectangle("line", cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE)

        Textures.draw(item.material, cellX + 5, cellY + 5, ITEM_CELL_SIZE - 10, ITEM_CELL_SIZE - 10)

        love.graphics.setFont(Fonts.get(18))
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(item.name, cellX + 2, cellY + ITEM_CELL_SIZE + 4)
    end

    function ItemBrowser:drawDragGhost()
        if not self.draggedItem then return end
        local mx, my = love.mouse.getPosition()
        local camera = self.state.camera
        Textures.draw(self.draggedItem.material, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
    end

    function ItemBrowser:draw()
        if not self.isOpen then return end

        local px, py = self:getPanelPosition()

        self:drawOverlay()
        self:drawPanel(px, py)
        self:drawTitle(px, py)
        self:drawSearchBar(px, py)
        self:drawItemGrid(px, py)
        self:drawDragGhost()
    end
end
