local ItemBrowser = {}

local PANEL_WIDTH = ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = ITEM_BROWSER_PANEL_HEIGHT
local ITEM_CELL_SIZE = ITEM_BROWSER_ITEM_CELL_SIZE
local ITEM_CELL_GAP = ITEM_BROWSER_ITEM_CELL_GAP
local ITEMS_PER_ROW = ITEM_BROWSER_ITEMS_PER_ROW
local HEADER_HEIGHT = ITEM_BROWSER_HEADER_HEIGHT

ItemBrowser.isOpen = false
ItemBrowser.searchQuery = ""
ItemBrowser.filteredItems = {}
ItemBrowser.draggedItem = nil
ItemBrowser.scrollY = 0
ItemBrowser.consumeNextText = false
ItemBrowser.searchFocused = false
ItemBrowser.dragStartX = 0
ItemBrowser.dragStartY = 0

local DRAG_THRESHOLD = ITEM_BROWSER_DRAG_THRESHOLD

local allItems = {}

local function buildItemList()
    allItems = {}
    for key, item in pairs(BLOCK_ITEMS) do
        table.insert(allItems, { key = key, name = item.name, material = item.material })
    end
    for key, item in pairs(OBJECT_ITEMS) do
        table.insert(allItems, { key = key, name = item.name, material = item.material })
    end
    table.sort(allItems, function(a, b) return a.name < b.name end)
end

local function getPanelPosition()
    local px = math.floor(scrWidth / 2 - PANEL_WIDTH / 2 + camera.x)
    local py = math.floor(scrHeight / 2 - PANEL_HEIGHT / 2 + camera.y)
    return px, py
end

local function clampScroll()
    local rowH = ITEM_CELL_SIZE + ITEM_CELL_GAP
    local numRows = math.ceil(#ItemBrowser.filteredItems / ITEMS_PER_ROW)
    if numRows == 0 then
        ItemBrowser.scrollY = 0
        return
    end
    local contentHeight = numRows * rowH
    local visibleHeight = PANEL_HEIGHT - HEADER_HEIGHT
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    if ItemBrowser.scrollY > maxScroll then
        ItemBrowser.scrollY = maxScroll
    end
end

local function filterItems()
    local query = ItemBrowser.searchQuery:lower()
    ItemBrowser.filteredItems = {}
    for _, item in ipairs(allItems) do
        if query == "" or item.name:lower():find(query, 1, true) then
            table.insert(ItemBrowser.filteredItems, item)
        end
    end
    clampScroll()
end

local function forEachItemCell(px, py, fn)
    local gridStartY = py + HEADER_HEIGHT - ItemBrowser.scrollY
    local col, row = 0, 0
    for _, item in ipairs(ItemBrowser.filteredItems) do
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

local function isPointInRect(x, y, rectX, rectY, w, h)
    return x >= rectX and x <= rectX + w and y >= rectY and y <= rectY + h
end

function ItemBrowser.open()
    ignoreMouseUntilRelease = true
    if #allItems == 0 then buildItemList() end
    ItemBrowser.isOpen = true
    ItemBrowser.searchQuery = ""
    ItemBrowser.scrollY = 0
    ItemBrowser.draggedItem = nil
    ItemBrowser.searchFocused = false
    ItemBrowser.dragStartX = 0
    ItemBrowser.dragStartY = 0
    filterItems()
end

function ItemBrowser.close()
    ItemBrowser.isOpen = false
    ItemBrowser.draggedItem = nil
    ItemBrowser.searchFocused = false
end

function ItemBrowser.clampScroll()
    clampScroll()
end

function ItemBrowser.toggle()
    if ItemBrowser.isOpen then ItemBrowser.close() else ItemBrowser.open() end
end

function ItemBrowser.handleTextInput(text)
    if not ItemBrowser.searchFocused then return end
    ItemBrowser.searchQuery = ItemBrowser.searchQuery .. text
    filterItems()
    ItemBrowser.scrollY = 0
end

function ItemBrowser.handleDelete()
    if not ItemBrowser.searchFocused then return end
    ItemBrowser.searchQuery = ItemBrowser.searchQuery:sub(1, -2)
    filterItems()
end

function ItemBrowser.handleOutsideClick(px, py, worldX, worldY)
    if isPointInRect(worldX, worldY, px, py, PANEL_WIDTH, PANEL_HEIGHT) then return false end
    ItemBrowser.close()
    return true
end

function ItemBrowser.handleSearchClick(px, py, worldX, worldY)
    if isPointInRect(worldX, worldY, px + 10, py + 36, PANEL_WIDTH - 20, 24) then
        ItemBrowser.searchFocused = true
        return true
    end
    return false
end

function ItemBrowser.handleGridClick(px, py, worldX, worldY)
    local found = false
    forEachItemCell(px, py, function(item, cellX, cellY)
        if not found and isPointInRect(worldX, worldY, cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE) then
            ItemBrowser.draggedItem = item
            ItemBrowser.dragStartX = worldX
            ItemBrowser.dragStartY = worldY
            found = true
        end
    end)
    return found
end

function ItemBrowser.mousepressed(worldX, worldY)
    if not ItemBrowser.isOpen then return end

    local px, py = getPanelPosition()

    if ItemBrowser.handleOutsideClick(px, py, worldX, worldY) then return end
    if ItemBrowser.handleSearchClick(px, py, worldX, worldY) then return end

    ItemBrowser.searchFocused = false
    ItemBrowser.handleGridClick(px, py, worldX, worldY)
end

function ItemBrowser.autoPlaceItem(item)
    for i = 1, MapBuilder.QUICK_ACCESS_COUNT do
        if not MapBuilder.quickAccess[i] then
            MapBuilder.setQuickAccess(i, item.key)
            return true
        end
    end
    return false
end

function ItemBrowser.dropOnSlot(worldX, worldY, item)
    for i, rect in ipairs(MapBuilderHUD.getSlotRects()) do
        if isPointInRect(worldX, worldY, rect.x, rect.y, rect.w, rect.h) then
            MapBuilder.setQuickAccess(i, item.key)
            return true
        end
    end
    return false
end

function ItemBrowser.mousereleased(worldX, worldY)
    if not ItemBrowser.draggedItem then return end

    local item = ItemBrowser.draggedItem
    ItemBrowser.draggedItem = nil

    if ItemBrowser.wasDragClick(worldX, worldY) then
        ItemBrowser.autoPlaceItem(item)
        return
    end

    ItemBrowser.dropOnSlot(worldX, worldY, item)
end

function ItemBrowser.wasDragClick(worldX, worldY)
    local dx = worldX - ItemBrowser.dragStartX
    local dy = worldY - ItemBrowser.dragStartY
    return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
end

function ItemBrowser.drawOverlay()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", camera.x, camera.y, scrWidth, scrHeight)
end

function ItemBrowser.drawPanel(px, py)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", px, py, PANEL_WIDTH, PANEL_HEIGHT)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", px, py, PANEL_WIDTH, PANEL_HEIGHT)
end

