-- Item browser: search, scroll and grid cells. Attaches methods to the
-- ItemBrowser factory.

local Config = require "core.config"

local PANEL_WIDTH = Config.ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = Config.ITEM_BROWSER_PANEL_HEIGHT
local ITEM_CELL_SIZE = Config.ITEM_BROWSER_ITEM_CELL_SIZE
local ITEM_CELL_GAP = Config.ITEM_BROWSER_ITEM_CELL_GAP
local ITEMS_PER_ROW = Config.ITEM_BROWSER_ITEMS_PER_ROW
local HEADER_HEIGHT = Config.ITEM_BROWSER_HEADER_HEIGHT

local function isPointInRect(x, y, rectX, rectY, w, h)
    return x >= rectX and x <= rectX + w and y >= rectY and y <= rectY + h
end

return function(ItemBrowser)
    function ItemBrowser:clampScroll()
        local rowH = ITEM_CELL_SIZE + ITEM_CELL_GAP
        local numRows = math.ceil(#self.filteredItems / ITEMS_PER_ROW)
        if numRows == 0 then
            self.scrollY = 0
            return
        end
        local contentHeight = numRows * rowH
        local visibleHeight = PANEL_HEIGHT - HEADER_HEIGHT
        local maxScroll = math.max(0, contentHeight - visibleHeight)
        if self.scrollY > maxScroll then
            self.scrollY = maxScroll
        end
    end

    function ItemBrowser:filterItems()
        local query = self.searchQuery:lower()
        self.filteredItems = {}
        for _, item in ipairs(self.allItems) do
            if query == "" or item.name:lower():find(query, 1, true) then
                table.insert(self.filteredItems, item)
            end
        end
        self:clampScroll()
    end

    function ItemBrowser:forEachItemCell(px, py, fn)
        local gridStartY = py + HEADER_HEIGHT - self.scrollY
        local col, row = 0, 0
        for _, item in ipairs(self.filteredItems) do
            local cellX = px + 10 + col * (ITEM_CELL_SIZE + ITEM_CELL_GAP)
            local cellY = gridStartY + row * (ITEM_CELL_SIZE + ITEM_CELL_GAP)
            fn(item, cellX, cellY)
            col = col + 1
            if col >= ITEMS_PER_ROW then
                col = 0
                row = row + 1
            end
        end
    end

    function ItemBrowser:handleTextInput(text)
        if not self.searchFocused then return end
        self.searchQuery = self.searchQuery .. text
        self:filterItems()
        self.scrollY = 0
    end

    function ItemBrowser:handleDelete()
        if not self.searchFocused then return end
        self.searchQuery = self.searchQuery:sub(1, -2)
        self:filterItems()
    end
end
