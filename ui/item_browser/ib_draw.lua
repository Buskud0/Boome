-- Item browser: rendering. Attaches methods to the ItemBrowser factory.

local Fonts = require "core.fonts"
local Textures = require "core.textures"

local PANEL_WIDTH = require("core.config").ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = require("core.config").ITEM_BROWSER_PANEL_HEIGHT
local ITEM_CELL_SIZE = require("core.config").ITEM_BROWSER_ITEM_CELL_SIZE
local ITEMS_PER_ROW = require("core.config").ITEM_BROWSER_ITEMS_PER_ROW
local ITEM_CELL_GAP = require("core.config").ITEM_BROWSER_ITEM_CELL_GAP
local HEADER_HEIGHT = require("core.config").ITEM_BROWSER_HEADER_HEIGHT
local SCROLLBAR_WIDTH = require("core.config").ITEM_BROWSER_SCROLLBAR_WIDTH

local FILTERS = { { id = "all", label = "All" }, { id = "block", label = "Blocks" }, { id = "object", label = "Objects" } }
local FILTER_Y = 66
local FILTER_H = 26
local FILTER_GAP = 8
local GRID_LEFT = 10
local GRID_RIGHT_PAD = 14
local GRID_TOP = HEADER_HEIGHT + 18

return function(ItemBrowser)
    function ItemBrowser:gridWidth()
        return PANEL_WIDTH - GRID_LEFT - SCROLLBAR_WIDTH - GRID_RIGHT_PAD
    end

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

    function ItemBrowser:filterRects(px, py)
        local rects = {}
        local total = -FILTER_GAP
        for i = 1, #FILTERS do
            total = total + FILTER_GAP + Fonts.get(16):getWidth(FILTERS[i].label) + 24
        end
        local x = px + math.max(GRID_LEFT, math.floor((PANEL_WIDTH - total) / 2))
        for i, f in ipairs(FILTERS) do
            local w = Fonts.get(16):getWidth(f.label) + 24
            rects[i] = { id = f.id, label = f.label, x = x, y = py + FILTER_Y, w = w, h = FILTER_H }
            x = x + w + FILTER_GAP
        end
        return rects
    end

    function ItemBrowser:drawFilterBar(px, py)
        for _, r in ipairs(self:filterRects(px, py)) do
            if r.id == self.filter then
                love.graphics.setColor(0.32, 0.55, 0.8, 0.95)
            else
                love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
            end
            love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
            self:drawCenteredText(r.label, r.x + r.w / 2, r.y + 1, 16,
                r.id == self.filter and {1, 1, 1} or {0.8, 0.8, 0.8})
        end
    end

    function ItemBrowser:drawItemGrid(px, py)
        local camera = self.state.camera
        local clipX = px - camera.x + GRID_LEFT
        local clipY = py - camera.y + GRID_TOP
        local clipW = self:gridWidth()
        local clipH = PANEL_HEIGHT - GRID_TOP
        local prev = { love.graphics.getScissor() }
        love.graphics.setScissor(math.floor(clipX), math.floor(clipY), math.floor(clipW), math.floor(clipH))
        self:forEachItemCell(px, py, function(item, cellX, cellY)
            self:drawItemCell(cellX, cellY, item)
        end)
        love.graphics.setScissor(prev[1], prev[2], prev[3], prev[4])
    end

    function ItemBrowser:drawItemCell(cellX, cellY, item)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE)
        love.graphics.setColor(0.35, 0.35, 0.35)
        love.graphics.rectangle("line", cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE)

        Textures.draw(item.material, cellX + 5, cellY + 5, ITEM_CELL_SIZE - 10, ITEM_CELL_SIZE - 10)

        local font = Fonts.get(18)
        love.graphics.setFont(font)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(item.name, cellX + 2, cellY + ITEM_CELL_SIZE + 4)
    end

    function ItemBrowser:drawScrollBar(px, py)
        local gridH = PANEL_HEIGHT - GRID_TOP
        local rowH = ITEM_CELL_SIZE + ITEM_CELL_GAP
        local numRows = math.max(1, math.ceil(#self.filteredItems / ITEMS_PER_ROW))
        local contentHeight = numRows * rowH
        if contentHeight <= gridH then return end

        local trackX = px + GRID_LEFT + self:gridWidth()
        local trackY = py + GRID_TOP
        local thumbH = math.max(20, gridH * (gridH / contentHeight))
        if thumbH > gridH then thumbH = gridH end
        local range = math.max(1, contentHeight - gridH)
        local thumbY = trackY + (gridH - thumbH) * (self.scrollY / range)

        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", trackX, trackY, SCROLLBAR_WIDTH, gridH)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", trackX, thumbY, SCROLLBAR_WIDTH, thumbH)
    end

    function ItemBrowser:drawDragGhost()
        if not self.draggedItem then return end
        local mx, my = love.mouse.getPosition()
        local camera = self.state.camera
        Textures.draw(self.draggedItem.material, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
    end

    function ItemBrowser:drawCenteredText(text, centerX, y, size, color)
        local font = Fonts.get(size)
        love.graphics.setFont(font)
        local textW = font:getWidth(text)
        love.graphics.setColor(color)
        love.graphics.print(text, centerX - textW / 2, y)
    end

    function ItemBrowser:draw()
        if not self.isOpen then return end

        local px, py = self:getPanelPosition()

        self:drawOverlay()
        self:drawPanel(px, py)
        self:drawTitle(px, py)
        self:drawSearchBar(px, py)
        self:drawFilterBar(px, py)
        self:drawItemGrid(px, py)
        self:drawScrollBar(px, py)
        self:drawDragGhost()
    end
end