function ItemBrowser.drawTitle(px, py)
    local font = Fonts.get(22)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Building Items", px + 10, py + 8)
end

local function drawSearchBox(px, py)
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", px + 10, py + 36, PANEL_WIDTH - 20, 24)

    if ItemBrowser.searchFocused then
        love.graphics.setColor(0.5, 0.7, 1.0)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    love.graphics.rectangle("line", px + 10, py + 36, PANEL_WIDTH - 20, 24)
end

local function getSearchDisplayText()
    if ItemBrowser.searchFocused then
        local cursor = love.timer.getTime() % 1 > 0.5 and "|" or " "
        return ItemBrowser.searchQuery .. cursor
    end
    if ItemBrowser.searchQuery ~= "" then
        return ItemBrowser.searchQuery
    end
    return "Press SPACE or click to search"
end

local function drawSearchText(px, py)
    love.graphics.setFont(Fonts.get(16))
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(getSearchDisplayText(), px + 14, py + 38)
end

function ItemBrowser.drawSearchBar(px, py)
    drawSearchBox(px, py)
    drawSearchText(px, py)
end

function ItemBrowser.drawItemGrid(px, py)
    forEachItemCell(px, py, function(item, cellX, cellY)
        ItemBrowser.drawItemCell(cellX, cellY, item)
    end)
end

function ItemBrowser.drawItemCell(cellX, cellY, item)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE)
    love.graphics.setColor(0.35, 0.35, 0.35)
    love.graphics.rectangle("line", cellX, cellY, ITEM_CELL_SIZE, ITEM_CELL_SIZE)

    Textures.draw(item.material, cellX + 5, cellY + 5, ITEM_CELL_SIZE - 10, ITEM_CELL_SIZE - 10)

    love.graphics.setFont(Fonts.get(18))
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(item.name, cellX + 2, cellY + ITEM_CELL_SIZE + 4)
end

function ItemBrowser.drawDragGhost()
    if not ItemBrowser.draggedItem then return end
    local mx, my = love.mouse.getPosition()
    Textures.draw(ItemBrowser.draggedItem.material, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
end

function ItemBrowser.draw()
    if not ItemBrowser.isOpen then return end

    local px, py = getPanelPosition()

    ItemBrowser.drawOverlay()
    ItemBrowser.drawPanel(px, py)
    ItemBrowser.drawTitle(px, py)
    ItemBrowser.drawSearchBar(px, py)
    ItemBrowser.drawItemGrid(px, py)
    ItemBrowser.drawDragGhost()
end

return ItemBrowser
