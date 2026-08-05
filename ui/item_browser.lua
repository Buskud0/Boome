-- Building-item browser: searchable grid + drag items onto the quick-access bar.
-- State-injected factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"

local ItemBrowser = {}
ItemBrowser.__index = ItemBrowser

local PANEL_WIDTH = Config.ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = Config.ITEM_BROWSER_PANEL_HEIGHT
local ITEM_CELL_SIZE = Config.ITEM_BROWSER_ITEM_CELL_SIZE
local ITEM_CELL_GAP = Config.ITEM_BROWSER_ITEM_CELL_GAP
local ITEMS_PER_ROW = Config.ITEM_BROWSER_ITEMS_PER_ROW
local HEADER_HEIGHT = Config.ITEM_BROWSER_HEADER_HEIGHT
local DRAG_THRESHOLD = Config.ITEM_BROWSER_DRAG_THRESHOLD

local function buildItemList()
    local all = {}
    for key, item in pairs(Config.BLOCK_ITEMS) do
        table.insert(all, { key = key, name = item.name, material = item.material })
    end
    for key, item in pairs(Config.OBJECT_ITEMS) do
        table.insert(all, { key = key, name = item.name, material = item.material })
    end
    table.sort(all, function(a, b) return a.name < b.name end)
    return all
end

function ItemBrowser.new(state)
    local self = setmetatable({}, ItemBrowser)
    self.state = state
    self.allItems = buildItemList()
    self.isOpen = false
    self.searchQuery = ""
    self.filteredItems = {}
    self.draggedItem = nil
    self.scrollY = 0
    self.consumeNextText = false
    self.searchFocused = false
    self.dragStartX = 0
    self.dragStartY = 0
    return self
end

local function isPointInRect(x, y, rectX, rectY, w, h)
    return x >= rectX and x <= rectX + w and y >= rectY and y <= rectY + h
end

function ItemBrowser:getPanelPosition()
    local px = math.floor(self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x)
    local py = math.floor(self.state.scrHeight / 2 - PANEL_HEIGHT / 2 + self.state.camera.y)
    return px, py
end

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

function ItemBrowser:open()
    self.state.ignoreMouseUntilRelease = true
    if #self.allItems == 0 then self.allItems = buildItemList() end
    self.isOpen = true
    self.searchQuery = ""
    self.scrollY = 0
    self.draggedItem = nil
    self.searchFocused = false
    self.dragStartX = 0
    self.dragStartY = 0
    self:filterItems()
end

function ItemBrowser:close()
    self.isOpen = false
    self.draggedItem = nil
    self.searchFocused = false
end

function ItemBrowser:toggle()
    if self.isOpen then self:close() else self:open() end
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

function ItemBrowser:handleOutsideClick(px, py, worldX, worldY)
    if isPointInRect(worldX, worldY, px, py, PANEL_WIDTH, PANEL_HEIGHT) then return false end
    self:close()
    return true
end

function ItemBrowser:handleSearchClick(px, py, worldX, worldY)
    if isPointInRect(worldX, worldY, px + 10, py + 36, PANEL_WIDTH - 20, 24) then
        self.searchFocused = true
        return true
    end
    return false
end

function ItemBrowser:handleGridClick(px, py, worldX, worldY)
    local found = false
    self:forEachItemCell(px, py, function(item, cellX, cellY)
        if not found and isPointInRect(worldX, worldY, cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE) then
            self.draggedItem = item
            self.dragStartX = worldX
            self.dragStartY = worldY
            found = true
        end
    end)
    return found
end

function ItemBrowser:mousepressed(worldX, worldY)
    if not self.isOpen then return end

    local px, py = self:getPanelPosition()

    if self:handleOutsideClick(px, py, worldX, worldY) then return end
    if self:handleSearchClick(px, py, worldX, worldY) then return end

    self.searchFocused = false
    self:handleGridClick(px, py, worldX, worldY)
end

function ItemBrowser:autoPlaceItem(item)
    local mapBuilder = self.state.mapBuilder
    for i = 1, mapBuilder.QUICK_ACCESS_COUNT do
        if not mapBuilder.quickAccess[i] then
            mapBuilder:setQuickAccess(i, item.key)
            return true
        end
    end
    return false
end

function ItemBrowser:dropOnSlot(worldX, worldY, item)
    for i, rect in ipairs(self.state.mapBuilderHUD:getSlotRects()) do
        if isPointInRect(worldX, worldY, rect.x, rect.y, rect.w, rect.h) then
            self.state.mapBuilder:setQuickAccess(i, item.key)
            return true
        end
    end
    return false
end

function ItemBrowser:mousereleased(worldX, worldY)
    if not self.draggedItem then return end

    local item = self.draggedItem
    self.draggedItem = nil

    if self:wasDragClick(worldX, worldY) then
        self:autoPlaceItem(item)
        return
    end

    self:dropOnSlot(worldX, worldY, item)
end

function ItemBrowser:wasDragClick(worldX, worldY)
    local dx = worldX - self.dragStartX
    local dy = worldY - self.dragStartY
    return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
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

return ItemBrowser